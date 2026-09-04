import Foundation
import Testing
@testable import FoldtintKit

struct ImmutableSessionTests {
    @Test func writeSucceedsWithoutUnlock() throws {
        let fileSystem = MemoryFileSystem()
        let folder = TestRoot.make().appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        let session = ImmutableSession(fileSystem: fileSystem)
        try session.write(at: folder) {
            try fileSystem.writeTags([FinderTag(name: "Locked", colorIndex: 3)], at: folder)
        }
        #expect(try fileSystem.isUserImmutable(folder))
        #expect(TagCodec.hasLocked(try fileSystem.readTags(at: folder)))
    }

    @Test func lockedWriteFallsBackToUnlockWindow() throws {
        let fileSystem = MemoryFileSystem()
        let folder = TestRoot.make().appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        fileSystem.setFailWriteWhileLocked(folder, true)
        let session = ImmutableSession(fileSystem: fileSystem)
        try session.write(at: folder) {
            try fileSystem.writeTags([FinderTag(name: "Locked", colorIndex: 3)], at: folder)
        }
        #expect(try fileSystem.isUserImmutable(folder))
        #expect(TagCodec.hasLocked(try fileSystem.readTags(at: folder)))
    }

    @Test func unlockedFailureDoesNotToggleLock() throws {
        let fileSystem = MemoryFileSystem()
        let folder = TestRoot.make().appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: false)
        fileSystem.setFailWrite(folder, true)
        let session = ImmutableSession(fileSystem: fileSystem)
        #expect(throws: FoldtintError.blockedWrite) {
            try session.write(at: folder) {
                try fileSystem.writeTags([FinderTag(name: "Locked", colorIndex: 3)], at: folder)
            }
        }
        #expect(try fileSystem.isUserImmutable(folder) == false)
    }

    @Test func relocksAfterFailedRetry() throws {
        let fileSystem = MemoryFileSystem()
        let folder = TestRoot.make().appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        let session = ImmutableSession(fileSystem: fileSystem)
        #expect(throws: FoldtintError.tagWrite) {
            try session.write(at: folder) {
                throw FoldtintError.tagWrite
            }
        }
        #expect(try fileSystem.isUserImmutable(folder))
    }
}
