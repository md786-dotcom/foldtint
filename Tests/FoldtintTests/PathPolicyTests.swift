import Foundation
import Testing
@testable import FoldtintKit

struct PathPolicyTests {
    let root = URL(fileURLWithPath: "/tmp/foldtint-desktop")
    var policy: PathPolicy { PathPolicy(root: root) }

    @Test func allowsTopLevelDirectory() {
        let url = root.appendingPathComponent("Work")
        #expect(policy.allows(url, kind: .directory))
    }

    @Test func rejectsNestedDirectory() {
        let url = root.appendingPathComponent("Work").appendingPathComponent("Inbox")
        #expect(!policy.allows(url, kind: .directory))
        #expect(!policy.isTopLevelItem(url))
    }

    @Test func rejectsRootItself() {
        #expect(!policy.allows(root, kind: .directory))
        #expect(policy.isRoot(root))
        #expect(!policy.isTopLevelItem(root))
    }

    @Test func rejectsFileAndPackageAndSymlink() {
        let url = root.appendingPathComponent("Work")
        #expect(!policy.allows(url, kind: .file))
        #expect(!policy.allows(url, kind: .package))
        #expect(!policy.allows(url, kind: .symbolicLink))
        #expect(!policy.allows(url, kind: .missing))
    }

    @Test func rejectsHiddenName() {
        let url = root.appendingPathComponent(".secret")
        #expect(!policy.isTopLevelItem(url))
        #expect(!policy.allows(url, kind: .directory))
    }

    @Test func blockedPaths() {
        #expect(PathPolicy.isBlocked("/"))
        #expect(PathPolicy.isBlocked("/System"))
        #expect(PathPolicy.isBlocked("/System/Library"))
        #expect(PathPolicy.isBlocked("/Applications"))
        #expect(PathPolicy.isBlocked("/Applications/Xcode.app"))
        #expect(!PathPolicy.isBlocked("/tmp/foldtint-desktop"))
        #expect(!PathPolicy.isBlocked("/Users/demo/Desktop"))
    }

    @Test func blockedTopLevelIsRejected() {
        let systemRoot = URL(fileURLWithPath: "/System")
        let policy = PathPolicy(root: systemRoot)
        let child = systemRoot.appendingPathComponent("Child")
        #expect(!policy.allows(child, kind: .directory))
    }
}
