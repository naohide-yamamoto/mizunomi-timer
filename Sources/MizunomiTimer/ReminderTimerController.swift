import Foundation

enum ReminderOutcome {
    case completed
    case skipped
    case missed
}

enum TimerState: Equatable {
    case stopped
    case waiting(startAt: Date)
    case running(startedAt: Date)
    case paused(startedAt: Date)

    var startedAt: Date? {
        switch self {
        case .running(let date), .paused(let date):
            return date
        case .stopped, .waiting:
            return nil
        }
    }
}

struct SettingsFormValues {
    var autoStartTimerAtLaunch: Bool
    var startTimeMinutes: Int
    var reminderIntervalMinutes: Int
    var reminderDurationMinutes: Int
    var reminderPanelAppearance: ReminderPanelAppearance
    var launchAtLogin: Bool
}

@MainActor
final class ReminderTimerController {
    var onStateChanged: ((TimerState) -> Void)?
    var onReminderDue: ((Date) -> Void)?

    private let settingsStore: AppSettingsStore
    private(set) var state: TimerState = .stopped {
        didSet {
            onStateChanged?(state)
        }
    }

    private var startTimer: Timer?
    private var reminderTimer: Timer?
    private var consecutiveUnhadIntervals = 0

    init(settingsStore: AppSettingsStore) {
        self.settingsStore = settingsStore
    }

    var currentSettings: AppSettings {
        settingsStore.load()
    }

    var currentUnhadMinutes: Int? {
        let count = consecutiveUnhadIntervals
        guard count > 0 else { return nil }
        return count * currentSettings.reminderIntervalMinutes
    }

    func startOnLaunch() {
        let settings = currentSettings

        if settings.hasCustomStartTime {
            waitUntilConfiguredStart(settings: settings)
        } else {
            startNow()
        }
    }

    func startNow() {
        invalidateTimers()
        consecutiveUnhadIntervals = 0
        let startedAt = Date()
        state = .running(startedAt: startedAt)
        scheduleNextReminder(startedAt: startedAt, after: startedAt)
    }

    func pauseOrResume() {
        switch state {
        case .running(let startedAt):
            reminderTimer?.invalidate()
            reminderTimer = nil
            state = .paused(startedAt: startedAt)
        case .paused(let startedAt):
            state = .running(startedAt: startedAt)
            scheduleNextReminder(startedAt: startedAt, after: Date())
        case .stopped, .waiting:
            break
        }
    }

    func stop() {
        invalidateTimers()
        consecutiveUnhadIntervals = 0
        state = .stopped
    }

    func apply(settings: AppSettings, startTimeChanged: Bool) {
        settingsStore.save(settings)

        switch state {
        case .running(let startedAt) where !startTimeChanged:
            reminderTimer?.invalidate()
            state = .running(startedAt: startedAt)
            scheduleNextReminder(startedAt: startedAt, after: Date())
        case .paused(let startedAt) where !startTimeChanged:
            state = .paused(startedAt: startedAt)
        default:
            consecutiveUnhadIntervals = 0
            startAccordingTo(settings: settings)
        }
    }

    func save(settings: AppSettings) {
        settingsStore.save(settings)
    }

    func record(_ outcome: ReminderOutcome) {
        switch outcome {
        case .completed:
            consecutiveUnhadIntervals = 0
        case .skipped, .missed:
            consecutiveUnhadIntervals += 1
        }
    }

    func resetHistory() {
        consecutiveUnhadIntervals = 0
    }

    func settingsFormValues(launchAtLogin: Bool) -> SettingsFormValues {
        let settings = currentSettings
        let startTimeMinutes: Int

        switch state {
        case .running(let startedAt), .paused(let startedAt):
            startTimeMinutes = TimeFormatter.minutesSinceMidnight(from: startedAt)
        case .waiting:
            startTimeMinutes = settings.startTimeMinutes
        case .stopped:
            startTimeMinutes = settings.startTimeMinutes
        }

        return SettingsFormValues(
            autoStartTimerAtLaunch: settings.autoStartTimerAtLaunch,
            startTimeMinutes: startTimeMinutes,
            reminderIntervalMinutes: settings.reminderIntervalMinutes,
            reminderDurationMinutes: settings.reminderDurationMinutes,
            reminderPanelAppearance: settings.reminderPanelAppearance,
            launchAtLogin: launchAtLogin
        )
    }

    private func startAccordingTo(settings: AppSettings) {
        if settings.hasCustomStartTime {
            waitUntilConfiguredStart(settings: settings)
        } else {
            startNow()
        }
    }

    private func waitUntilConfiguredStart(settings: AppSettings) {
        invalidateTimers()
        let startDate = TimeFormatter.nextOccurrence(minutesSinceMidnight: settings.startTimeMinutes)
        state = .waiting(startAt: startDate)

        startTimer = Timer.scheduledTimer(withTimeInterval: max(0.1, startDate.timeIntervalSinceNow), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.beginFromConfiguredStart(startDate)
            }
        }
    }

    private func beginFromConfiguredStart(_ startDate: Date) {
        startTimer?.invalidate()
        startTimer = nil
        consecutiveUnhadIntervals = 0
        state = .running(startedAt: startDate)
        scheduleNextReminder(startedAt: startDate, after: startDate)
    }

    private func scheduleNextReminder(startedAt: Date, after referenceDate: Date) {
        reminderTimer?.invalidate()

        let nextDate = nextReminderDate(startedAt: startedAt, after: referenceDate)
        reminderTimer = Timer.scheduledTimer(withTimeInterval: max(0.1, nextDate.timeIntervalSinceNow), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fireReminder(scheduledAt: nextDate)
            }
        }
    }

    private func fireReminder(scheduledAt date: Date) {
        guard case .running(let startedAt) = state else { return }
        onReminderDue?(date)
        scheduleNextReminder(startedAt: startedAt, after: date.addingTimeInterval(0.001))
    }

    private func nextReminderDate(startedAt: Date, after referenceDate: Date) -> Date {
        let interval = TimeInterval(currentSettings.reminderIntervalMinutes * 60)
        let elapsed = max(0, referenceDate.timeIntervalSince(startedAt))
        let completedIntervals = floor(elapsed / interval)
        return startedAt.addingTimeInterval((completedIntervals + 1) * interval)
    }

    private func invalidateTimers() {
        startTimer?.invalidate()
        reminderTimer?.invalidate()
        startTimer = nil
        reminderTimer = nil
    }
}
