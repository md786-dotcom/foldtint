import Testing
@testable import FoldtintKit

struct DebouncerTests {
    @Test func coalescesPathsUntilFire() {
        let scheduler = ManualScheduler()
        var flushed: Set<String> = []
        var overflowed = false
        let debouncer = Debouncer(
            delay: 0.15,
            cap: 4,
            scheduler: scheduler,
            onFlush: { flushed = $0 },
            onOverflow: { overflowed = true }
        )
        debouncer.enqueue("/tmp/a")
        debouncer.enqueue("/tmp/b")
        #expect(flushed.isEmpty)
        scheduler.fire()
        #expect(flushed == ["/tmp/a", "/tmp/b"])
        #expect(!overflowed)
    }

    @Test func overflowRunsScanCallback() {
        let scheduler = ManualScheduler()
        var flushed: Set<String> = []
        var overflowed = false
        let debouncer = Debouncer(
            delay: 0.15,
            cap: 2,
            scheduler: scheduler,
            onFlush: { flushed = $0 },
            onOverflow: { overflowed = true }
        )
        debouncer.enqueue("/tmp/a")
        debouncer.enqueue("/tmp/b")
        debouncer.enqueue("/tmp/c")
        scheduler.fire()
        #expect(overflowed)
        #expect(flushed.isEmpty)
    }

    @Test func duplicatePathDoesNotOverflow() {
        let scheduler = ManualScheduler()
        var overflowed = false
        let debouncer = Debouncer(
            delay: 0.15,
            cap: 1,
            scheduler: scheduler,
            onFlush: { _ in },
            onOverflow: { overflowed = true }
        )
        debouncer.enqueue("/tmp/a")
        debouncer.enqueue("/tmp/a")
        scheduler.fire()
        #expect(!overflowed)
    }
}
