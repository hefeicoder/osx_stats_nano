import XCTest
@testable import OSXStatsNano

final class MemoryMonitorTests: XCTestCase {
    func testMemoryUsageReturnsValidValues() {
        let monitor = MemoryMonitor()
        let stats = monitor.currentUsage()
        XCTAssertGreaterThan(stats.totalBytes, 0)
        XCTAssertGreaterThan(stats.usedBytes, 0)
        XCTAssertLessThanOrEqual(stats.usedBytes, stats.totalBytes)
    }

    func testMemoryPercentageIsValid() {
        let monitor = MemoryMonitor()
        let stats = monitor.currentUsage()
        let pct = stats.percentage
        XCTAssertGreaterThan(pct, 0.0)
        XCTAssertLessThanOrEqual(pct, 100.0)
    }
}
