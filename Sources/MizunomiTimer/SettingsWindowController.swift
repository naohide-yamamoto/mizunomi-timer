import AppKit

private final class FocusSinkView: NSView {
    override var acceptsFirstResponder: Bool {
        true
    }

    override func becomeFirstResponder() -> Bool {
        true
    }
}

@MainActor
protocol SettingsWindowControllerDelegate: AnyObject {
    func settingsWindowController(
        _ controller: SettingsWindowController,
        didSave values: SettingsFormValues,
        startTimeChanged: Bool
    )
}

@MainActor
final class SettingsWindowController: NSWindowController {
    weak var delegate: SettingsWindowControllerDelegate?

    private let initialValues: SettingsFormValues
    private let focusSinkView = FocusSinkView()
    private let autoStartAtLaunchButton = NSButton(checkboxWithTitle: "Start timer at app launch", target: nil, action: nil)
    private let startHourPopUp = NSPopUpButton()
    private let startMinutePopUp = NSPopUpButton()
    private let startPeriodPopUp = NSPopUpButton()
    private let intervalField = NSTextField()
    private let durationField = NSTextField()
    private let launchAtLoginButton = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
    private let panelWidthField = NSTextField()
    private let panelHeightField = NSTextField()
    private let displayModePopUp = NSPopUpButton()
    private let panelLocationPopUp = NSPopUpButton()
    private let fillColorWell = NSColorWell()
    private let borderColorWell = NSColorWell()
    private let headingFontField = NSComboBox()
    private let headingFontSizeField = NSTextField()
    private let headingColorWell = NSColorWell()
    private let supportiveFontField = NSComboBox()
    private let supportiveFontSizeField = NSTextField()
    private let supportiveColorWell = NSColorWell()

    init(values: SettingsFormValues) {
        self.initialValues = values

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 506),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        buildContent()
        populateFields(with: values)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.deminiaturize(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(focusSinkView)
    }

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        configureControls()
        focusSinkView.translatesAutoresizingMaskIntoConstraints = false

        let timerSection = section(
            title: "Timer",
            rows: [
                formRow("Start time", startTimeRow()),
                formRow("Reminder interval", minutesRow(field: intervalField)),
                formRow("Reminder duration", minutesRow(field: durationField)),
                formRow("App launch", launchAtLoginButton)
            ]
        )

        let panelSection = section(
            title: "Reminder Panel",
            rows: [
                formRow("Size", sizeRow()),
                formRow("Display", displayModePopUp),
                formRow("Location on Desktop", panelLocationPopUp),
                formRow("Fill colour", fillColorWell),
                formRow("Border colour", borderColorWell),
                formRow("Reminder text", textDetailsRow())
            ]
        )

        let resetButton = NSButton(title: "Reset Settings", target: self, action: #selector(resetDefaults))
        resetButton.bezelStyle = .rounded

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"

        let buttonRow = buttonsRow(resetButton: resetButton, cancelButton: cancelButton, saveButton: saveButton)

        let stack = NSStackView(views: [timerSection, panelSection, buttonRow])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.spacing = 20
        stack.alignment = .leading

        contentView.addSubview(stack)
        contentView.addSubview(focusSinkView)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -22),
            focusSinkView.widthAnchor.constraint(equalToConstant: 1),
            focusSinkView.heightAnchor.constraint(equalToConstant: 1),
            focusSinkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusSinkView.topAnchor.constraint(equalTo: contentView.topAnchor)
        ])
    }

    private func configureControls() {
        NSColorPanel.shared.showsAlpha = true

        autoStartAtLaunchButton.target = self
        autoStartAtLaunchButton.action = #selector(autoStartAtLaunchChanged)

        configureStartTimePopUps()

        intervalField.placeholderString = "60"
        durationField.placeholderString = "10"
        setWidth(intervalField, 52)
        setWidth(durationField, 52)

        setWidth(panelWidthField, 52)
        setWidth(panelHeightField, 52)
        setWidth(headingFontSizeField, 58)
        setWidth(supportiveFontSizeField, 58)

        configureDisplayModePopUp()
        configurePanelLocationPopUp()

        configureColorWell(fillColorWell)
        configureColorWell(borderColorWell)
        configureColorWell(headingColorWell)
        configureColorWell(supportiveColorWell)

        configureFontCombo(headingFontField)
        configureFontCombo(supportiveFontField)
    }

    private func configureStartTimePopUps() {
        for hour in 1...12 {
            startHourPopUp.addItem(withTitle: String(hour))
            startHourPopUp.lastItem?.representedObject = hour
        }

        for minute in 0..<60 {
            startMinutePopUp.addItem(withTitle: String(format: "%02d", minute))
            startMinutePopUp.lastItem?.representedObject = minute
        }

        for period in ["AM", "PM"] {
            startPeriodPopUp.addItem(withTitle: period)
            startPeriodPopUp.lastItem?.representedObject = period
        }

        for popUp in [startHourPopUp, startMinutePopUp, startPeriodPopUp] {
            popUp.target = self
            popUp.action = #selector(startTimeSelectionChanged)
        }

        setWidth(startHourPopUp, 64)
        setWidth(startMinutePopUp, 64)
        setWidth(startPeriodPopUp, 72)
    }

    private func configureDisplayModePopUp() {
        for mode in ReminderDisplayMode.allCases {
            displayModePopUp.addItem(withTitle: mode.displayName)
            displayModePopUp.lastItem?.representedObject = mode.rawValue
        }
        setWidth(displayModePopUp, 260)
        updateDisplayModeAvailability()
    }

    private func configurePanelLocationPopUp() {
        for location in ReminderPanelLocation.allCases {
            panelLocationPopUp.addItem(withTitle: location.displayName)
            panelLocationPopUp.lastItem?.representedObject = location.rawValue
        }
        setWidth(panelLocationPopUp, 180)
    }

    private func populateFields(with values: SettingsFormValues) {
        let appearance = values.reminderPanelAppearance

        autoStartAtLaunchButton.state = values.autoStartTimerAtLaunch ? .on : .off
        selectStartTime(minutesSinceMidnight: values.startTimeMinutes)
        intervalField.stringValue = String(values.reminderIntervalMinutes)
        durationField.stringValue = String(values.reminderDurationMinutes)
        launchAtLoginButton.state = values.launchAtLogin ? .on : .off

        panelWidthField.stringValue = String(appearance.width)
        panelHeightField.stringValue = String(appearance.height)
        selectDisplayMode(NSScreen.screens.count > 1 ? appearance.displayMode : .mainDisplay)
        selectLocation(appearance.location)
        fillColorWell.color = appearance.fillColor.nsColor()
        borderColorWell.color = appearance.borderColor.nsColor()
        headingFontField.stringValue = appearance.headingFontName
        headingFontSizeField.stringValue = displayNumber(appearance.headingFontSize)
        headingColorWell.color = appearance.headingTextColor.nsColor()
        supportiveFontField.stringValue = appearance.supportiveFontName
        supportiveFontSizeField.stringValue = displayNumber(appearance.supportiveFontSize)
        supportiveColorWell.color = appearance.supportiveTextColor.nsColor()

        updateStartTimeAvailability()
        updateDisplayModeAvailability()
    }

    private func section(title: String, rows: [NSView]) -> NSStackView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [titleLabel] + rows)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.spacing = 9
        stack.alignment = .leading
        return stack
    }

    private func formRow(_ title: String, _ control: NSView) -> NSStackView {
        let titleLabel = label(title)
        setWidth(titleLabel, 160)

        let row = NSStackView(views: [titleLabel, control])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.orientation = .horizontal
        row.spacing = 14
        row.alignment = .centerY
        return row
    }

    private func startTimeRow() -> NSStackView {
        let timeRow = NSStackView(views: [
            startHourPopUp,
            suffixLabel(":"),
            startMinutePopUp,
            startPeriodPopUp
        ])
        timeRow.orientation = .horizontal
        timeRow.spacing = 6
        timeRow.alignment = .centerY

        let stack = NSStackView(views: [autoStartAtLaunchButton, timeRow])
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        return stack
    }

    private func minutesRow(field: NSTextField) -> NSStackView {
        let row = NSStackView(views: [field, suffixLabel("minutes")])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }

    private func pointSizeRow(field: NSTextField) -> NSStackView {
        let row = NSStackView(views: [field, suffixLabel("pt")])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }

    private func sizeRow() -> NSStackView {
        let row = NSStackView(views: [
            suffixLabel("Width:"),
            panelWidthField,
            suffixLabel("pt"),
            suffixLabel("Height:"),
            panelHeightField,
            suffixLabel("pt")
        ])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }

    private func textDetailsRow() -> NSStackView {
        let headingRow = compactTextRow(
            title: "Heading",
            fontField: headingFontField,
            sizeField: headingFontSizeField,
            colorWell: headingColorWell
        )
        let supportiveRow = compactTextRow(
            title: "Message",
            fontField: supportiveFontField,
            sizeField: supportiveFontSizeField,
            colorWell: supportiveColorWell
        )

        let stack = NSStackView(views: [headingRow, supportiveRow])
        stack.orientation = .vertical
        stack.spacing = 7
        stack.alignment = .leading
        return stack
    }

    private func compactTextRow(
        title: String,
        fontField: NSComboBox,
        sizeField: NSTextField,
        colorWell: NSColorWell
    ) -> NSStackView {
        let titleLabel = suffixLabel(title)
        setWidth(titleLabel, 70)

        let row = NSStackView(views: [
            titleLabel,
            fontField,
            pointSizeRow(field: sizeField),
            colorWell
        ])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }

    private func buttonsRow(resetButton: NSButton, cancelButton: NSButton, saveButton: NSButton) -> NSStackView {
        let spacer = NSView()
        let row = NSStackView(views: [resetButton, spacer, cancelButton, saveButton])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        row.distribution = .fill
        setWidth(row, 652)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        cancelButton.widthAnchor.constraint(equalToConstant: 84).isActive = true
        saveButton.widthAnchor.constraint(equalToConstant: 84).isActive = true
        return row
    }

    private func label(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .right
        return label
    }

    private func suffixLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func configureColorWell(_ colorWell: NSColorWell) {
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.widthAnchor.constraint(equalToConstant: 44).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    private func configureFontCombo(_ comboBox: NSComboBox) {
        comboBox.addItems(withObjectValues: fontOptions())
        comboBox.completes = true
        comboBox.numberOfVisibleItems = 12
        setWidth(comboBox, 170)
    }

    private func fontOptions() -> [String] {
        let families = NSFontManager.shared.availableFontFamilies.sorted()
        return ["System"] + families.filter { $0 != "System" }
    }

    private func setWidth(_ view: NSView, _ width: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    private func selectedDisplayMode() -> ReminderDisplayMode {
        guard NSScreen.screens.count > 1 else { return .mainDisplay }
        let rawValue = displayModePopUp.selectedItem?.representedObject as? String
        return rawValue.flatMap(ReminderDisplayMode.init(rawValue:)) ?? .mainDisplay
    }

    private func selectDisplayMode(_ mode: ReminderDisplayMode) {
        for item in displayModePopUp.itemArray where item.representedObject as? String == mode.rawValue {
            displayModePopUp.select(item)
            return
        }
    }

    private func selectedLocation() -> ReminderPanelLocation {
        let rawValue = panelLocationPopUp.selectedItem?.representedObject as? String
        return rawValue.flatMap(ReminderPanelLocation.init(rawValue:)) ?? .topRight
    }

    private func selectLocation(_ location: ReminderPanelLocation) {
        for item in panelLocationPopUp.itemArray where item.representedObject as? String == location.rawValue {
            panelLocationPopUp.select(item)
            return
        }
    }

    private func selectedStartTimeMinutes() -> Int {
        let hour = startHourPopUp.selectedItem?.representedObject as? Int ?? 12
        let minute = startMinutePopUp.selectedItem?.representedObject as? Int ?? 0
        let period = startPeriodPopUp.selectedItem?.representedObject as? String ?? "AM"
        let hour24: Int

        if period == "AM" {
            hour24 = hour == 12 ? 0 : hour
        } else {
            hour24 = hour == 12 ? 12 : hour + 12
        }

        return (hour24 * 60) + minute
    }

    private func selectStartTime(minutesSinceMidnight: Int) {
        let hour24 = max(0, min(1439, minutesSinceMidnight)) / 60
        let minute = max(0, min(1439, minutesSinceMidnight)) % 60
        let period = hour24 < 12 ? "AM" : "PM"
        let hour12 = {
            let remainder = hour24 % 12
            return remainder == 0 ? 12 : remainder
        }()

        selectItem(in: startHourPopUp, representedObject: hour12)
        selectItem(in: startMinutePopUp, representedObject: minute)
        selectItem(in: startPeriodPopUp, representedObject: period)
    }

    private func selectItem<T: Equatable>(in popUp: NSPopUpButton, representedObject value: T) {
        for item in popUp.itemArray where item.representedObject as? T == value {
            popUp.select(item)
            return
        }
    }

    private func validatedValues() -> SettingsFormValues? {
        let autoStartTimerAtLaunch = autoStartAtLaunchButton.state == .on
        let startTimeMinutes = selectedStartTimeMinutes()

        guard let interval = parseWholeNumber(intervalField.stringValue),
              (1...1440).contains(interval) else {
            showValidationAlert("Enter a whole number between 1 and 1,440 minutes.")
            return nil
        }

        guard let duration = parseWholeNumber(durationField.stringValue),
              (1...1440).contains(duration) else {
            showValidationAlert("Enter a whole number between 1 and 1,440 minutes.")
            return nil
        }

        guard duration < interval else {
            showValidationAlert("Reminder duration must be shorter than the reminder interval.")
            return nil
        }

        guard let panelWidth = parseWholeNumber(panelWidthField.stringValue),
              (240...720).contains(panelWidth),
              let panelHeight = parseWholeNumber(panelHeightField.stringValue),
              (84...420).contains(panelHeight) else {
            showValidationAlert("Panel width must be 240–720 and height must be 84–420.")
            return nil
        }

        guard let headingFontSize = parseDecimal(headingFontSizeField.stringValue),
              (8...48).contains(headingFontSize),
              let supportiveFontSize = parseDecimal(supportiveFontSizeField.stringValue),
              (8...48).contains(supportiveFontSize) else {
            showValidationAlert("Text sizes must be numbers between 8 and 48 pt.")
            return nil
        }

        return SettingsFormValues(
            autoStartTimerAtLaunch: autoStartTimerAtLaunch,
            startTimeMinutes: startTimeMinutes,
            reminderIntervalMinutes: interval,
            reminderDurationMinutes: duration,
            reminderPanelAppearance: ReminderPanelAppearance(
                width: panelWidth,
                height: panelHeight,
                location: selectedLocation(),
                displayMode: selectedDisplayMode(),
                fillColor: AppColor(nsColor: fillColorWell.color),
                borderColor: AppColor(nsColor: borderColorWell.color),
                headingFontName: cleanedFontName(headingFontField.stringValue),
                headingFontSize: headingFontSize,
                headingTextColor: AppColor(nsColor: headingColorWell.color),
                supportiveFontName: cleanedFontName(supportiveFontField.stringValue),
                supportiveFontSize: supportiveFontSize,
                supportiveTextColor: AppColor(nsColor: supportiveColorWell.color)
            ),
            launchAtLogin: launchAtLoginButton.state == .on
        )
    }

    private func parseWholeNumber(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.allSatisfy(\.isNumber) else { return nil }
        return Int(trimmed)
    }

    private func parseDecimal(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value.isFinite else { return nil }
        return value
    }

    private func cleanedFontName(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "System" : trimmed
    }

    private func displayNumber(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }

    private func defaultFormValues() -> SettingsFormValues {
        let settings = AppSettings.defaults()
        return SettingsFormValues(
            autoStartTimerAtLaunch: settings.autoStartTimerAtLaunch,
            startTimeMinutes: settings.startTimeMinutes,
            reminderIntervalMinutes: settings.reminderIntervalMinutes,
            reminderDurationMinutes: settings.reminderDurationMinutes,
            reminderPanelAppearance: settings.reminderPanelAppearance,
            launchAtLogin: false
        )
    }

    private func showValidationAlert(_ text: String) {
        guard let window else { return }

        let alert = NSAlert()
        alert.messageText = "Check settings"
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window)
    }

    private func updateStartTimeAvailability() {
        let isEnabled = autoStartAtLaunchButton.state == .off
        startHourPopUp.isEnabled = isEnabled
        startMinutePopUp.isEnabled = isEnabled
        startPeriodPopUp.isEnabled = isEnabled
    }

    private func updateDisplayModeAvailability() {
        displayModePopUp.isEnabled = NSScreen.screens.count > 1
        if !displayModePopUp.isEnabled {
            selectDisplayMode(.mainDisplay)
        }
    }

    @objc private func screenParametersDidChange() {
        updateDisplayModeAvailability()
    }

    @objc private func autoStartAtLaunchChanged() {
        updateStartTimeAvailability()
    }

    @objc private func startTimeSelectionChanged() {
        autoStartAtLaunchButton.state = .off
        updateStartTimeAvailability()
    }

    @objc private func resetDefaults() {
        populateFields(with: defaultFormValues())
    }

    @objc private func save() {
        guard let values = validatedValues() else { return }
        let startModeChanged = values.autoStartTimerAtLaunch != initialValues.autoStartTimerAtLaunch
        let customStartTimeChanged = !values.autoStartTimerAtLaunch && values.startTimeMinutes != initialValues.startTimeMinutes

        delegate?.settingsWindowController(
            self,
            didSave: values,
            startTimeChanged: startModeChanged || customStartTimeChanged
        )
        close()
    }

    @objc private func cancel() {
        close()
    }
}
