import Foundation
import Testing
@testable import FoldtintKit

struct ConfigStoreTests {
    @Test func missingFileReturnsPurple() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-config-\(UUID().uuidString).json")
        let store = FileConfigStore(fileURL: file)
        #expect(try store.load() == FoldtintConfig(color: .purple))
    }

    @Test func saveLoadAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-conf-\(UUID().uuidString)", isDirectory: true)
        let file = directory.appendingPathComponent("config.json")
        let store = FileConfigStore(fileURL: file)
        try store.save(FoldtintConfig(color: .green))
        #expect(try store.load().color == .green)
        try store.delete()
        #expect(!FileManager.default.fileExists(atPath: file.path))
        #expect(try store.load().color == .purple)
        try store.delete()
        #expect(try store.load().color == .purple)
    }

    @Test func defaultStorePathContainsFoldtint() {
        let store = FileConfigStore.defaultStore()
        #expect(store.fileURL.path.contains("foldtint"))
        #expect(store.fileURL.lastPathComponent == "config.json")
    }

    @Test func deleteLeavesNonEmptyDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-keep-\(UUID().uuidString)", isDirectory: true)
        let file = directory.appendingPathComponent("config.json")
        let extra = directory.appendingPathComponent("other.txt")
        let store = FileConfigStore(fileURL: file)
        try store.save(FoldtintConfig(color: .blue))
        try Data("x".utf8).write(to: extra)
        try store.delete()
        #expect(FileManager.default.fileExists(atPath: extra.path))
        try FileManager.default.removeItem(at: directory)
    }

    @Test func corruptFileThrows() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-bad-\(UUID().uuidString).json")
        try Data("not-json".utf8).write(to: file)
        let store = FileConfigStore(fileURL: file)
        #expect(throws: FoldtintError.configRead) {
            _ = try store.load()
        }
        try FileManager.default.removeItem(at: file)
    }
}
