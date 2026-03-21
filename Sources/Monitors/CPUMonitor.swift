import Darwin

final class CPUMonitor {
    // Cache the host port — avoids 2 Mach traps (acquire+release) per poll
    private let hostPort = mach_host_self()
    private var previousTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?

    /// Returns CPU usage as percentage (0.0–100.0).
    /// First call returns 0 (establishes baseline). Subsequent calls return delta-based usage.
    func currentUsage() -> Double {
        guard let ticks = readTicks() else { return 0.0 }

        defer { previousTicks = ticks }

        guard let prev = previousTicks else { return 0.0 }

        let userDelta = ticks.user &- prev.user
        let systemDelta = ticks.system &- prev.system
        let idleDelta = ticks.idle &- prev.idle
        let niceDelta = ticks.nice &- prev.nice
        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

        guard totalDelta > 0 else { return 0.0 }

        let active = Double(userDelta + systemDelta + niceDelta)
        return (active / Double(totalDelta)) * 100.0
    }

    private func readTicks() -> (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)? {
        var processorCount: natural_t = 0
        var processorInfo: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            hostPort,
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &infoCount
        )

        guard result == KERN_SUCCESS, let info = processorInfo else { return nil }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.size)
            )
        }

        var user: UInt64 = 0, system: UInt64 = 0, idle: UInt64 = 0, nice: UInt64 = 0

        for i in 0..<Int(processorCount) {
            let offset = Int32(i) * CPU_STATE_MAX
            user   += UInt64(info[Int(offset + CPU_STATE_USER)])
            system += UInt64(info[Int(offset + CPU_STATE_SYSTEM)])
            idle   += UInt64(info[Int(offset + CPU_STATE_IDLE)])
            nice   += UInt64(info[Int(offset + CPU_STATE_NICE)])
        }

        return (user, system, idle, nice)
    }
}
