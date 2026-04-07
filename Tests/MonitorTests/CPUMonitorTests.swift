import XCTest
@testable import OSXStatsNano

final class CPUMonitorTests: XCTestCase {
    func testCPUUsageReturnsValidPercentage() {
        let monitor = CPUMonitor()
        let usage = monitor.currentUsage()
        XCTAssertGreaterThanOrEqual(usage, 0.0)
        XCTAssertLessThanOrEqual(usage, 100.0)
    }

    func testCPUUsageChangesOverTime() {
        let monitor = CPUMonitor()
        _ = monitor.currentUsage()
        var sum = 0.0
        for i in 0..<1_000_000 { sum += Double(i) }
        _ = sum
        let usage = monitor.currentUsage()
        XCTAssertFalse(usage.isNaN)
        XCTAssertGreaterThanOrEqual(usage, 0.0)
    }

    func testResetClearsPreviousTicks() {
        let monitor = CPUMonitor()
        // Establish a baseline
        _ = monitor.currentUsage()
        // Reset clears previousTicks — next call must return 0 (no baseline to diff against)
        monitor.reset()
        XCTAssertEqual(monitor.currentUsage(), 0.0)
    }

    func testResetAllowsCleanRestartAfterReset() {
        let monitor = CPUMonitor()
        _ = monitor.currentUsage()
        monitor.reset()
        _ = monitor.currentUsage() // re-establish baseline after reset
        var sum = 0.0
        for i in 0..<1_000_000 { sum += Double(i) }
        _ = sum
        let usage = monitor.currentUsage()
        XCTAssertGreaterThanOrEqual(usage, 0.0)
        XCTAssertLessThanOrEqual(usage, 100.0)
    }
}
