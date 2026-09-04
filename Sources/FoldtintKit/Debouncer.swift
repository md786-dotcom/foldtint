import Foundation

enum WatchLimits {
    static let debounceSeconds: TimeInterval = 0.15
    static let pendingPathCap = 256
}

final class Debouncer<Scheduler: TaskScheduling> {
    private var pending: Set<String> = []
    private var overflow = false
    private let delay: TimeInterval
    private let cap: Int
    private let scheduler: Scheduler
    private let onFlush: (Set<String>) -> Void
    private let onOverflow: () -> Void

    init(
        delay: TimeInterval,
        cap: Int,
        scheduler: Scheduler,
        onFlush: @escaping (Set<String>) -> Void,
        onOverflow: @escaping () -> Void
    ) {
        self.delay = delay
        self.cap = cap
        self.scheduler = scheduler
        self.onFlush = onFlush
        self.onOverflow = onOverflow
    }

    func enqueue(_ path: String) {
        if pending.count >= cap && !pending.contains(path) {
            pending.removeAll(keepingCapacity: true)
            overflow = true
            schedule()
            return
        }
        pending.insert(path)
        overflow = false
        schedule()
    }

    private func schedule() {
        scheduler.cancelPending()
        scheduler.runAfter(delay) { [weak self] in
            self?.flush()
        }
    }

    private func flush() {
        if overflow {
            overflow = false
            pending.removeAll(keepingCapacity: true)
            onOverflow()
            return
        }
        let batch = pending
        pending.removeAll(keepingCapacity: true)
        onFlush(batch)
    }
}
