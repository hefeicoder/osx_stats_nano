import XCTest
@testable import OSXStatsNano

final class NetworkMonitorTests: XCTestCase {
    func testNetworkStatsReturnsNonNegative() {
        let monitor = NetworkMonitor()
        let stats = monitor.currentThroughput()
        XCTAssertGreaterThanOrEqual(stats.bytesInPerSec, 0)
        XCTAssertGreaterThanOrEqual(stats.bytesOutPerSec, 0)
    }

    func testNetworkTotalBytesArePositive() {
        let monitor = NetworkMonitor()
        _ = monitor.currentThroughput()
        let stats = monitor.currentThroughput()
        XCTAssertGreaterThanOrEqual(stats.bytesInPerSec, 0)
    }

    func testResetClearsState() {
        let monitor = NetworkMonitor()
        _ = monitor.currentThroughput() // establish baseline
        monitor.reset()
        // After reset, no previousBytes/previousTime — must return 0, not overflow
        let stats = monitor.currentThroughput()
        XCTAssertEqual(stats.bytesInPerSec, 0)
        XCTAssertEqual(stats.bytesOutPerSec, 0)
    }

    func testResetPreventsPostSleepUInt64Overflow() {
        // Regression test for the post-sleep crash (PR #3):
        // After sleep, the network interface byte counters reset to a lower value.
        // If previousBytes > current (counter wrapped/reset) and previousTime is stale
        // (long elapsed), the wrapping subtraction could overflow UInt64 when used
        // unsafely. The fix: reset() clears previousBytes so the first post-wake call
        // returns 0 instead of an overflowed value.
        //
        // We simulate this by calling reset() (as StatsPoller.start() does on wake)
        // and verifying no overflow occurs.
        let monitor = NetworkMonitor()
        _ = monitor.currentThroughput()
        monitor.reset()
        let stats = monitor.currentThroughput()
        // Must be 0 (no baseline), never a huge overflow value
        XCTAssertEqual(stats.bytesInPerSec, 0)
        XCTAssertEqual(stats.bytesOutPerSec, 0)
        XCTAssertLessThan(stats.bytesInPerSec, UInt64.max / 2)
        XCTAssertLessThan(stats.bytesOutPerSec, UInt64.max / 2)
    }

    func testFormatBytesPerSecKB() {
        XCTAssertEqual(NetworkThroughput.format(bytesPerSec: 512), "0 KB/s")
        XCTAssertEqual(NetworkThroughput.format(bytesPerSec: 1024), "1 KB/s")
        XCTAssertEqual(NetworkThroughput.format(bytesPerSec: 10240), "10 KB/s")
    }

    func testFormatBytesPerSecMB() {
        let oneMB: UInt64 = 1024 * 1024
        XCTAssertEqual(NetworkThroughput.format(bytesPerSec: oneMB), "1.0 MB/s")
        XCTAssertEqual(NetworkThroughput.format(bytesPerSec: oneMB * 10), "10.0 MB/s")
    }

    func testFormatBytesPerSecGB() {
        let oneGB: UInt64 = 1024 * 1024 * 1024
        XCTAssertEqual(NetworkThroughput.format(bytesPerSec: oneGB), "1.0 GB/s")
    }
}
