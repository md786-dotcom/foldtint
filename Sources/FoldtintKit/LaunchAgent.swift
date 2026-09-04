import Darwin
import Foundation

enum LaunchAgentPlist {
    static let label = "com.foldtint.daemon"

    static func xml(executable: String) -> String {
        let path = escape(executable)
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(path)</string>
                <string>daemon</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ProcessType</key>
            <string>Background</string>
            <key>LowPriorityIO</key>
            <true/>
        </dict>
        </plist>
        """
    }

    static func escape(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        return result
    }

    static func plistURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }
}

struct LaunchAgentController: AgentControl {
    var plistURL: URL
    var usesLaunchctl: Bool

    init(
        plistURL: URL = LaunchAgentPlist.plistURL(),
        usesLaunchctl: Bool = true
    ) {
        self.plistURL = plistURL
        self.usesLaunchctl = usesLaunchctl
    }

    func install(executable: String) throws {
        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let xml = LaunchAgentPlist.xml(executable: executable)
        try xml.write(to: plistURL, atomically: true, encoding: .utf8)
        if usesLaunchctl {
            try bootstrap()
        }
    }

    func remove() throws {
        if usesLaunchctl {
            let domain = "gui/\(getuid())"
            _ = try? ProcessRunner.run("/bin/launchctl", ["bootout", "\(domain)/\(LaunchAgentPlist.label)"])
        }
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    func isLoaded() -> Bool {
        if !usesLaunchctl {
            return false
        }
        let domain = "gui/\(getuid())"
        let status = try? ProcessRunner.run(
            "/bin/launchctl",
            ["print", "\(domain)/\(LaunchAgentPlist.label)"]
        )
        return status == 0
    }

    private func bootstrap() throws {
        let domain = "gui/\(getuid())"
        _ = try? ProcessRunner.run("/bin/launchctl", ["bootout", "\(domain)/\(LaunchAgentPlist.label)"])
        let status = try ProcessRunner.run("/bin/launchctl", ["bootstrap", domain, plistURL.path])
        if status != 0 {
            throw FoldtintError.agentFailed
        }
    }
}

enum ProcessRunner {
    @discardableResult
    static func run(_ executable: String, _ arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
