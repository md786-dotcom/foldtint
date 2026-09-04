import Foundation
import Testing
@testable import FoldtintKit

struct WatchFilterTests {
    let root = URL(fileURLWithPath: "/tmp/foldtint-desktop")
    var filter: WatchFilter { WatchFilter(policy: PathPolicy(root: root)) }

    @Test func rootEventScans() {
        #expect(filter.decision(path: root.path) == .scanRoot)
    }

    @Test func topLevelFolderSyncs() {
        let url = root.appendingPathComponent("Work")
        #expect(filter.decision(path: url.path) == .syncPath(url.standardizedFileURL))
    }

    @Test func nestedPathIsIgnored() {
        let url = root.appendingPathComponent("Work").appendingPathComponent("Inbox")
        #expect(filter.decision(path: url.path) == .ignore)
    }

    @Test func outsidePathIsIgnored() {
        #expect(filter.decision(path: "/tmp/other") == .ignore)
    }

    @Test func hiddenTopLevelIsIgnored() {
        let url = root.appendingPathComponent(".hidden")
        #expect(filter.decision(path: url.path) == .ignore)
    }
}
