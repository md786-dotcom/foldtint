import Foundation

struct FolderScanner<FS: FolderFileSystem> {
    let fileSystem: FS
    let policy: PathPolicy

    /// List only the first level under Desktop. Do not walk into a folder.
    func topLevelFolders() throws -> [URL] {
        let names = try fileSystem.childNames(in: policy.root)
        var folders: [URL] = []
        for name in names {
            let url = policy.root.appendingPathComponent(name)
            let kind = try fileSystem.kind(of: url)
            if policy.allows(url, kind: kind) {
                folders.append(url)
            }
        }
        return folders
    }
}
