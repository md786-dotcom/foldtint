import CoreServices
import Dispatch
import Foundation

final class CallbackBox {
    let onEvent: (String) -> Void

    init(onEvent: @escaping (String) -> Void) {
        self.onEvent = onEvent
    }
}

/// Directory-level stream only. Per-file events increase memory use.
final class DesktopWatcher {
    private var stream: FSEventStreamRef?
    private var box: Unmanaged<CallbackBox>?

    func start(path: String, onEvent: @escaping (String) -> Void) {
        let retained = Unmanaged.passRetained(CallbackBox(onEvent: onEvent))
        box = retained
        var context = FSEventStreamContext(
            version: 0,
            info: retained.toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let paths = [path] as CFArray
        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagNoDefer
                | kFSEventStreamCreateFlagWatchRoot
        )
        guard let created = FSEventStreamCreate(
            kCFAllocatorDefault,
            fseventCallback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            WatchLimits.debounceSeconds,
            flags
        ) else {
            retained.release()
            box = nil
            return
        }
        stream = created
        FSEventStreamSetDispatchQueue(created, DispatchQueue.main)
        FSEventStreamStart(created)
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        box?.release()
    }
}

// C callback signature is fixed by FSEventStream.
private func fseventCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let clientCallBackInfo else {
        return
    }
    _ = streamRef
    _ = eventFlags
    _ = eventIds
    let box = Unmanaged<CallbackBox>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
    let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
    let names = EventPathList.strings(from: paths, limit: numEvents)
    for name in names {
        box.onEvent(name)
    }
}
