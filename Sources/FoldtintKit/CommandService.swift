import Foundation

struct ScanReport: Equatable {
    var applied = 0
    var reverted = 0
    var unchanged = 0
    var skipped = 0

    mutating func add(_ action: SyncAction) {
        switch action {
        case .applied:
            applied += 1
        case .reverted:
            reverted += 1
        case .unchanged:
            unchanged += 1
        case .skipped:
            skipped += 1
        }
    }

    var text: String {
        """
        applied: \(applied)
        reverted: \(reverted)
        unchanged: \(unchanged)
        skipped: \(skipped)
        """
    }
}

struct CommandService<FS: FolderFileSystem, Settings: SettingsStore, Agent: AgentControl> {
    let root: URL
    let fileSystem: FS
    let settings: Settings
    let agent: Agent
    let executablePath: String

    var policy: PathPolicy {
        PathPolicy(root: root)
    }

    var engine: SyncEngine<FS> {
        SyncEngine(fileSystem: fileSystem, policy: policy)
    }

    var scanner: FolderScanner<FS> {
        FolderScanner(fileSystem: fileSystem, policy: policy)
    }

    func colorRead() throws -> String {
        let config = try settings.load()
        return config.color.rawValue
    }

    func colorSet(_ color: ColorName) throws -> String {
        try settings.save(FoldtintConfig(color: color))
        let report = try scan()
        return "color: \(color.rawValue)\n\(report)"
    }

    func scan() throws -> String {
        try scanReport().text
    }

    func scanReport() throws -> ScanReport {
        let color = try settings.load().color
        var report = ScanReport()
        let folders = try scanner.topLevelFolders()
        for url in folders {
            let action = try engine.sync(url: url, color: color)
            report.add(action)
        }
        return report
    }

    func on() throws -> String {
        try agent.install(executable: executablePath)
        return "daemon on"
    }

    func off() throws -> String {
        try agent.remove()
        return "daemon off"
    }

    func status() throws -> String {
        let color = try settings.load().color
        let loaded = agent.isLoaded()
        var locked = 0
        var tinted = 0
        let folders = try scanner.topLevelFolders()
        for url in folders {
            if try fileSystem.isUserImmutable(url) {
                locked += 1
            }
            if TagCodec.hasLocked(try fileSystem.readTags(at: url)) {
                tinted += 1
            }
        }
        return """
        color: \(color.rawValue)
        desktop: \(root.path)
        daemon: \(loaded ? "on" : "off")
        locked: \(locked)
        tinted: \(tinted)
        """
    }

    func uninstall() throws -> String {
        try agent.remove()
        var stripped = 0
        let folders = try scanner.topLevelFolders()
        for url in folders {
            let action = try engine.stripLocked(url: url)
            if action == .reverted {
                stripped += 1
            }
        }
        try settings.delete()
        return "uninstalled\nstripped: \(stripped)"
    }
}

extension CommandService where FS == LiveFileSystem, Settings == FileConfigStore, Agent == LaunchAgentController {
    static func live() throws -> CommandService<LiveFileSystem, FileConfigStore, LaunchAgentController> {
        CommandService(
            root: try DesktopRoot.resolve(),
            fileSystem: LiveFileSystem(),
            settings: FileConfigStore.defaultStore(),
            agent: LaunchAgentController(),
            executablePath: ExecutablePath.resolve()
        )
    }
}
