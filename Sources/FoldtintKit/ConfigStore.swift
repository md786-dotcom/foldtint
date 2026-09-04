import Foundation

struct FoldtintConfig: Codable, Equatable, Sendable {
    var color: ColorName
}

struct FileConfigStore: SettingsStore {
    let fileURL: URL

    static func defaultStore() -> FileConfigStore {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directory = support.appendingPathComponent("foldtint", isDirectory: true)
        let file = directory.appendingPathComponent("config.json")
        return FileConfigStore(fileURL: file)
    }

    func load() throws -> FoldtintConfig {
        let manager = FileManager.default
        if !manager.fileExists(atPath: fileURL.path) {
            return FoldtintConfig(color: ColorName.defaultColor)
        }
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw FoldtintError.configRead
        }
        do {
            return try JSONDecoder().decode(FoldtintConfig.self, from: data)
        } catch {
            throw FoldtintError.configRead
        }
    }

    func save(_ config: FoldtintConfig) throws {
        let directory = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(config)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw FoldtintError.configWrite
        }
    }

    func delete() throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: fileURL.path) {
            try manager.removeItem(at: fileURL)
        }
        let directory = fileURL.deletingLastPathComponent()
        removeEmptyDirectory(directory, manager: manager)
    }

    private func removeEmptyDirectory(_ directory: URL, manager: FileManager) {
        let names = try? manager.contentsOfDirectory(atPath: directory.path)
        guard let names, names.isEmpty else {
            return
        }
        try? manager.removeItem(at: directory)
    }
}
