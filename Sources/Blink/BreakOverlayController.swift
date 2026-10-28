import AppKit

/// Borderless windows can't become key by default, so Escape would never reach them.
private final class OverlayWindow: NSWindow {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // kVK_Escape; hardcoded to avoid importing Carbon for one constant
            onEscape?()
        } else {
            super.keyDown(with: event)
        }
    }
}

final class BreakOverlayController {
    private var windows: [OverlayWindow] = []
    private var countdownTimer: Timer?
    private var remainingSeconds = 0

    func show(seconds: Int) {
        guard windows.isEmpty else { return }
        remainingSeconds = seconds

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = false
            window.onEscape = { [weak self] in self?.dismiss() }

            let label = NSTextField(labelWithString: "")
            label.font = .systemFont(ofSize: 36, weight: .medium)
            label.textColor = .white
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            let content = NSView(frame: screen.frame)
            content.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: content.centerYAnchor)
            ])
            window.contentView = content
            label.identifier = NSUserInterfaceItemIdentifier("countdownLabel")

            window.orderFrontRegardless()
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        let keyWindow = windows.first { $0.screen == NSScreen.main } ?? windows.first
        keyWindow?.makeKey()
        updateLabels()
        NSSound(named: "Glass")?.play()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            dismiss()
        } else {
            updateLabels()
        }
    }

    private func updateLabels() {
        let text = "Look away from the screen\n\(remainingSeconds)"
        for window in windows {
            (window.contentView?.subviews.first as? NSTextField)?.stringValue = text
        }
    }

    private func dismiss() {
        guard !windows.isEmpty else { return }
        countdownTimer?.invalidate()
        countdownTimer = nil
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        NSSound(named: "Pop")?.play()
    }
}
