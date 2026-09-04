import Foundation

struct LiveFileSystem: FolderFileSystem {
    func kind(of url: URL) throws -> FolderKind {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .isPackageKey,
            .isAliasFileKey,
        ]
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: keys)
        } catch {
            return .missing
        }
        if values.isSymbolicLink == true || values.isAliasFile == true {
            return .symbolicLink
        }
        if values.isPackage == true {
            return .package
        }
        if values.isDirectory == true {
            return .directory
        }
        return .file
    }

    func isUserImmutable(_ url: URL) throws -> Bool {
        let values = try url.resourceValues(forKeys: [.isUserImmutableKey])
        return values.isUserImmutable ?? false
    }

    func setUserImmutable(_ flag: Bool, at url: URL) throws {
        var working = url
        var values = URLResourceValues()
        values.isUserImmutable = flag
        try working.setResourceValues(values)
    }

    func readTags(at url: URL) throws -> [FinderTag] {
        let data = try ExtendedAttribute.read(name: ExtendedAttribute.tagsName, from: url)
        guard let data else {
            return []
        }
        let raw: [String]
        do {
            raw = try PropertyListDecoder().decode([String].self, from: data)
        } catch {
            throw FoldtintError.tagRead
        }
        return raw.map(TagCodec.parseEntry)
    }

    func writeTags(_ tags: [FinderTag], at url: URL) throws {
        if tags.isEmpty {
            try ExtendedAttribute.remove(name: ExtendedAttribute.tagsName, from: url)
            return
        }
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let raw = tags.map(TagCodec.encode)
        let data: Data
        do {
            data = try encoder.encode(raw)
        } catch {
            throw FoldtintError.tagWrite
        }
        try ExtendedAttribute.write(name: ExtendedAttribute.tagsName, data: data, to: url)
    }

    func childNames(in directory: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
    }
}
