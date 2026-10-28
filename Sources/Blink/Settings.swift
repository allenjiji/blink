import Foundation

struct Settings {
    private static let intervalKey = "intervalMinutes"
    private static let breakKey = "breakSeconds"

    static let defaultIntervalMinutes = 20
    static let defaultBreakSeconds = 20

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var intervalMinutes: Int {
        get {
            let value = defaults.integer(forKey: Self.intervalKey)
            return value > 0 ? value : Self.defaultIntervalMinutes
        }
        nonmutating set { defaults.set(newValue, forKey: Self.intervalKey) }
    }

    var breakSeconds: Int {
        get {
            let value = defaults.integer(forKey: Self.breakKey)
            return value > 0 ? value : Self.defaultBreakSeconds
        }
        nonmutating set { defaults.set(newValue, forKey: Self.breakKey) }
    }
}
