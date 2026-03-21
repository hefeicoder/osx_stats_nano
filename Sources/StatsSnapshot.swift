import Foundation

/// Immutable snapshot of all system metrics at a point in time.
struct StatsSnapshot {
    let cpu: Double              // 0–100
    let memory: MemoryStats
    let gpu: Double              // 0–100, or -1 if unavailable
    let network: NetworkThroughput

    static let empty = StatsSnapshot(
        cpu: 0,
        memory: MemoryStats(totalBytes: 0, usedBytes: 0),
        gpu: -1,
        network: NetworkThroughput(bytesInPerSec: 0, bytesOutPerSec: 0)
    )

    /// Returns true if any metric changed enough to warrant a redraw.
    func isDifferent(from other: StatsSnapshot) -> Bool {
        if abs(cpu - other.cpu) >= 1.0 { return true }
        if abs(memory.percentage - other.memory.percentage) >= 1.0 { return true }
        if abs(gpu - other.gpu) >= 1.0 { return true }
        // 1 KB/s threshold — prevents jitter from defeating idle suppression
        let inDelta = network.bytesInPerSec.distance(to: other.network.bytesInPerSec)
        let outDelta = network.bytesOutPerSec.distance(to: other.network.bytesOutPerSec)
        if abs(inDelta) > 1024 || abs(outDelta) > 1024 { return true }
        return false
    }
}
