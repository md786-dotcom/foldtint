import ArgumentParser

public struct FoldtintCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "foldtint",
        abstract: "Tint locked top-level Desktop folders.",
        subcommands: [
            ColorCommand.self,
            ScanCommand.self,
            OnCommand.self,
            OffCommand.self,
            StatusCommand.self,
            DaemonCommand.self,
            UninstallCommand.self,
        ]
    )

    public init() {}
}

enum CommandKind: Equatable {
    case colorRead
    case colorSet(ColorName)
    case scan
    case on
    case off
    case status
    case daemon
    case uninstall
}

enum CommandKindRunner {
    nonisolated(unsafe) static var liveOutput: (CommandKind) throws -> String = defaultLive

    static func defaultLive(_ kind: CommandKind) throws -> String {
        if kind == .daemon {
            try DaemonRunner.runLive()
            return ""
        }
        return try output(kind, service: CommandService.live())
    }

    static func output<FS: FolderFileSystem, Settings: SettingsStore, Agent: AgentControl>(
        _ kind: CommandKind,
        service: CommandService<FS, Settings, Agent>
    ) throws -> String {
        switch kind {
        case .colorRead:
            return try service.colorRead()
        case .colorSet(let color):
            return try service.colorSet(color)
        case .scan:
            return try service.scan()
        case .on:
            return try service.on()
        case .off:
            return try service.off()
        case .status:
            return try service.status()
        case .uninstall:
            return try service.uninstall()
        case .daemon:
            return ""
        }
    }
}

struct ColorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "color",
        abstract: "Show or set the locked-folder color."
    )

    @Argument(help: "gray, green, purple, blue, yellow, red, or orange")
    var name: ColorName?

    func run() throws {
        let kind: CommandKind
        if let name {
            kind = .colorSet(name)
        } else {
            kind = .colorRead
        }
        print(try CommandKindRunner.liveOutput(kind))
    }
}

struct ScanCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Apply or remove the Locked tag on top-level Desktop folders."
    )

    func run() throws {
        print(try CommandKindRunner.liveOutput(.scan))
    }
}

struct OnCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "on",
        abstract: "Start the Desktop lock watcher."
    )

    func run() throws {
        print(try CommandKindRunner.liveOutput(.on))
    }
}

struct OffCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "off",
        abstract: "Stop the Desktop lock watcher."
    )

    func run() throws {
        print(try CommandKindRunner.liveOutput(.off))
    }
}

struct StatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show color, daemon state, and folder counts."
    )

    func run() throws {
        print(try CommandKindRunner.liveOutput(.status))
    }
}

struct DaemonCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "daemon",
        abstract: "Run the Desktop lock watcher."
    )

    func run() throws {
        _ = try CommandKindRunner.liveOutput(.daemon)
    }
}

struct UninstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Stop the watcher, remove Locked tags, and delete configuration."
    )

    func run() throws {
        print(try CommandKindRunner.liveOutput(.uninstall))
    }
}
