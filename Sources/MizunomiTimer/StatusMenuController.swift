import AppKit

@MainActor
protocol StatusMenuControllerDelegate: AnyObject {
    func statusMenuDidChooseStart()
    func statusMenuDidChoosePauseOrResume()
    func statusMenuDidChooseStop()
    func statusMenuDidChooseSettings()
    func statusMenuDidChooseHelp()
    func statusMenuDidChooseAbout()
    func statusMenuDidChooseQuit()
}

@MainActor
final class StatusMenuController: NSObject {
    private weak var delegate: StatusMenuControllerDelegate?
    private var statusItem: NSStatusItem?

    private let menu = NSMenu()
    private let startItem = NSMenuItem(title: "Start", action: #selector(start), keyEquivalent: "")
    private let pauseItem = NSMenuItem(title: "Pause", action: #selector(pauseOrResume), keyEquivalent: "")
    private let stopItem = NSMenuItem(title: "Stop", action: #selector(stop), keyEquivalent: "")
    private let settingsItem = NSMenuItem(title: "Settings", action: #selector(settings), keyEquivalent: "")
    private let helpItem = NSMenuItem(title: "Help", action: #selector(help), keyEquivalent: "")
    private let aboutItem = NSMenuItem(title: "About Mizunomi Timer", action: #selector(about), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")

    init(delegate: StatusMenuControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    func install() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = MenuBarIconFactory.makeTemplateIcon()
        statusItem?.button?.toolTip = "Mizunomi Timer"
        statusItem?.button?.setAccessibilityLabel("Mizunomi Timer")

        menu.autoenablesItems = false

        for item in [startItem, pauseItem, stopItem, settingsItem, helpItem, aboutItem, quitItem] {
            item.target = self
        }

        menu.addItem(startItem)
        menu.addItem(pauseItem)
        menu.addItem(stopItem)
        menu.addItem(.separator())
        menu.addItem(settingsItem)
        menu.addItem(helpItem)
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem?.menu = menu
        update(for: .stopped)
    }

    func update(for state: TimerState) {
        switch state {
        case .stopped:
            startItem.title = "Start"
            startItem.isEnabled = true
            pauseItem.title = "Pause"
            pauseItem.isEnabled = false
            stopItem.isEnabled = false
        case .waiting:
            startItem.title = "Start"
            startItem.isEnabled = true
            pauseItem.title = "Pause"
            pauseItem.isEnabled = false
            stopItem.isEnabled = true
        case .running(let startedAt):
            startItem.title = "Started at \(TimeFormatter.displayTime(from: startedAt))"
            startItem.isEnabled = false
            pauseItem.title = "Pause"
            pauseItem.isEnabled = true
            stopItem.isEnabled = true
        case .paused(let startedAt):
            startItem.title = "Started at \(TimeFormatter.displayTime(from: startedAt))"
            startItem.isEnabled = false
            pauseItem.title = "Resume"
            pauseItem.isEnabled = true
            stopItem.isEnabled = true
        }
    }

    @objc private func start() {
        delegate?.statusMenuDidChooseStart()
    }

    @objc private func pauseOrResume() {
        delegate?.statusMenuDidChoosePauseOrResume()
    }

    @objc private func stop() {
        delegate?.statusMenuDidChooseStop()
    }

    @objc private func settings() {
        delegate?.statusMenuDidChooseSettings()
    }

    @objc private func help() {
        delegate?.statusMenuDidChooseHelp()
    }

    @objc private func about() {
        delegate?.statusMenuDidChooseAbout()
    }

    @objc private func quit() {
        delegate?.statusMenuDidChooseQuit()
    }
}
