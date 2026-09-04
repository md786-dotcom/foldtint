import Foundation
import Testing
@testable import FoldtintKit

struct FolderScannerTests {
    @Test func listsOnlyTopLevelDirectories() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        let work = root.appendingPathComponent("Work")
        let nested = work.appendingPathComponent("Inbox")
        let file = root.appendingPathComponent("notes.txt")
        let app = root.appendingPathComponent("Mail.app")
        fileSystem.putDirectory(root)
        fileSystem.putDirectory(work, locked: true)
        fileSystem.putDirectory(nested, locked: true)
        fileSystem.nodes[fileSystem.key(file)] = MemoryFileSystem.Node(
            kind: .file,
            locked: false,
            tags: [],
            failWriteWhileLocked: false,
            failWrite: false
        )
        fileSystem.nodes[fileSystem.key(app)] = MemoryFileSystem.Node(
            kind: .package,
            locked: false,
            tags: [],
            failWriteWhileLocked: false,
            failWrite: false
        )
        let scanner = FolderScanner(fileSystem: fileSystem, policy: PathPolicy(root: root))
        let folders = try scanner.topLevelFolders()
        #expect(folders.count == 1)
        #expect(folders.contains(work))
    }
}
