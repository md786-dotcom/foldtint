import Testing
@testable import FoldtintKit

struct TagCodecTests {
    @Test func parseColoredEntry() {
        let tag = TagCodec.parseEntry("Locked\n3")
        #expect(tag.name == "Locked")
        #expect(tag.colorIndex == 3)
    }

    @Test func parseNameOnlyUsesZero() {
        let tag = TagCodec.parseEntry("Work")
        #expect(tag.name == "Work")
        #expect(tag.colorIndex == 0)
    }

    @Test func parseInvalidIndexUsesZero() {
        let tag = TagCodec.parseEntry("Locked\nabc")
        #expect(tag.name == "Locked\nabc")
        #expect(tag.colorIndex == 0)
    }

    @Test func encodeJoinsNameAndIndex() {
        let tag = FinderTag(name: "Locked", colorIndex: 6)
        #expect(TagCodec.encode(tag) == "Locked\n6")
    }

    @Test func hasLockedDetectsName() {
        let tags = [FinderTag(name: "Work", colorIndex: 4), FinderTag(name: "Locked", colorIndex: 3)]
        #expect(TagCodec.hasLocked(tags))
        #expect(!TagCodec.hasLocked([FinderTag(name: "Work", colorIndex: 4)]))
    }

    @Test func lockedColorIndexReadsLockedTag() {
        let tags = [FinderTag(name: "Work", colorIndex: 4), FinderTag(name: "Locked", colorIndex: 3)]
        #expect(TagCodec.lockedColorIndex(tags) == 3)
        #expect(TagCodec.lockedColorIndex([FinderTag(name: "Work", colorIndex: 4)]) == nil)
    }

    @Test func applyingLockedPreservesOtherTags() {
        let tags = [FinderTag(name: "Work", colorIndex: 4)]
        let next = TagCodec.applyingLocked(to: tags, color: .purple)
        #expect(next.count == 2)
        #expect(next[0].name == "Work")
        #expect(next[1].name == TagCodec.lockedName)
        #expect(next[1].colorIndex == 3)
    }

    @Test func applyingLockedReplacesExistingLocked() {
        let tags = [FinderTag(name: "Locked", colorIndex: 6), FinderTag(name: "Work", colorIndex: 4)]
        let next = TagCodec.applyingLocked(to: tags, color: .blue)
        #expect(next.count == 2)
        #expect(TagCodec.lockedColorIndex(next) == 4)
        #expect(next.contains { $0.name == "Work" })
    }

    @Test func removingLockedKeepsOthers() {
        let tags = [FinderTag(name: "Work", colorIndex: 4), FinderTag(name: "Locked", colorIndex: 3)]
        let next = TagCodec.removingLocked(from: tags)
        #expect(next == [FinderTag(name: "Work", colorIndex: 4)])
    }
}
