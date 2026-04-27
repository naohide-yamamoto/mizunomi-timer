import AppKit

@MainActor
final class ReminderPanelController: NSObject {
    private let unhadMinutes: Int?
    private let displayDurationMinutes: Int
    private let appearance: ReminderPanelAppearance
    private let onResolve: (ReminderOutcome) -> Void
    private var panel: NSPanel?
    private var timeoutTimer: Timer?
    private var didResolve = false

    init(
        unhadMinutes: Int?,
        displayDurationMinutes: Int,
        appearance: ReminderPanelAppearance,
        onResolve: @escaping (ReminderOutcome) -> Void
    ) {
        self.unhadMinutes = unhadMinutes
        self.displayDurationMinutes = displayDurationMinutes
        self.appearance = appearance
        self.onResolve = onResolve
        super.init()
    }

    func show() {
        let panel = makePanel()
        self.panel = panel
        position(panel)
        panel.orderFrontRegardless()

        timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(displayDurationMinutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.resolve(.missed)
            }
        }
    }

    func expireAsMissed() {
        resolve(.missed)
    }

    func dismissWithoutRecording() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        panel?.close()
        panel = nil
        didResolve = true
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: CGFloat(appearance.width), height: CGFloat(appearance.height)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hasShadow = false
        panel.backgroundColor = .clear
        panel.isOpaque = false

        let backgroundView = NSView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 12
        backgroundView.layer?.masksToBounds = true
        backgroundView.layer?.backgroundColor = appearance.fillColor.nsColor().cgColor
        backgroundView.layer?.borderWidth = 1
        backgroundView.layer?.borderColor = appearance.borderColor.nsColor().cgColor

        let iconView = NSImageView(image: NSApp.applicationIconImage ?? AppIconFactory.makeApplicationIcon(size: 128))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown

        let title = NSTextField(labelWithString: "Time for water")
        title.font = font(named: appearance.headingFontName, size: appearance.headingFontSize, weight: .semibold)
        title.textColor = appearance.headingTextColor.nsColor()
        title.lineBreakMode = .byTruncatingTail

        var textViews: [NSView] = [title]
        if let messageText {
            let message = NSTextField(wrappingLabelWithString: messageText)
            message.font = font(named: appearance.supportiveFontName, size: appearance.supportiveFontSize, weight: .regular)
            message.textColor = appearance.supportiveTextColor.nsColor()
            message.maximumNumberOfLines = 2
            textViews.append(message)
        }

        let textStack = NSStackView(views: textViews)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.orientation = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading

        let headerStack = NSStackView(views: [iconView, textStack])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.orientation = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .centerY

        let okButton = NSButton(title: "OK", target: self, action: #selector(ok))
        okButton.bezelStyle = .rounded

        let skipButton = NSButton(title: "Skip", target: self, action: #selector(skip))
        skipButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [skipButton, okButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillEqually

        let contentStack = NSStackView(views: [headerStack, buttonStack])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.orientation = .vertical
        contentStack.spacing = 8
        contentStack.alignment = .trailing

        backgroundView.addSubview(contentStack)
        panel.contentView = backgroundView

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),
            contentStack.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14),
            contentStack.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: backgroundView.bottomAnchor, constant: -9),
            buttonStack.widthAnchor.constraint(equalToConstant: 132)
        ])

        return panel
    }

    private func position(_ panel: NSPanel) {
        let screenFrame = selectedScreenFrame()
        let margin: CGFloat = 18
        let x: CGFloat
        let y: CGFloat

        switch appearance.location {
        case .topRight, .bottomRight:
            x = screenFrame.maxX - panel.frame.width - margin
        case .topCentre, .bottomCentre:
            x = screenFrame.midX - (panel.frame.width / 2)
        case .topLeft, .bottomLeft:
            x = screenFrame.minX + margin
        }

        switch appearance.location {
        case .topRight, .topCentre, .topLeft:
            y = screenFrame.maxY - panel.frame.height - margin
        case .bottomRight, .bottomCentre, .bottomLeft:
            y = screenFrame.minY + margin
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func selectedScreenFrame() -> NSRect {
        let mainDisplay = NSScreen.screens.first
        switch appearance.displayMode {
        case .mainDisplay:
            return mainDisplay?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        case .activeDisplay:
            return NSScreen.main?.visibleFrame ?? mainDisplay?.visibleFrame ?? .zero
        }
    }

    private var messageText: String? {
        guard let unhadMinutes else { return nil }
        return "You have not had water for \(unhadMinutes) minutes."
    }

    private func font(named name: String, size: Double, weight: NSFont.Weight) -> NSFont {
        let fontSize = CGFloat(size)
        if name == "System" {
            return .systemFont(ofSize: fontSize, weight: weight)
        }

        return NSFont(name: name, size: fontSize) ?? .systemFont(ofSize: fontSize, weight: weight)
    }

    private func resolve(_ outcome: ReminderOutcome) {
        guard !didResolve else { return }
        didResolve = true
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        panel?.close()
        panel = nil
        onResolve(outcome)
    }

    @objc private func ok() {
        resolve(.completed)
    }

    @objc private func skip() {
        resolve(.skipped)
    }
}
