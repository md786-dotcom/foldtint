import Foundation
@testable import FoldtintKit

final class MemoryFileSystem: FolderFileSystem {
    struct Node {
        var kind: FolderKind
        var locked: Bool
        var tags: [FinderTag]
        var failWriteWhileLocked: Bool
        var failWrite: Bool
    }

    var nodes: [String: Node] = [:]

    func key(_ url: URL) -> String {
        url.standardizedFileURL.path
    }

    func putDirectory(_ url: URL, locked: Bool = false, tags: [FinderTag] = []) {
        nodes[key(url)] = Node(
            kind: .directory,
            locked: locked,
            tags: tags,
            failWriteWhileLocked: false,
            failWrite: false
        )
    }

    func kind(of url: URL) throws -> FolderKind {
        nodes[key(url)]?.kind ?? .missing
    }

    func isUserImmutable(_ url: URL) throws -> Bool {
        nodes[key(url)]?.locked ?? false
    }

    func setUserImmutable(_ flag: Bool, at url: URL) throws {
        guard var node = nodes[key(url)] else {
            return
        }
        node.locked = flag
        nodes[key(url)] = node
    }

    func readTags(at url: URL) throws -> [FinderTag] {
        nodes[key(url)]?.tags ?? []
    }

    func writeTags(_ tags: [FinderTag], at url: URL) throws {
        guard var node = nodes[key(url)] else {
            throw FoldtintError.tagWrite
        }
        if node.failWrite {
            throw FoldtintError.blockedWrite
        }
        if node.failWriteWhileLocked && node.locked {
            throw FoldtintError.blockedWrite
        }
        node.tags = tags
        nodes[key(url)] = node
    }

    func childNames(in directory: URL) throws -> [String] {
        let prefix = key(directory) + "/"
        var names: [String] = []
        for path in nodes.keys {
            guard path.hasPrefix(prefix) else {
                continue
            }
            let rest = String(path.dropFirst(prefix.count))
            if rest.contains("/") {
                continue
            }
            if !rest.isEmpty {
                names.append(rest)
            }
        }
        return names
    }

    func setFailWriteWhileLocked(_ url: URL, _ flag: Bool) {
        guard var node = nodes[key(url)] else {
            return
        }
        node.failWriteWhileLocked = flag
        nodes[key(url)] = node
    }

    func setFailWrite(_ url: URL, _ flag: Bool) {
        guard var node = nodes[key(url)] else {
            return
        }
        node.failWrite = flag
        nodes[key(url)] = node
    }
}

final class MemorySettings: SettingsStore {
    var config = FoldtintConfig(color: ColorName.defaultColor)
    var deleted = false

    func load() throws -> FoldtintConfig {
        if deleted {
            return FoldtintConfig(color: ColorName.defaultColor)
        }
        return config
    }

    func save(_ config: FoldtintConfig) throws {
        self.config = config
        deleted = false
    }

    func delete() throws {
        deleted = true
        config = FoldtintConfig(color: ColorName.defaultColor)
    }
}

final class MemoryAgent: AgentControl {
    var installedPath: String?
    var loaded = false

    func install(executable: String) throws {
        installedPath = executable
        loaded = true
    }

    func remove() throws {
        installedPath = nil
        loaded = false
    }

    func isLoaded() -> Bool {
        loaded
    }
}

final class ManualScheduler: TaskScheduling {
    private var pending: (() -> Void)?

    func runAfter(_ delay: TimeInterval, _ body: @escaping () -> Void) {
        pending = body
    }

    func cancelPending() {
        pending = nil
    }

    func fire() {
        let body = pending
        pending = nil
        body?()
    }
}

enum TestRoot {
    static func make() -> URL {
        URL(fileURLWithPath: "/tmp/foldtint-desktop")
    }

    static func service(
        fileSystem: MemoryFileSystem,
        settings: MemorySettings = MemorySettings(),
        agent: MemoryAgent = MemoryAgent()
    ) -> CommandService<MemoryFileSystem, MemorySettings, MemoryAgent> {
        CommandService(
            root: make(),
            fileSystem: fileSystem,
            settings: settings,
            agent: agent,
            executablePath: "/tmp/foldtint"
        )
    }
}
