import XCTest
@testable import OSXStatsNano

final class StatsPollerTests: XCTestCase {

    // Config with minimum intervals so tests don't wait 2s per tick
    private var fastConfig: AppConfig {
        var c = AppConfig()
        c.cpuInterval = 0.5
        c.memoryInterval = 0.5
        c.gpuInterval = 1.0
        c.networkInterval = 0.5
        return c
    }

    func testOnUpdateCalledAfterStart() {
        let poller = StatsPoller(config: fastConfig)
        let expectation = expectation(description: "onUpdate fired")
        expectation.assertForOverFulfill = false

        poller.onUpdate = { _ in expectation.fulfill() }
        poller.start()
        defer { poller.stop() }

        waitForExpectations(timeout: 3)
    }

    func testOnUpdateReceivesValidSnapshot() {
        let poller = StatsPoller(config: fastConfig)
        let expectation = expectation(description: "valid snapshot received")

        poller.onUpdate = { snapshot in
            XCTAssertGreaterThanOrEqual(snapshot.cpu, 0.0)
            XCTAssertLessThanOrEqual(snapshot.cpu, 100.0)
            XCTAssertGreaterThan(snapshot.memory.totalBytes, 0)
            XCTAssertGreaterThanOrEqual(snapshot.memory.usedBytes, 0)
            expectation.fulfill()
        }
        poller.start()
        defer { poller.stop() }

        waitForExpectations(timeout: 3)
    }

    func testStopPreventsOnUpdateFromFiring() {
        let poller = StatsPoller(config: fastConfig)
        // Let it fire at least once, then stop and verify it goes quiet
        let firstFire = expectation(description: "first update")
        firstFire.assertForOverFulfill = false

        poller.onUpdate = { _ in firstFire.fulfill() }
        poller.start()
        waitForExpectations(timeout: 3)

        poller.stop()

        var firedAfterStop = false
        poller.onUpdate = { _ in firedAfterStop = true }

        // Wait two tick intervals — no update should arrive
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(firedAfterStop)
    }

    func testStopBeforeStartDoesNotCrash() {
        let poller = StatsPoller(config: fastConfig)
        poller.stop() // should be a no-op
    }

    func testStartIsIdempotent() {
        let poller = StatsPoller(config: fastConfig)
        let expectation = expectation(description: "update fires after double start")
        expectation.assertForOverFulfill = false

        poller.onUpdate = { _ in expectation.fulfill() }
        poller.start()
        poller.start() // second start should cancel the first and restart cleanly
        defer { poller.stop() }

        waitForExpectations(timeout: 3)
    }

    func testRestartFiresAfterStopAndStart() {
        let poller = StatsPoller(config: fastConfig)

        // First run
        let first = expectation(description: "first run update")
        first.assertForOverFulfill = false
        poller.onUpdate = { _ in first.fulfill() }
        poller.start()
        waitForExpectations(timeout: 3)

        poller.stop()

        // Second run — simulates wake-from-sleep restart
        let second = expectation(description: "second run update")
        second.assertForOverFulfill = false
        poller.onUpdate = { _ in second.fulfill() }
        poller.start()
        defer { poller.stop() }

        waitForExpectations(timeout: 3)
    }
}
