import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusBarController: StatusBarController!
    private var poller: StatsPoller!
    private var menu: NSMenu!

    private var config = AppConfig()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppConfig.createDefaultIfNeeded()
        config = AppConfig.load()

        statusBarController = StatusBarController(config: config)

        // Create menu shell once — contents built lazily in menuWillOpen
        menu = NSMenu()
        menu.delegate = self
        statusBarController.setMenu(menu)

        poller = StatsPoller(config: config)
        poller.onUpdate = { [weak self] snapshot in
            // Already on main thread (dispatched by StatsPoller)
            self?.statusBarController.display(snapshot)
            // Menu NOT rebuilt here — only on click via menuWillOpen
        }
        poller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        poller.stop()
    }

    // MARK: - NSMenuDelegate — lazy menu building (only on user click)

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let snapshot = statusBarController.snapshot

        // Pure AppKit view — no SwiftUI, no NSHostingView
        let detailItem = NSMenuItem()
        let detailView = StatsDetailView(snapshot: snapshot)
        detailItem.view = detailView
        menu.addItem(detailItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
