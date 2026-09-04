import Foundation

struct ImmutableSession<FS: FolderFileSystem> {
    let fileSystem: FS

    /// The Finder lock can block a tag write. Clear the lock only for that write, then set it again.
    func write(at url: URL, operation: () throws -> Void) throws {
        do {
            try operation()
            return
        } catch {
            let locked = try fileSystem.isUserImmutable(url)
            if !locked {
                throw error
            }
        }
        try fileSystem.setUserImmutable(false, at: url)
        do {
            try operation()
        } catch {
            try fileSystem.setUserImmutable(true, at: url)
            throw error
        }
        try fileSystem.setUserImmutable(true, at: url)
    }
}
