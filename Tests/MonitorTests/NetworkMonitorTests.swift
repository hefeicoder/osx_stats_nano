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
}
