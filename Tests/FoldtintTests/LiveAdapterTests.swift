import CoreFoundation
import Foundation
import Testing
@testable import FoldtintKit

struct EventPathListTests {
    @Test func readsStringArray() {
        let array = ["/tmp/a", "/tmp/b"] as CFArray
        let names = EventPathList.strings(from: array, limit: 2)
        #expect(names == ["/tmp/a", "/tmp/b"])
    }

    @Test func limitTruncates() {
        let array = ["a", "b", "c"] as CFArray
        let names = EventPathList.strings(from: array, limit: 1)
        #expect(names == ["a"])
    }

    @Test func zeroLimitIsEmpty() {
        let array = ["a"] as CFArray
        #expect(EventPathList.strings(from: array, limit: 0).isEmpty)
    }
}

struct DaemonFlushTests {
    @Test func flushSyncsListedPaths() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        let engine = SyncEngine(fileSystem: fileSystem, policy: PathPolicy(root: root))
        let settings = MemorySettings()
        let scanner = FolderScanner(fileSystem: fileSystem, policy: PathPolicy(root: root))
        DaemonRunner.flush(
            paths: [folder.path],
            rootPath: root.path,
            engine: engine,
            settings: settings,
            scanner: scanner
        )
        #expect(TagCodec.hasLocked(try fileSystem.readTags(at: folder)))
    }

    @Test func flushRootScansChildren() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        let engine = SyncEngine(fileSystem: fileSystem, policy: PathPolicy(root: root))
        DaemonRunner.flush(
            paths: [root.path],
            rootPath: root.path,
            engine: engine,
            settings: MemorySettings(),
            scanner: FolderScanner(fileSystem: fileSystem, policy: PathPolicy(root: root))
        )
        #expect(TagCodec.hasLocked(try fileSystem.readTags(at: folder)))
    }

    @Test func ingestEnqueuesTopLevelAndRoot() {
        let root = TestRoot.make()
        let filter = WatchFilter(policy: PathPolicy(root: root))
        var queued: [String] = []
        EventIngest.enqueue(path: root.path, filter: filter, rootPath: root.path) { queued.append($0) }
        EventIngest.enqueue(
            path: root.appendingPathComponent("Work").path,
            filter: filter,
            rootPath: root.path
        ) { queued.append($0) }
        EventIngest.enqueue(
            path: root.appendingPathComponent("Work").appendingPathComponent("Inbox").path,
            filter: filter,
            rootPath: root.path
        ) { queued.append($0) }
        #expect(queued.count == 2)
        #expect(queued[0] == root.path)
    }

    @Test func flushUsesDefaultColorWhenSettingsFail() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        struct BrokenSettings: SettingsStore {
            func load() throws -> FoldtintConfig { throw FoldtintError.configRead }
            func save(_ config: FoldtintConfig) throws {}
            func delete() throws {}
        }
        DaemonRunner.flush(
            paths: [folder.path],
            rootPath: root.path,
            engine: SyncEngine(fileSystem: fileSystem, policy: PathPolicy(root: root)),
            settings: BrokenSettings(),
            scanner: FolderScanner(fileSystem: fileSystem, policy: PathPolicy(root: root))
        )
        #expect(TagCodec.lockedColorIndex(try fileSystem.readTags(at: folder)) == ColorName.defaultColor.tagColorIndex)
    }

    @Test func syncAllAppliesChildren() throws {
        let root = TestRoot.make()
        let fileSystem = MemoryFileSystem()
        fileSystem.putDirectory(root)
        let folder = root.appendingPathComponent("Work")
        fileSystem.putDirectory(folder, locked: true)
        DaemonRunner.syncAll(
            engine: SyncEngine(fileSystem: fileSystem, policy: PathPolicy(root: root)),
            scanner: FolderScanner(fileSystem: fileSystem, policy: PathPolicy(root: root)),
            color: .green
        )
        #expect(TagCodec.lockedColorIndex(try fileSystem.readTags(at: folder)) == 2)
    }
}

struct LiveFileSystemTests {
    @Test func tagsAndLockRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-live-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fs = LiveFileSystem()
        #expect(try fs.kind(of: directory) == .directory)
        try fs.writeTags([FinderTag(name: "Locked", colorIndex: 3)], at: directory)
        let tags = try fs.readTags(at: directory)
        #expect(TagCodec.lockedColorIndex(tags) == 3)
        try fs.writeTags([], at: directory)
        #expect(try fs.readTags(at: directory).isEmpty)
        try fs.setUserImmutable(true, at: directory)
        #expect(try fs.isUserImmutable(directory))
        try fs.setUserImmutable(false, at: directory)
        #expect(try fs.isUserImmutable(directory) == false)
        let names = try fs.childNames(in: directory.deletingLastPathComponent())
        #expect(names.contains(directory.lastPathComponent))
    }

    @Test func missingPathIsMissingKind() throws {
        let url = URL(fileURLWithPath: "/tmp/foldtint-missing-\(UUID().uuidString)")
        #expect(try LiveFileSystem().kind(of: url) == .missing)
    }

    @Test func fileKind() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-file-\(UUID().uuidString)")
        try Data("x".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(try LiveFileSystem().kind(of: file) == .file)
        #expect(try LiveFileSystem().readTags(at: file).isEmpty)
    }

    @Test func watcherStartsAndStops() {
        let watcher = DesktopWatcher()
        watcher.start(path: FileManager.default.temporaryDirectory.path) { _ in }
    }

    @Test func processRunnerTrue() throws {
        let status = try ProcessRunner.run("/usr/bin/true", [])
        #expect(status == 0)
    }

    @Test func processRunnerFalse() throws {
        let status = try ProcessRunner.run("/usr/bin/false", [])
        #expect(status != 0)
    }

    @Test func symlinkKind() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-link-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let target = directory.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        let link = directory.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        #expect(try LiveFileSystem().kind(of: link) == .symbolicLink)
        let app = directory.appendingPathComponent("Demo.app")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let kind = try LiveFileSystem().kind(of: app)
        #expect(kind == .package || kind == .directory)
    }

    @Test func launchAgentWritesPlistWithoutLaunchctl() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldtint-agent-\(UUID().uuidString)", isDirectory: true)
        let plist = directory.appendingPathComponent("com.foldtint.daemon.plist")
        let agent = LaunchAgentController(plistURL: plist, usesLaunchctl: false)
        try agent.install(executable: "/tmp/foldtint")
        #expect(FileManager.default.fileExists(atPath: plist.path))
        let xml = try String(contentsOf: plist, encoding: .utf8)
        #expect(xml.contains("/tmp/foldtint"))
        #expect(agent.isLoaded() == false)
        try agent.remove()
        #expect(!FileManager.default.fileExists(atPath: plist.path))
        try agent.remove()
    }

    @Test func watchRetainsStream() {
        var paths: [String] = []
        let watcher = DaemonRunner.watch(root: FileManager.default.temporaryDirectory.path) { path in
            paths.append(path)
        }
        #expect(paths.isEmpty)
        _ = watcher
    }
}

struct DispatchSchedulerTests {
    @Test func cancelClearsWork() {
        let scheduler = DispatchScheduler()
        var ran = false
        scheduler.runAfter(60) {
            ran = true
        }
        scheduler.cancelPending()
        #expect(!ran)
    }
}
