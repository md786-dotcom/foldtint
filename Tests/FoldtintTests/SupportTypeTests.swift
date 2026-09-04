import Foundation
import Testing
@testable import FoldtintKit

struct LaunchAgentPlistTests {
    @Test func xmlContainsLabelAndDaemon() {
        let xml = LaunchAgentPlist.xml(executable: "/opt/foldtint")
        #expect(xml.contains("<string>com.foldtint.daemon</string>"))
        #expect(xml.contains("<string>/opt/foldtint</string>"))
        #expect(xml.contains("<string>daemon</string>"))
        #expect(xml.contains("<key>KeepAlive</key>"))
        #expect(xml.contains("<key>LowPriorityIO</key>"))
    }

    @Test func escapeReplacesMarkup() {
        let xml = LaunchAgentPlist.xml(executable: "/opt/a&b<c>")
        #expect(xml.contains("/opt/a&amp;b&lt;c&gt;"))
        #expect(!xml.contains("/opt/a&b<c>"))
    }

    @Test func plistURLIsInLaunchAgents() {
        let url = LaunchAgentPlist.plistURL()
        #expect(url.lastPathComponent == "com.foldtint.daemon.plist")
        #expect(url.path.contains("LaunchAgents"))
    }
}

struct PathsTests {
    @Test func executableAbsolutePath() {
        #expect(ExecutablePath.resolve(arguments: ["/usr/local/bin/foldtint"]) == "/usr/local/bin/foldtint")
    }

    @Test func executableEmptyUsesDefault() {
        #expect(ExecutablePath.resolve(arguments: []) == "/usr/local/bin/foldtint")
    }

    @Test func desktopRootRejectsBlockedHome() {
        #expect(throws: FoldtintError.refusedRoot) {
            try DesktopRoot.resolve(home: URL(fileURLWithPath: "/System"))
        }
    }

    @Test func desktopRootAcceptsTempHome() throws {
        let home = URL(fileURLWithPath: "/tmp/foldtint-home")
        let desktop = try DesktopRoot.resolve(home: home)
        #expect(desktop.lastPathComponent == "Desktop")
    }

    @Test func executableRelativePath() {
        let path = ExecutablePath.resolve(arguments: ["foldtint-rel"])
        #expect(path.hasSuffix("foldtint-rel") || path.contains("foldtint-rel"))
    }

    @Test func liveServiceUsesDesktop() throws {
        let service = try CommandService.live()
        #expect(service.root.lastPathComponent == "Desktop")
        #expect(!service.executablePath.isEmpty)
    }
}

struct ScanReportTests {
    @Test func addCountsEachAction() {
        var report = ScanReport()
        report.add(.applied)
        report.add(.applied)
        report.add(.reverted)
        report.add(.unchanged)
        report.add(.skipped)
        #expect(report.applied == 2)
        #expect(report.reverted == 1)
        #expect(report.unchanged == 1)
        #expect(report.skipped == 1)
        #expect(report.text.contains("applied: 2"))
    }
}

struct FoldtintErrorTests {
    @Test func descriptionsAreSet() {
        #expect(FoldtintError.refusedRoot.description.contains("not allowed"))
        #expect(FoldtintError.unknownColor.description.contains("color"))
        #expect(FoldtintError.configRead.description.contains("read"))
        #expect(FoldtintError.configWrite.description.contains("written"))
        #expect(FoldtintError.tagRead.description.contains("tags"))
        #expect(FoldtintError.tagWrite.description.contains("tags"))
        #expect(FoldtintError.agentFailed.description.contains("LaunchAgent"))
        #expect(FoldtintError.missingCommand.description.contains("required"))
        #expect(FoldtintError.extraArguments.description.contains("Too many"))
        #expect(FoldtintError.blockedWrite.description.contains("blocked"))
    }
}
