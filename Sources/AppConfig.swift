import Foundation

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
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            guard let colonIndex = trimmed.firstIndex(of: ":") else { continue }
            let key = trimmed[trimmed.startIndex..<colonIndex]
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            let value = trimmed[trimmed.index(after: colonIndex)...]
                .trimmingCharacters(in: .whitespaces)
                .lowercased()

            switch key {
            case "cpu_interval":
                if let v = Double(value), v >= 0.5 { config.cpuInterval = v }
            case "memory_interval":
                if let v = Double(value), v >= 0.5 { config.memoryInterval = v }
            case "gpu_interval":
                if let v = Double(value), v >= 1.0 { config.gpuInterval = v }
            case "network_interval":
                if let v = Double(value), v >= 0.5 { config.networkInterval = v }
            case "show_cpu":
                config.showCPU = value == "true"
            case "show_memory":
                config.showMemory = value == "true"
            case "show_gpu":
                config.showGPU = value == "true"
            case "show_network":
                config.showNetwork = value == "true"
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
        # OSX Stats Nano Configuration
        #
        # Intervals: seconds between polls per monitor (min 0.5, gpu min 1.0)
        # GPU uses IOKit which is heavier — default 6s is recommended.
        # show_*: toggle each monitor on/off

        cpu_interval: 2.0      # default: 2s
        memory_interval: 2.0   # default: 2s
        gpu_interval: 6.0      # default: 6s (IOKit is heavier)
        network_interval: 2.0  # default: 2s

        show_cpu: true
        show_memory: true
        show_gpu: true
        show_network: true
        """

        try? defaultYAML.write(to: configPath, atomically: true, encoding: .utf8)
    }
}
