import Dispatch
import Foundation

final class DispatchScheduler: TaskScheduling {
    private var item: DispatchWorkItem?

    func runAfter(_ delay: TimeInterval, _ body: @escaping () -> Void) {
        item?.cancel()
        let work = DispatchWorkItem(block: body)
        item = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func cancelPending() {
        item?.cancel()
        item = nil
    }
}

enum EventIngest {
    static func enqueue(
        path: String,
        filter: WatchFilter,
        rootPath: String,
        enqueue: (String) -> Void
    ) {
        switch filter.decision(path: path) {
        case .ignore:
            break
        case .scanRoot:
            enqueue(rootPath)
        case .syncPath(let url):
            enqueue(url.path)
        }
    }
}

enum DaemonRunner {
    nonisolated(unsafe) static var keepAlive: DesktopWatcher?

    static func runLive() throws {
        let service = try CommandService.live()
        start(service: service)
        CFRunLoopRun()
    }

    static func start(
        service: CommandService<LiveFileSystem, FileConfigStore, LaunchAgentController>
    ) {
        _ = try? service.scan()
        let debouncer = debouncer(for: service)
        keepAlive = watch(root: service.policy.rootPath, enqueue: { path in
            debouncer.enqueue(path)
        })
    }

    static func debouncer(
        for service: CommandService<LiveFileSystem, FileConfigStore, LaunchAgentController>
    ) -> Debouncer<DispatchScheduler> {
        Debouncer(
            delay: WatchLimits.debounceSeconds,
            cap: WatchLimits.pendingPathCap,
            scheduler: DispatchScheduler(),
            onFlush: { paths in
                flush(
                    paths: paths,
                    rootPath: service.policy.rootPath,
                    engine: service.engine,
                    settings: service.settings,
                    scanner: service.scanner
                )
            },
            onOverflow: {
                _ = try? service.scan()
            }
        )
    }

    @discardableResult
    static func watch(root: String, enqueue: @escaping (String) -> Void) -> DesktopWatcher {
        let filter = WatchFilter(policy: PathPolicy(root: URL(fileURLWithPath: root)))
        let watcher = DesktopWatcher()
        watcher.start(path: root) { path in
            EventIngest.enqueue(path: path, filter: filter, rootPath: root, enqueue: enqueue)
        }
        return watcher
    }

    static func flush<FS: FolderFileSystem, Settings: SettingsStore>(
        paths: Set<String>,
        rootPath: String,
        engine: SyncEngine<FS>,
        settings: Settings,
        scanner: FolderScanner<FS>
    ) {
        let color = (try? settings.load())?.color ?? ColorName.defaultColor
        if paths.contains(rootPath) {
            syncAll(engine: engine, scanner: scanner, color: color)
            return
        }
        for path in paths {
            _ = try? engine.sync(url: URL(fileURLWithPath: path), color: color)
        }
    }

    static func syncAll<FS: FolderFileSystem>(
        engine: SyncEngine<FS>,
        scanner: FolderScanner<FS>,
        color: ColorName
    ) {
        let folders = (try? scanner.topLevelFolders()) ?? []
        for url in folders {
            _ = try? engine.sync(url: url, color: color)
        }
    }
}
