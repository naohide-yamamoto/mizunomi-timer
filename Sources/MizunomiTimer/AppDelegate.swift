import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = AppSettingsStore()
    private lazy var timerController = ReminderTimerController(settingsStore: settingsStore)
    private lazy var statusMenuController = StatusMenuController(delegate: self)

    private var settingsWindowController: SettingsWindowController?
    private var aboutWindowController: AboutWindowController?
    private var activeReminderPanel: ReminderPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.applicationIconImage = AppIconFactory.makeApplicationIcon(size: 256)

        timerController.onStateChanged = { [weak self] state in
            self?.statusMenuController.update(for: state)
        }

        timerController.onReminderDue = { [weak self] dueDate in
            self?.showReminder(for: dueDate)
        }

        statusMenuController.install()
        timerController.startOnLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        activeReminderPanel?.dismissWithoutRecording()
        timerController.resetHistory()
    }

    private func showReminder(for dueDate: Date) {
        activeReminderPanel?.expireAsMissed()
        activeReminderPanel = nil

        let unhadMinutes = timerController.currentUnhadMinutes
        let panel = ReminderPanelController(
            unhadMinutes: unhadMinutes,
            displayDurationMinutes: timerController.currentSettings.reminderDurationMinutes,
            appearance: timerController.currentSettings.reminderPanelAppearance
        ) { [weak self] outcome in
            guard let self else { return }
            self.timerController.record(outcome)
            self.activeReminderPanel = nil
        }

        activeReminderPanel = panel
        panel.show()
    }

    private func openSettingsWindow() {
        if let controller = settingsWindowController,
           let window = controller.window,
           window.isVisible || window.isMiniaturized {
            controller.show()
            return
        }

        let values = timerController.settingsFormValues(
            launchAtLogin: LaunchAtLoginController.isEnabled
        )
        let controller = SettingsWindowController(values: values)
        controller.delegate = self
        settingsWindowController = controller
        controller.show()
    }

    private func openAboutWindow() {
        let controller = aboutWindowController ?? AboutWindowController()
        aboutWindowController = controller
        controller.show()
    }

    private func openHelp() {
        guard let helpURL = Bundle.main.url(forResource: "UserManual", withExtension: "html") else {
            showAlert(
                message: "Help could not be opened.",
                informativeText: "The user manual is missing from the app bundle."
            )
            return
        }

        if !NSWorkspace.shared.open(helpURL) {
            showAlert(
                message: "Help could not be opened.",
                informativeText: "macOS could not find an app for opening the user manual."
            )
        }
    }

    private func showAlert(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning

        alert.runModal()
    }
}

extension AppDelegate: StatusMenuControllerDelegate {
    func statusMenuDidChooseStart() {
        timerController.startNow()
    }

    func statusMenuDidChoosePauseOrResume() {
        timerController.pauseOrResume()
    }

    func statusMenuDidChooseStop() {
        activeReminderPanel?.dismissWithoutRecording()
        activeReminderPanel = nil
        timerController.stop()
    }

    func statusMenuDidChooseReset() {
        activeReminderPanel?.dismissWithoutRecording()
        activeReminderPanel = nil
        timerController.stop()
        timerController.startNow()
    }

    func statusMenuDidChooseSettings() {
        openSettingsWindow()
    }

    func statusMenuDidChooseHelp() {
        openHelp()
    }

    func statusMenuDidChooseAbout() {
        openAboutWindow()
    }

    func statusMenuDidChooseQuit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: SettingsWindowControllerDelegate {
    func settingsWindowController(
        _ controller: SettingsWindowController,
        didSave values: SettingsFormValues,
        startTimeChanged: Bool
    ) {
        do {
            try LaunchAtLoginController.setEnabled(values.launchAtLogin)
        } catch {
            showAlert(
                message: "Launch at login could not be updated.",
                informativeText: error.localizedDescription
            )
        }

        let settings = AppSettings(
            startTimeMinutes: values.startTimeMinutes,
            hasCustomStartTime: !values.autoStartTimerAtLaunch,
            reminderIntervalMinutes: values.reminderIntervalMinutes,
            reminderDurationMinutes: values.reminderDurationMinutes,
            reminderPanelAppearance: values.reminderPanelAppearance
        )

        if timerController.state == .stopped && !startTimeChanged {
            timerController.save(settings: settings)
        } else {
            timerController.apply(settings: settings, startTimeChanged: startTimeChanged)
        }
    }
}
