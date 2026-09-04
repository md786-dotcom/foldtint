import Foundation
import Testing
@testable import FoldtintKit

struct CommandServiceTests {
    @Test func scanAppliesAndReverts() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let locked = root.appendingPathComponent("LockedFolder")
        let unlocked = root.appendingPathComponent("OpenFolder")
        fileSystem.putDirectory(locked, locked: true)
        fileSystem.putDirectory(
            unlocked,
            locked: false,
            tags: [FinderTag(name: "Locked", colorIndex: 3)]
        )
        let service = TestRoot.service(fileSystem: fileSystem)
        let report = try service.scanReport()
        #expect(report.applied == 1)
        #expect(report.reverted == 1)
        #expect(report.text.contains("applied: 1"))
        #expect(try service.scan().contains("unchanged: 2"))
    }

    @Test func colorSetSavesAndRescans() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        let settings = MemorySettings()
        let service = TestRoot.service(fileSystem: fileSystem, settings: settings)
        let output = try service.colorSet(.red)
        #expect(settings.config.color == .red)
        #expect(output.contains("color: red"))
        #expect(TagCodec.lockedColorIndex(try fileSystem.readTags(at: folder)) == 6)
        #expect(try service.colorRead() == "red")
    }

    @Test func onOffAndStatus() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        let agent = MemoryAgent()
        let service = TestRoot.service(fileSystem: fileSystem, agent: agent)
        #expect(try service.on() == "daemon on")
        #expect(agent.loaded)
        #expect(agent.installedPath == "/tmp/foldtint")
        let text = try service.status()
        #expect(text.contains("color: purple"))
        #expect(text.contains("daemon: on"))
        #expect(text.contains("locked: 1"))
        #expect(text.contains("tinted: 1"))
        #expect(try service.off() == "daemon off")
        #expect(!agent.loaded)
        #expect(try service.status().contains("daemon: off"))
    }

    @Test func uninstallStripsTagsKeepsLock() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        let nested = folder.appendingPathComponent("Inbox")
        fileSystem.putDirectory(nested, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        let settings = MemorySettings()
        let agent = MemoryAgent()
        agent.loaded = true
        let service = TestRoot.service(fileSystem: fileSystem, settings: settings, agent: agent)
        let output = try service.uninstall()
        #expect(output.contains("stripped: 1"))
        #expect(!agent.loaded)
        #expect(settings.deleted)
        #expect(try fileSystem.readTags(at: folder).isEmpty)
        #expect(try fileSystem.isUserImmutable(folder))
        #expect(TagCodec.hasLocked(try fileSystem.readTags(at: nested)))
    }
}
