import XCTest
@testable import OSXStatsNano

final class StatsSnapshotTests: XCTestCase {

    // MARK: - isDifferent: CPU

    func testIsDifferentCPUBelowThreshold() {
        let a = snapshot(cpu: 50.0)
        let b = snapshot(cpu: 50.5)
        XCTAssertFalse(a.isDifferent(from: b))
    }

    func testIsDifferentCPUAtThreshold() {
        let a = snapshot(cpu: 50.0)
        let b = snapshot(cpu: 51.0)
        XCTAssertTrue(a.isDifferent(from: b))
    }

    // MARK: - isDifferent: memory

    func testIsDifferentMemoryBelowThreshold() {
        let a = snapshot(memUsed: 4_000_000_000, memTotal: 8_000_000_000)
        let b = snapshot(memUsed: 4_000_100_000, memTotal: 8_000_000_000)
        XCTAssertFalse(a.isDifferent(from: b))
    }

    // MARK: - isDifferent: network — regression for UInt64 overflow (PR #3)

    func testIsDifferentNetworkBelowThreshold() {
        let a = snapshot(bytesIn: 1000, bytesOut: 1000)
        let b = snapshot(bytesIn: 1500, bytesOut: 1500)
        XCTAssertFalse(a.isDifferent(from: b))
    }

    func testIsDifferentNetworkAboveThreshold() {
        let a = snapshot(bytesIn: 0, bytesOut: 0)
        let b = snapshot(bytesIn: 2048, bytesOut: 0)
        XCTAssertTrue(a.isDifferent(from: b))
    }

    func testIsDifferentNetworkNoOverflowWhenCurrentLessThanPrevious() {
        // Regression: before PR #3, using .distance(to:) on UInt64 would trap when
        // the new value was less than the previous (e.g. counter reset after sleep).
        // Safe max/min subtraction must never overflow.
        let large = snapshot(bytesIn: UInt64.max - 1, bytesOut: UInt64.max - 1)
        let small = snapshot(bytesIn: 0, bytesOut: 0)
        // Should not crash or overflow — just returns true (values differ by > 1 KB)
        XCTAssertTrue(large.isDifferent(from: small))
        XCTAssertTrue(small.isDifferent(from: large))
    }

    func testIsDifferentNetworkMaxUInt64ValuesNoOverflow() {
        let a = snapshot(bytesIn: UInt64.max, bytesOut: UInt64.max)
        let b = snapshot(bytesIn: UInt64.max, bytesOut: UInt64.max)
        XCTAssertFalse(a.isDifferent(from: b))
    }

    // MARK: - Helpers

    private func snapshot(
        cpu: Double = 0,
        memUsed: UInt64 = 0,
        memTotal: UInt64 = 8_000_000_000,
        gpu: Double = -1,
        bytesIn: UInt64 = 0,
        bytesOut: UInt64 = 0
    ) -> StatsSnapshot {
        StatsSnapshot(
            cpu: cpu,
            memory: MemoryStats(totalBytes: memTotal, usedBytes: memUsed),
            gpu: gpu,
            network: NetworkThroughput(bytesInPerSec: bytesIn, bytesOutPerSec: bytesOut)
        )
    }
}
