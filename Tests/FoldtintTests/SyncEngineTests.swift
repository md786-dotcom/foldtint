import Foundation
import Testing
@testable import FoldtintKit

struct SyncEngineTests {
    let root = TestRoot.make()

    func engine(_ fileSystem: MemoryFileSystem) -> SyncEngine<MemoryFileSystem> {
        SyncEngine(fileSystem: fileSystem, policy: PathPolicy(root: root))
    }

    @Test func lockAppliesLockedTag() throws {
        let fileSystem = MemoryFileSystem()
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Work", colorIndex: 4)])
        let action = try engine(fileSystem).sync(url: folder, color: .purple)
        #expect(action == .applied)
        let tags = try fileSystem.readTags(at: folder)
        #expect(TagCodec.hasLocked(tags))
        #expect(TagCodec.lockedColorIndex(tags) == 3)
        #expect(tags.contains { $0.name == "Work" })
        #expect(fileSystem.nodes[fileSystem.key(folder)]?.locked == true)
    }

    @Test func unlockRemovesOnlyLockedTag() throws {
        let fileSystem = MemoryFileSystem()
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(
            folder,
            locked: false,
            tags: [FinderTag(name: "Work", colorIndex: 4), FinderTag(name: "Locked", colorIndex: 3)]
        )
        let action = try engine(fileSystem).sync(url: folder, color: .purple)
        #expect(action == .reverted)
        let tags = try fileSystem.readTags(at: folder)
        #expect(tags == [FinderTag(name: "Work", colorIndex: 4)])
    }

    @Test func alreadyCorrectIsUnchanged() throws {
        let fileSystem = MemoryFileSystem()
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        #expect(try engine(fileSystem).sync(url: folder, color: .purple) == .unchanged)
        fileSystem.putDirectory(folder, locked: false, tags: [])
        #expect(try engine(fileSystem).sync(url: folder, color: .purple) == .unchanged)
    }

    @Test func colorChangeUpdatesLockedTag() throws {
        let fileSystem = MemoryFileSystem()
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 6)])
        #expect(try engine(fileSystem).sync(url: folder, color: .blue) == .applied)
        #expect(TagCodec.lockedColorIndex(try fileSystem.readTags(at: folder)) == 4)
    }

    @Test func nestedAndFileAreSkipped() throws {
        let fileSystem = MemoryFileSystem()
        let nested = root.appendingPathComponent("Work").appendingPathComponent("Inbox")
        fileSystem.putDirectory(nested, locked: true)
        #expect(try engine(fileSystem).sync(url: nested, color: .purple) == .skipped)
        let file = root.appendingPathComponent("notes.txt")
        fileSystem.nodes[fileSystem.key(file)] = MemoryFileSystem.Node(
            kind: .file,
            locked: true,
            tags: [],
            failWriteWhileLocked: false,
            failWrite: false
        )
        #expect(try engine(fileSystem).sync(url: file, color: .purple) == .skipped)
    }

    @Test func stripRemovesTagWhileLocked() throws {
        let fileSystem = MemoryFileSystem()
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        #expect(try engine(fileSystem).stripLocked(url: folder) == .reverted)
        #expect(try fileSystem.readTags(at: folder).isEmpty)
        #expect(try fileSystem.isUserImmutable(folder))
    }

    @Test func stripSkipsNested() throws {
        let fileSystem = MemoryFileSystem()
        let nested = root.appendingPathComponent("Work").appendingPathComponent("Inbox")
        fileSystem.putDirectory(nested, locked: true, tags: [FinderTag(name: "Locked", colorIndex: 3)])
        #expect(try engine(fileSystem).stripLocked(url: nested) == .skipped)
    }
}
