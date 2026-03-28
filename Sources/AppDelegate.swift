import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusBarController: StatusBarController!
    private var poller: StatsPoller!
    private var menu: NSMenu!
    private var menuBuilder: StatsMenuBuilder!
    private var menuIsOpen = false

    private var config = AppConfig()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppConfig.createDefaultIfNeeded()
        config = AppConfig.load()

        statusBarController = StatusBarController(config: config)

        menuBuilder = StatsMenuBuilder(config: config)
        menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        // Build menu structure once (items are reused, values updated live)
        menuBuilder.buildMenu(menu)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusBarController.setMenu(menu)

        poller = StatsPoller(config: config)
        poller.onUpdate = { [weak self] snapshot in
            guard let self else { return }
            self.statusBarController.display(snapshot)
            // Update menu item values live while menu is open
            if self.menuIsOpen {
                self.menuBuilder.update(snapshot: snapshot)
            }
        }
        poller.start()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        poller.stop()
    }

    @objc private func systemDidWake() {
        // NSStatusItem can become invalid after long sleep — recreate it
        statusBarController = StatusBarController(config: config)
        statusBarController.setMenu(menu)
        // Restart poller to reset elapsed timers and get fresh readings immediately
        poller.stop()
        poller.start()
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menuIsOpen = true
        // Refresh values immediately on open
        menuBuilder.update(snapshot: statusBarController.snapshot)
    }

    func menuDidClose(_ menu: NSMenu) {
        menuIsOpen = false
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
