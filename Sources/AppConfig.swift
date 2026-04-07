import Foundation
import AppKit

/// App configuration loaded from ~/.config/osx-stats-nano/config.yaml
/// Hand-rolled flat YAML parser — no external dependency.
struct AppConfig {
    var cpuInterval: TimeInterval = 2.0
    var memoryInterval: TimeInterval = 2.0
    var gpuInterval: TimeInterval = 6.0
    var networkInterval: TimeInterval = 2.0
    var showCPU: Bool = true
    var showMemory: Bool = true
    var showGPU: Bool = true
    var showNetwork: Bool = true

    // Widget style: circle | bar | vbar
    var cpuStyle: String = "circle"
    var memoryStyle: String = "circle"
    var gpuStyle: String = "circle"

    // Widget colors: green | orange | blue | red | purple | yellow | pink | teal
    var cpuColor: String = "green"
    var memoryColor: String = "orange"
    var gpuColor: String = "purple"

    // SF Symbol names — see developer.apple.com/sf-symbols
    var cpuIcon: String = "cpu"
    var memoryIcon: String = "memorychip"
    var gpuIcon: String = "display"
    var networkIcon: String = "network"

    static func color(for name: String) -> NSColor {
        switch name {
        case "orange": return .systemOrange
        case "blue":   return .systemBlue
        case "red":    return .systemRed
        case "purple": return .systemPurple
        case "yellow": return .systemYellow
        case "pink":   return .systemPink
        case "teal":   return .systemTeal
        case "auto":   return .labelColor
        default:       return .systemGreen
        }
    }

    static let configDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/osx-stats-nano")
    static let configPath = configDir.appendingPathComponent("config.yaml")

    /// Load config from disk, falling back to defaults for missing keys.
    static func load() -> AppConfig {
        var config = AppConfig()

        guard let data = try? Data(contentsOf: configPath),
              let text = String(data: data, encoding: .utf8) else {
            return config
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Strip inline comments and skip empty/comment lines
            let stripped = trimmed.hasPrefix("#") ? "" : String(trimmed.prefix(while: { $0 != "#" }))
                .trimmingCharacters(in: .whitespaces)
            if stripped.isEmpty { continue }

            guard let colonIndex = stripped.firstIndex(of: ":") else { continue }
            let key = stripped[stripped.startIndex..<colonIndex]
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            // Preserve case for icon values (SF Symbol names are case-sensitive)
            let rawValue = stripped[stripped.index(after: colonIndex)...]
                .trimmingCharacters(in: .whitespaces)

            switch key {
            case "cpu_interval":
                if let v = Double(rawValue), v >= 0.5 { config.cpuInterval = v }
            case "memory_interval":
                if let v = Double(rawValue), v >= 0.5 { config.memoryInterval = v }
            case "gpu_interval":
                if let v = Double(rawValue), v >= 1.0 { config.gpuInterval = v }
            case "network_interval":
                if let v = Double(rawValue), v >= 0.5 { config.networkInterval = v }
            case "show_cpu":
                config.showCPU = rawValue.lowercased() == "true"
            case "show_memory":
                config.showMemory = rawValue.lowercased() == "true"
            case "show_gpu":
                config.showGPU = rawValue.lowercased() == "true"
            case "show_network":
                config.showNetwork = rawValue.lowercased() == "true"
            case "cpu_icon":
                if !rawValue.isEmpty { config.cpuIcon = rawValue }
            case "memory_icon":
                if !rawValue.isEmpty { config.memoryIcon = rawValue }
            case "gpu_icon":
                if !rawValue.isEmpty { config.gpuIcon = rawValue }
            case "network_icon":
                if !rawValue.isEmpty { config.networkIcon = rawValue }
            case "cpu_style":
                if !rawValue.isEmpty { config.cpuStyle = rawValue.lowercased() }
            case "memory_style":
                if !rawValue.isEmpty { config.memoryStyle = rawValue.lowercased() }
            case "gpu_style":
                if !rawValue.isEmpty { config.gpuStyle = rawValue.lowercased() }
            case "cpu_color":
                if !rawValue.isEmpty { config.cpuColor = rawValue.lowercased() }
            case "memory_color":
                if !rawValue.isEmpty { config.memoryColor = rawValue.lowercased() }
            case "gpu_color":
                if !rawValue.isEmpty { config.gpuColor = rawValue.lowercased() }
            default:
                break
            }
        }

        return config
    }

    /// Write default config file if none exists. Creates ~/.config/osx-stats-nano/ if needed.
    static func createDefaultIfNeeded() {
        let fm = FileManager.default
        if fm.fileExists(atPath: configPath.path) { return }

        try? fm.createDirectory(at: configDir, withIntermediateDirectories: true)

        let defaultYAML = """
        # ─────────────────────────────────────────
        # OSX Stats Nano — Configuration
        # ─────────────────────────────────────────
        # Edit this file and restart the app to apply changes.

        # ── Polling intervals (seconds) ──────────
        # Minimum: 0.5s (gpu minimum: 1.0s)
        # GPU uses IOKit which is heavier — 6s recommended.

        cpu_interval: 2.0      # default: 2.0
        memory_interval: 2.0   # default: 2.0
        gpu_interval: 6.0      # default: 6.0
        network_interval: 2.0  # default: 2.0

        # ── Visibility ───────────────────────────
        # Options: true | false

        show_cpu: true         # default: true
        show_memory: true      # default: true
        show_gpu: true         # default: true
        show_network: true     # default: true

        # ── Widget style ─────────────────────────
        # Options: circle | bar | vbar

        cpu_style: circle      # default: circle
        memory_style: circle   # default: circle
        gpu_style: circle      # default: circle

        # ── Widget color ─────────────────────────
        # Options: auto | green | orange | blue | red | purple | yellow | pink | teal

        cpu_color: green       # default: green
        memory_color: orange   # default: orange
        gpu_color: purple      # default: purple

        # ── Icons (SF Symbol names) ───────────────
        # Browse symbols at: developer.apple.com/sf-symbols
        # cpu:     cpu | cpu.fill | bolt | bolt.fill
        # memory:  memorychip | memorychip.fill
        # gpu:     display | display.fill | rectangle.3.group
        # network: network | wifi | antenna.radiowaves.left.and.right

        cpu_icon: cpu
        memory_icon: memorychip
        gpu_icon: display
        network_icon: network
        """

        try? defaultYAML.write(to: configPath, atomically: true, encoding: .utf8)
    }
}
