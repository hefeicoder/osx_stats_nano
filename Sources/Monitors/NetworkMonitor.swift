import CoreFoundation
import Darwin

struct NetworkThroughput {
    let bytesInPerSec: UInt64
    let bytesOutPerSec: UInt64

    var formattedIn: String { Self.format(bytesPerSec: bytesInPerSec) }
    var formattedOut: String { Self.format(bytesPerSec: bytesOutPerSec) }

    static func format(bytesPerSec: UInt64) -> String {
        let kb = Double(bytesPerSec) / 1024
        if kb < 1024 {
            return String(format: "%.0f KB/s", kb)
        }
        let mb = kb / 1024
        if mb < 1024 {
            return String(format: "%.1f MB/s", mb)
        }
        return String(format: "%.1f GB/s", mb / 1024)
    }
}

final class NetworkMonitor {
    private var previousBytes: (inBytes: UInt64, outBytes: UInt64)?
    private var previousTime: CFAbsoluteTime?

    func reset() {
        previousBytes = nil
        previousTime = nil
    }

    func currentThroughput() -> NetworkThroughput {
        let current = readTotalBytes()
        let now = CFAbsoluteTimeGetCurrent()

        defer {
            previousBytes = current
            previousTime = now
        }

        guard let prev = previousBytes, let prevTime = previousTime else {
            return NetworkThroughput(bytesInPerSec: 0, bytesOutPerSec: 0)
        }

        let elapsed = now - prevTime
        guard elapsed > 0 else {
            return NetworkThroughput(bytesInPerSec: 0, bytesOutPerSec: 0)
        }

        let inDelta = current.inBytes &- prev.inBytes
        let outDelta = current.outBytes &- prev.outBytes

        return NetworkThroughput(
            bytesInPerSec: UInt64(Double(inDelta) / elapsed),
            bytesOutPerSec: UInt64(Double(outDelta) / elapsed)
        )
    }

    private func readTotalBytes() -> (inBytes: UInt64, outBytes: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ptr = ifaddr

        while let current = ptr {
            defer { ptr = current.pointee.ifa_next }

            guard current.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) else { continue }

            // Skip loopback — strcmp avoids Swift String allocation
            guard strcmp(current.pointee.ifa_name, "lo0") != 0 else { continue }

            if let data = current.pointee.ifa_data {
                let ifData = data.assumingMemoryBound(to: if_data.self)
                totalIn += UInt64(ifData.pointee.ifi_ibytes)
                totalOut += UInt64(ifData.pointee.ifi_obytes)
            }
        }

        return (totalIn, totalOut)
    }
}
