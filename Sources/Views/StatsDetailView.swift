import AppKit
import IOKit

/// Builds and live-updates menu items showing detailed stats with SF Symbol icons.
final class StatsMenuBuilder {
    private var cpuItem: NSMenuItem?
    private var memoryItem: NSMenuItem?
    private var gpuItem: NSMenuItem?
    private var downItem: NSMenuItem?
    private var upItem: NSMenuItem?

    private let config: AppConfig
    private let cpuLabel: String   // e.g. "CPU (10)"
    private let gpuLabel: String   // e.g. "GPU (1)"

    init(config: AppConfig) {
        self.config = config

        let coreCount = ProcessInfo.processInfo.processorCount
        cpuLabel = "CPU (\(coreCount))"

        let gpuCount = StatsMenuBuilder.gpuCount()
        gpuLabel = gpuCount > 0 ? "GPU (\(gpuCount))" : "GPU"
    }

    func buildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let headerItem = NSMenuItem(title: "OSX Stats Nano", action: nil, keyEquivalent: "")
        headerItem.isEnabled = true
        headerItem.attributedTitle = NSAttributedString(
            string: "OSX Stats Nano",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor,
            ]
        )
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        if config.showCPU {
            cpuItem = makeRow(icon: config.cpuIcon, label: cpuLabel, value: "—")
            menu.addItem(cpuItem!)
        }
        if config.showMemory {
            memoryItem = makeRow(icon: config.memoryIcon, label: "Memory", value: "—")
            menu.addItem(memoryItem!)
        }
        if config.showGPU {
            gpuItem = makeRow(icon: config.gpuIcon, label: gpuLabel, value: "—")
            menu.addItem(gpuItem!)
        }
        if config.showNetwork {
            menu.addItem(NSMenuItem.separator())
            downItem = makeRow(icon: config.networkIcon, label: "Down", value: "—")
            menu.addItem(downItem!)
            upItem = makeRow(icon: config.networkIcon, label: "Up", value: "—")
            menu.addItem(upItem!)
        }

        menu.addItem(NSMenuItem.separator())
    }

    func update(snapshot: StatsSnapshot) {
        updateItem(cpuItem, label: cpuLabel, value: String(format: "%.1f%%", snapshot.cpu))
        updateItem(memoryItem, label: "Memory",
                   value: String(format: "%.1f / %.1f GB (%.0f%%)",
                                 snapshot.memory.usedGB, snapshot.memory.totalGB, snapshot.memory.percentage))
        updateItem(gpuItem, label: gpuLabel,
                   value: snapshot.gpu >= 0 ? String(format: "%.1f%%", snapshot.gpu) : "N/A")
        updateItem(downItem, label: "Down", value: snapshot.network.formattedIn)
        updateItem(upItem, label: "Up", value: snapshot.network.formattedOut)
    }

    private func makeRow(icon symbolName: String, label: String, value: String) -> NSMenuItem {
        let item = NSMenuItem(title: label, action: nil, keyEquivalent: "")
        item.isEnabled = true

        if let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: label) {
            let symConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            item.image = img.withSymbolConfiguration(symConfig)
        }

        updateItem(item, label: label, value: value)
        return item
    }

    private func updateItem(_ item: NSMenuItem?, label: String, value: String) {
        guard let item else { return }
        let attrStr = NSMutableAttributedString()
        attrStr.append(NSAttributedString(
            string: "\(label)    ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.labelColor,
            ]
        ))
        attrStr.append(NSAttributedString(
            string: value,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor.labelColor,
            ]
        ))
        item.attributedTitle = attrStr
    }

    // Returns GPU core count from IOKit registry (Apple Silicon: e.g. 32 for M1 Max).
    // Falls back to 0 if unavailable.
    private static func gpuCount() -> Int {
        let matching = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var entry: io_object_t = IOIteratorNext(iterator)
        while entry != 0 {
            defer {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }
            // Search entry and its parents for "gpu-core-count" (Apple Silicon)
            if let n = IORegistryEntrySearchCFProperty(
                entry, kIOServicePlane,
                "gpu-core-count" as CFString,
                kCFAllocatorDefault,
                IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
            ) as? NSNumber {
                return n.intValue
            }
        }
        return 0
    }
}
