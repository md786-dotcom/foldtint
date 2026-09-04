import Foundation

enum SyncAction: Equatable {
    case skipped
    case unchanged
    case applied
    case reverted
}

struct SyncEngine<FS: FolderFileSystem> {
    let fileSystem: FS
    let policy: PathPolicy

    func sync(url: URL, color: ColorName) throws -> SyncAction {
        let kind = try fileSystem.kind(of: url)
        guard policy.allows(url, kind: kind) else {
            return .skipped
        }
        let locked = try fileSystem.isUserImmutable(url)
        let tags = try fileSystem.readTags(at: url)
        if locked {
            return try applyLocked(url: url, tags: tags, color: color)
        }
        return try revertUnlocked(url: url, tags: tags)
    }

    func stripLocked(url: URL) throws -> SyncAction {
        let kind = try fileSystem.kind(of: url)
        guard policy.allows(url, kind: kind) else {
            return .skipped
        }
        let tags = try fileSystem.readTags(at: url)
        return try revertUnlocked(url: url, tags: tags)
    }

    private func applyLocked(url: URL, tags: [FinderTag], color: ColorName) throws -> SyncAction {
        if TagCodec.lockedColorIndex(tags) == color.tagColorIndex {
            return .unchanged
        }
        let next = TagCodec.applyingLocked(to: tags, color: color)
        try writeTags(next, at: url)
        return .applied
    }

    private func revertUnlocked(url: URL, tags: [FinderTag]) throws -> SyncAction {
        if !TagCodec.hasLocked(tags) {
            return .unchanged
        }
        let next = TagCodec.removingLocked(from: tags)
        try writeTags(next, at: url)
        return .reverted
    }

    private func writeTags(_ tags: [FinderTag], at url: URL) throws {
        let session = ImmutableSession(fileSystem: fileSystem)
        try session.write(at: url) {
            try fileSystem.writeTags(tags, at: url)
        }
    }
}
