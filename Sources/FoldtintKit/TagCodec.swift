enum TagCodec {
    static let lockedName = "Locked"

    static func parseEntry(_ raw: String) -> FinderTag {
        let parts = raw.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let index = Int(parts[1]) else {
            return FinderTag(name: raw, colorIndex: 0)
        }
        return FinderTag(name: String(parts[0]), colorIndex: index)
    }

    static func encode(_ tag: FinderTag) -> String {
        "\(tag.name)\n\(tag.colorIndex)"
    }

    static func hasLocked(_ tags: [FinderTag]) -> Bool {
        tags.contains { tag in
            tag.name == lockedName
        }
    }

    static func lockedColorIndex(_ tags: [FinderTag]) -> Int? {
        tags.first { tag in
            tag.name == lockedName
        }?.colorIndex
    }

    static func applyingLocked(to tags: [FinderTag], color: ColorName) -> [FinderTag] {
        let others = removingLocked(from: tags)
        let locked = FinderTag(name: lockedName, colorIndex: color.tagColorIndex)
        return others + [locked]
    }

    static func removingLocked(from tags: [FinderTag]) -> [FinderTag] {
        tags.filter { tag in
            tag.name != lockedName
        }
    }
}
