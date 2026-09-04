import Foundation

enum WatchDecision: Equatable {
    case ignore
    case scanRoot
    case syncPath(URL)
}

struct WatchFilter: Sendable {
    let policy: PathPolicy

    func decision(path: String) -> WatchDecision {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        if policy.isRoot(url) {
            return .scanRoot
        }
        if policy.isTopLevelItem(url) {
            return .syncPath(url)
        }
        return .ignore
    }
}
