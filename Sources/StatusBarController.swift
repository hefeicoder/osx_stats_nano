import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let barView: StatusBarView

    /// The last snapshot used for display. Always set from main thread.
    private(set) var snapshot: StatsSnapshot = .empty

    init(config: AppConfig = AppConfig()) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        barView = StatusBarView(config: config)
        statusItem.button?.addSubview(barView)
        barView.frame = statusItem.button?.bounds ?? .zero
        barView.autoresizingMask = [.width, .height]
    }

    /// Update display from snapshot. Must be called on main thread.
    func display(_ snapshot: StatsSnapshot) {
        self.snapshot = snapshot
        barView.snapshot = snapshot
        barView.rebuildWidgets()
        statusItem.length = barView.cachedWidth
        barView.frame.size.width = barView.cachedWidth
        barView.needsDisplay = true
    }

    func setMenu(_ menu: NSMenu) {
        statusItem.menu = menu
    }
}

/// Custom NSView that draws widgets directly — no NSImage allocation.
final class StatusBarView: NSView {
    var snapshot: StatsSnapshot = .empty
    private let appConfig: AppConfig

    private let spacing: CGFloat = 4

    // SF Symbol icons — cached once at init, never reallocated
    private let cpuIcon: NSImage?
    private let memIcon: NSImage?
    private let gpuIcon: NSImage?

    // Cached per-update to avoid recomputing in draw()
    private(set) var cachedWidth: CGFloat = 0
    private var cachedWidgets: [StatusBarWidget] = []

    init(config: AppConfig = AppConfig()) {
        self.appConfig = config
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        cpuIcon = NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig)
        memIcon = NSImage(systemSymbolName: "memorychip", accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig)
        gpuIcon = NSImage(systemSymbolName: "gpu", accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig)
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Rebuild widget list and cache width. Called once per snapshot update, NOT per draw.
    func rebuildWidgets() {
        var widgets: [StatusBarWidget] = []
        if appConfig.showCPU {
            widgets.append(PercentageBarWidget(icon: cpuIcon, percentage: snapshot.cpu, tintColor: .systemGreen))
        }
        if appConfig.showMemory {
            widgets.append(PercentageCircleWidget(icon: memIcon, percentage: snapshot.memory.percentage, tintColor: .systemOrange))
        }
        if appConfig.showGPU && snapshot.gpu >= 0 {
            widgets.append(PercentageCircleWidget(icon: gpuIcon, percentage: snapshot.gpu, tintColor: .systemPurple))
        }
        if appConfig.showNetwork {
            widgets.append(TextWidget("↓\(snapshot.network.formattedIn) ↑\(snapshot.network.formattedOut)"))
        }
        cachedWidgets = widgets
        cachedWidth = widgets.isEmpty ? 0 : widgets.reduce(0) { $0 + $1.widthForHeight(22) + spacing } - spacing
    }

    override func draw(_ dirtyRect: NSRect) {
        var x: CGFloat = 0
        for widget in cachedWidgets {
            widget.draw(at: NSPoint(x: x, y: 0), height: bounds.height)
            x += widget.widthForHeight(bounds.height) + spacing
        }
    }
}
