import ArgumentParser
import Testing
@testable import FoldtintKit

struct CLIParseTests {
    @Test func parseColorAndScan() throws {
        _ = try FoldtintCommand.parseAsRoot(["color"])
        _ = try FoldtintCommand.parseAsRoot(["color", "red"])
        _ = try FoldtintCommand.parseAsRoot(["scan"])
        _ = try FoldtintCommand.parseAsRoot(["on"])
        _ = try FoldtintCommand.parseAsRoot(["off"])
        _ = try FoldtintCommand.parseAsRoot(["status"])
        _ = try FoldtintCommand.parseAsRoot(["daemon"])
        _ = try FoldtintCommand.parseAsRoot(["uninstall"])
    }

    @Test func runnerUsesService() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let service = TestRoot.service(fileSystem: fileSystem)
        #expect(try CommandKindRunner.output(.colorRead, service: service) == "purple")
        #expect(try CommandKindRunner.output(.scan, service: service).contains("applied"))
        #expect(try CommandKindRunner.output(.on, service: service) == "daemon on")
        #expect(try CommandKindRunner.output(.status, service: service).contains("daemon: on"))
        #expect(try CommandKindRunner.output(.off, service: service) == "daemon off")
        #expect(try CommandKindRunner.output(.uninstall, service: service).contains("uninstalled"))
        #expect(try CommandKindRunner.output(.daemon, service: service) == "")
        let colored = try CommandKindRunner.output(.colorSet(.green), service: TestRoot.service(fileSystem: fileSystem))
        #expect(colored.contains("color: green"))
    }

    @Test func commandsPrintStubOutput() throws {
        let previous = CommandKindRunner.liveOutput
        defer { CommandKindRunner.liveOutput = previous }
        var seen: [CommandKind] = []
        CommandKindRunner.liveOutput = { kind in
            seen.append(kind)
            return "ok"
        }
        try ColorCommand.parse([]).run()
        try ScanCommand.parse([]).run()
        try OnCommand.parse([]).run()
        try OffCommand.parse([]).run()
        try StatusCommand.parse([]).run()
        try DaemonCommand.parse([]).run()
        try UninstallCommand.parse([]).run()
        try ColorCommand.parse(["red"]).run()
        #expect(seen.contains(.colorRead))
        #expect(seen.contains(.colorSet(.red)))
        #expect(seen.contains(.scan))
        #expect(seen.contains(.on))
        #expect(seen.contains(.off))
        #expect(seen.contains(.status))
        #expect(seen.contains(.daemon))
        #expect(seen.contains(.uninstall))
    }

    @Test func parseRejectsUnknownColor() {
        #expect(throws: Error.self) {
            _ = try FoldtintCommand.parseAsRoot(["color", "neon"])
        }
    }

    @Test func parseRejectsUnknownCommand() {
        #expect(throws: Error.self) {
            _ = try FoldtintCommand.parseAsRoot(["paint"])
        }
    }
}
