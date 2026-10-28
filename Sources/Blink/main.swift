import AppKit
import Foundation

/// No Xcode on this machine means no XCTest/Swift Testing framework, so this
/// is a plain assert-based self-check instead of a real test target.
/// Run it with: swift run Blink --selfcheck
func runSelfCheckAndExitIfRequested() {
    guard CommandLine.arguments.contains("--selfcheck") else { return }

    let suiteName = "BlinkSelfCheck.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    let settings = Settings(defaults: defaults)

    assert(settings.intervalMinutes == Settings.defaultIntervalMinutes, "default interval should be 20")
    assert(settings.breakSeconds == Settings.defaultBreakSeconds, "default break should be 20")

    settings.intervalMinutes = 5
    settings.breakSeconds = 30
    assert(settings.intervalMinutes == 5, "interval should round-trip through UserDefaults")
    assert(settings.breakSeconds == 30, "break seconds should round-trip through UserDefaults")

    assert(ReminderScheduler.fireInterval(forMinutes: 20) == 1200, "20 minutes should be 1200 seconds")
    assert(ReminderScheduler.fireInterval(forMinutes: 1) == 60, "1 minute should be 60 seconds")

    defaults.removePersistentDomain(forName: suiteName)
    print("Self-check passed.")
    exit(0)
}

runSelfCheckAndExitIfRequested()

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
