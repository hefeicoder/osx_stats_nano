import Foundation
import IOKit

final class GPUMonitor {
    /// Returns GPU utilization percentage (0.0–100.0), or -1 if unavailable.
    func currentUsage() -> Double {
        let matching = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return -1
        }
        defer { IOObjectRelease(iterator) }

        var maxUtilization: Double = -1

        var entry: io_object_t = IOIteratorNext(iterator)
        while entry != 0 {
            defer {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }

            // Fetch only PerformanceStatistics — avoids copying the entire property tree
            guard let perfStats = IORegistryEntrySearchCFProperty(
                entry, kIOServicePlane,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault, 0
            ) as? [String: Any] else {
                continue
            }

            // Apple Silicon uses "GPU Activity(%)" or "Device Utilization %"
            if let utilization = perfStats["Device Utilization %"] as? NSNumber {
                maxUtilization = max(maxUtilization, utilization.doubleValue)
            } else if let utilization = perfStats["GPU Activity(%)"] as? NSNumber {
                maxUtilization = max(maxUtilization, utilization.doubleValue)
            }
        }

        return maxUtilization
    }
}
