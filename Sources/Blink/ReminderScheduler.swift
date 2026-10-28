import Foundation

final class ReminderScheduler {
    private static let meetingPollInterval: TimeInterval = 30

    private var timer: Timer?
    private var meetingPollTimer: Timer?
    private let settings: Settings
    private let onFire: () -> Void

    init(settings: Settings, onFire: @escaping () -> Void) {
        self.settings = settings
        self.onFire = onFire
    }

    static func fireInterval(forMinutes minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }

    var isRunning: Bool { timer != nil }
    var nextFireDate: Date? { timer?.fireDate }

    func start() {
        stop()
        let interval = Self.fireInterval(forMinutes: settings.intervalMinutes)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.fireOrDeferForMeeting()
        }
        // .common mode so it keeps firing while the status-bar menu is open or a modal alert is up.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        meetingPollTimer?.invalidate()
        meetingPollTimer = nil
    }

    /// If a meeting is in progress, hold the reminder and poll until it ends, then fire right away.
    private func fireOrDeferForMeeting() {
        guard MeetingDetector.isInMeeting() else {
            onFire()
            return
        }
        guard meetingPollTimer == nil else { return }
        let poll = Timer(timeInterval: Self.meetingPollInterval, repeats: true) { [weak self] pollTimer in
            guard let self, !MeetingDetector.isInMeeting() else { return }
            pollTimer.invalidate()
            self.meetingPollTimer = nil
            self.onFire()
        }
        RunLoop.main.add(poll, forMode: .common)
        meetingPollTimer = poll
    }

    /// Call after settings change so the new interval takes effect.
    func restartIfRunning() {
        guard isRunning else { return }
        start()
    }
}
