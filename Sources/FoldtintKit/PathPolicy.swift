import Foundation

struct PathPolicy: Sendable {
    let root: URL

    init(root: URL) {
        self.root = root.resolvingSymlinksInPath().standardizedFileURL
    }

    var rootPath: String {
        root.path
    }

    func isRoot(_ url: URL) -> Bool {
        standardize(url).path == rootPath
    }

    /// A nested folder is not in scope. Only a direct child of Desktop is valid.
    func isTopLevelItem(_ url: URL) -> Bool {
        let item = standardize(url)
        if item.lastPathComponent.hasPrefix(".") {
            return false
        }
        let parent = item.deletingLastPathComponent().standardizedFileURL
        return parent.path == rootPath
    }

    func allows(_ url: URL, kind: FolderKind) -> Bool {
        if kind != .directory {
            return false
        }
        if Self.isBlocked(standardize(url).path) {
            return false
        }
        return isTopLevelItem(url)
    }

    static func isBlocked(_ path: String) -> Bool {
        if path == "/" {
            return true
        }
        if path == "/System" || path.hasPrefix("/System/") {
            return true
        }
        if path == "/Applications" || path.hasPrefix("/Applications/") {
            return true
        }
        return false
    }

    private func standardize(_ url: URL) -> URL {
        url.standardizedFileURL
    }
}
