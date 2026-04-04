import Foundation

final class StatsPoller {
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let gpuMonitor = GPUMonitor()
    private let networkMonitor = NetworkMonitor()

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.xishu.osx-stats-nano.poller", qos: .utility)

    /// Called on the main thread only when snapshot changes meaningfully.
    var onUpdate: ((StatsSnapshot) -> Void)?

    // Per-monitor intervals in seconds
    private let cpuInterval: TimeInterval
    private let memoryInterval: TimeInterval
    private let gpuInterval: TimeInterval
    private let networkInterval: TimeInterval

    // Base tick = fastest interval (GCD-style)
    private let tickInterval: TimeInterval

    // Elapsed time tracking per monitor
    private var cpuElapsed: TimeInterval = 0
    private var memoryElapsed: TimeInterval = 0
    private var gpuElapsed: TimeInterval = 0
    private var networkElapsed: TimeInterval = 0

    // Last polled values (reused when monitor is skipped this tick)
    private var lastCPU: Double = 0
    private var lastMemory: MemoryStats = MemoryStats(totalBytes: 0, usedBytes: 0)
    private var lastGPU: Double = -1
    private var lastNetwork: NetworkThroughput = NetworkThroughput(bytesInPerSec: 0, bytesOutPerSec: 0)
    private var previous: StatsSnapshot = .empty

    init(config: AppConfig = AppConfig()) {
        self.cpuInterval = config.cpuInterval
        self.memoryInterval = config.memoryInterval
        self.gpuInterval = config.gpuInterval
        self.networkInterval = config.networkInterval
        self.tickInterval = min(cpuInterval, memoryInterval, gpuInterval, networkInterval)
    }

    func start() {
        stop()
        cpuMonitor.reset()
        networkMonitor.reset()
        // Fire immediately on first tick
        cpuElapsed = cpuInterval
        memoryElapsed = memoryInterval
        gpuElapsed = gpuInterval
        networkElapsed = networkInterval

        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: tickInterval)
        t.setEventHandler { [weak self] in
            self?.poll()
        }
        timer = t
        t.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func poll() {
        cpuElapsed += tickInterval
        memoryElapsed += tickInterval
        gpuElapsed += tickInterval
        networkElapsed += tickInterval

        if cpuElapsed >= cpuInterval {
            lastCPU = cpuMonitor.currentUsage()
            cpuElapsed = 0
        }
        if memoryElapsed >= memoryInterval {
            lastMemory = memoryMonitor.currentUsage()
            memoryElapsed = 0
        }
        if gpuElapsed >= gpuInterval {
            lastGPU = gpuMonitor.currentUsage()
            gpuElapsed = 0
        }
        if networkElapsed >= networkInterval {
            lastNetwork = networkMonitor.currentThroughput()
            networkElapsed = 0
        }

        let snapshot = StatsSnapshot(
            cpu: lastCPU, memory: lastMemory, gpu: lastGPU, network: lastNetwork
        )

        // Skip dispatch if nothing changed meaningfully
        guard snapshot.isDifferent(from: previous) else { return }
        previous = snapshot

        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?(snapshot)
        }
    }
}
