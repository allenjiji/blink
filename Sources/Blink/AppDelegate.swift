import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings()
    private let overlay = BreakOverlayController()
    private var scheduler: ReminderScheduler!
    private var statusItem: NSStatusItem!

    private var nextReminderItem: NSMenuItem!
    private var startPauseItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        scheduler = ReminderScheduler(settings: settings) { [weak self] in
            guard let self else { return }
            self.overlay.show(seconds: self.settings.breakSeconds)
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Blink")
            button.image?.isTemplate = true
        }
        statusItem.menu = buildMenu()

        scheduler.start()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        nextReminderItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        nextReminderItem.isEnabled = false
        menu.addItem(nextReminderItem)
        menu.addItem(.separator())

        startPauseItem = NSMenuItem(title: "Pause", action: #selector(toggleRunning), keyEquivalent: "")
        startPauseItem.target = self
        menu.addItem(startPauseItem)

        let preferencesItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: "")
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(.separator())

        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Blink", action: #selector(NSApplication.terminate), keyEquivalent: "q")
        menu.addItem(quitItem)

        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard scheduler.isRunning, let fireDate = scheduler.nextFireDate else {
            nextReminderItem.title = "Reminders paused"
            return
        }
        let remaining = max(0, Int(fireDate.timeIntervalSinceNow))
        nextReminderItem.title = String(format: "Next reminder in %d:%02d", remaining / 60, remaining % 60)
    }

    @objc private func toggleRunning() {
        if scheduler.isRunning {
            scheduler.stop()
            startPauseItem.title = "Resume"
        } else {
            scheduler.start()
            startPauseItem.title = "Pause"
        }
    }

    @objc private func openPreferences() {
        let alert = NSAlert()
        alert.messageText = "Blink Preferences"
        alert.informativeText = "How often to remind you, and how long each break lasts."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 54))

        let intervalLabel = NSTextField(labelWithString: "Remind every (minutes):")
        intervalLabel.frame = NSRect(x: 0, y: 30, width: 170, height: 20)
        let intervalField = NSTextField(frame: NSRect(x: 175, y: 28, width: 60, height: 22))
        intervalField.integerValue = settings.intervalMinutes

        let breakLabel = NSTextField(labelWithString: "Look away for (seconds):")
        breakLabel.frame = NSRect(x: 0, y: 2, width: 170, height: 20)
        let breakField = NSTextField(frame: NSRect(x: 175, y: 0, width: 60, height: 22))
        breakField.integerValue = settings.breakSeconds

        accessory.addSubview(intervalLabel)
        accessory.addSubview(intervalField)
        accessory.addSubview(breakLabel)
        accessory.addSubview(breakField)
        alert.accessoryView = accessory

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let newInterval = intervalField.integerValue
        let newBreak = breakField.integerValue
        if newInterval > 0 { settings.intervalMinutes = newInterval }
        if newBreak > 0 { settings.breakSeconds = newBreak }
        scheduler.restartIfRunning()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                launchAtLoginItem.state = .off
            } else {
                try SMAppService.mainApp.register()
                launchAtLoginItem.state = .on
                if SMAppService.mainApp.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = "\(error.localizedDescription)\n\nThis only works when running the packaged Blink.app, not via `swift run`."
            alert.runModal()
        }
    }
}
