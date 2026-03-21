import Darwin
import Foundation

struct MemoryStats {
    let totalBytes: UInt64
    let usedBytes: UInt64

    var percentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return (Double(usedBytes) / Double(totalBytes)) * 100.0
    }

    var usedGB: Double { Double(usedBytes) / 1_073_741_824 }
    var totalGB: Double { Double(totalBytes) / 1_073_741_824 }
}

final class MemoryMonitor {
    private let hostPort = mach_host_self()
    private let totalBytes: UInt64

    init() {
        totalBytes = ProcessInfo.processInfo.physicalMemory
    }

    func currentUsage() -> MemoryStats {
        let pageSize = vm_kernel_page_size
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryStats(totalBytes: totalBytes, usedBytes: 0)
        }

        let active = UInt64(stats.active_count) * UInt64(pageSize)
        let wired = UInt64(stats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(stats.compressor_page_count) * UInt64(pageSize)
        let used = active + wired + compressed

        return MemoryStats(totalBytes: totalBytes, usedBytes: used)
    }
}
