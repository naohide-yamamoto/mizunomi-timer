import AppKit

struct AppColor: Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(nsColor: NSColor) {
        let color = nsColor.usingColorSpace(.sRGB) ?? nsColor.usingColorSpace(.deviceRGB) ?? .white
        red = Double(color.redComponent)
        green = Double(color.greenComponent)
        blue = Double(color.blueComponent)
        alpha = Double(color.alphaComponent)
    }

    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard [6, 8].contains(cleaned.count), let value = Int(cleaned, radix: 16) else { return nil }

        if cleaned.count == 8 {
            red = Double((value >> 24) & 0xff) / 255.0
            green = Double((value >> 16) & 0xff) / 255.0
            blue = Double((value >> 8) & 0xff) / 255.0
            alpha = Double(value & 0xff) / 255.0
        } else {
            red = Double((value >> 16) & 0xff) / 255.0
            green = Double((value >> 8) & 0xff) / 255.0
            blue = Double(value & 0xff) / 255.0
            alpha = 1.0
        }
    }

    func nsColor() -> NSColor {
        NSColor(
            calibratedRed: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }

    var hexString: String {
        let redValue = max(0, min(255, Int(round(red * 255))))
        let greenValue = max(0, min(255, Int(round(green * 255))))
        let blueValue = max(0, min(255, Int(round(blue * 255))))
        let alphaValue = max(0, min(255, Int(round(alpha * 255))))
        return String(format: "#%02X%02X%02X%02X", redValue, greenValue, blueValue, alphaValue)
    }
}

enum ReminderPanelLocation: String, CaseIterable, Equatable {
    case topRight
    case topCentre
    case topLeft
    case bottomRight
    case bottomCentre
    case bottomLeft

    var displayName: String {
        switch self {
        case .topRight:
            return "Top-right"
        case .topCentre:
            return "Top-centre"
        case .topLeft:
            return "Top-left"
        case .bottomRight:
            return "Bottom-right"
        case .bottomCentre:
            return "Bottom-centre"
        case .bottomLeft:
            return "Bottom-left"
        }
    }
}

enum ReminderDisplayMode: String, CaseIterable, Equatable {
    case mainDisplay
    case activeDisplay

    var displayName: String {
        switch self {
        case .mainDisplay:
            return "Always in the main display"
        case .activeDisplay:
            return "Active display at reminder time"
        }
    }
}

struct ReminderPanelAppearance: Equatable {
    var width: Int
    var height: Int
    var location: ReminderPanelLocation
    var displayMode: ReminderDisplayMode
    var fillColor: AppColor
    var borderColor: AppColor
    var headingFontName: String
    var headingFontSize: Double
    var headingTextColor: AppColor
    var supportiveFontName: String
    var supportiveFontSize: Double
    var supportiveTextColor: AppColor

    static let defaults = ReminderPanelAppearance(
        width: 320,
        height: 90,
        location: .topRight,
        displayMode: .mainDisplay,
        fillColor: AppColor(red: 0.13, green: 0.18, blue: 0.22, alpha: 0.92),
        borderColor: AppColor(red: 0.36, green: 0.58, blue: 0.68, alpha: 0.78),
        headingFontName: "System",
        headingFontSize: 14,
        headingTextColor: AppColor(red: 0.95, green: 0.98, blue: 0.99),
        supportiveFontName: "System",
        supportiveFontSize: 12,
        supportiveTextColor: AppColor(red: 0.78, green: 0.88, blue: 0.92)
    )
}

struct AppSettings: Equatable {
    var startTimeMinutes: Int
    var hasCustomStartTime: Bool
    var reminderIntervalMinutes: Int
    var reminderDurationMinutes: Int
    var reminderPanelAppearance: ReminderPanelAppearance

    var autoStartTimerAtLaunch: Bool {
        get { !hasCustomStartTime }
        set { hasCustomStartTime = !newValue }
    }

    static func defaults(now: Date = Date()) -> AppSettings {
        AppSettings(
            startTimeMinutes: TimeFormatter.minutesSinceMidnight(from: now),
            hasCustomStartTime: false,
            reminderIntervalMinutes: 60,
            reminderDurationMinutes: 10,
            reminderPanelAppearance: .defaults
        )
    }
}

final class AppSettingsStore {
    private enum Key {
        static let startTimeMinutes = "startTimeMinutes"
        static let hasCustomStartTime = "hasCustomStartTime"
        static let reminderIntervalMinutes = "reminderIntervalMinutes"
        static let reminderDurationMinutes = "reminderDurationMinutes"
        static let reminderPanelWidth = "reminderPanelWidth"
        static let reminderPanelHeight = "reminderPanelHeight"
        static let reminderPanelLocation = "reminderPanelLocation"
        static let reminderPanelDisplayMode = "reminderPanelDisplayMode"
        static let reminderPanelFillColor = "reminderPanelFillColor"
        static let reminderPanelFillTransparencyPercent = "reminderPanelFillTransparencyPercent"
        static let reminderPanelBorderColor = "reminderPanelBorderColor"
        static let reminderHeadingFontName = "reminderHeadingFontName"
        static let reminderHeadingFontSize = "reminderHeadingFontSize"
        static let reminderHeadingTextColor = "reminderHeadingTextColor"
        static let reminderSupportiveFontName = "reminderSupportiveFontName"
        static let reminderSupportiveFontSize = "reminderSupportiveFontSize"
        static let reminderSupportiveTextColor = "reminderSupportiveTextColor"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(now: Date = Date()) -> AppSettings {
        let fallback = AppSettings.defaults(now: now)
        let hasInterval = defaults.object(forKey: Key.reminderIntervalMinutes) != nil
        let hasDuration = defaults.object(forKey: Key.reminderDurationMinutes) != nil
        let hasStart = defaults.object(forKey: Key.startTimeMinutes) != nil
        let fallbackAppearance = fallback.reminderPanelAppearance
        let location = ReminderPanelLocation(
            rawValue: defaults.string(forKey: Key.reminderPanelLocation) ?? fallbackAppearance.location.rawValue
        ) ?? fallbackAppearance.location
        let displayMode = ReminderDisplayMode(
            rawValue: defaults.string(forKey: Key.reminderPanelDisplayMode) ?? fallbackAppearance.displayMode.rawValue
        ) ?? fallbackAppearance.displayMode

        return AppSettings(
            startTimeMinutes: hasStart ? defaults.integer(forKey: Key.startTimeMinutes) : fallback.startTimeMinutes,
            hasCustomStartTime: defaults.bool(forKey: Key.hasCustomStartTime),
            reminderIntervalMinutes: hasInterval ? defaults.integer(forKey: Key.reminderIntervalMinutes) : fallback.reminderIntervalMinutes,
            reminderDurationMinutes: hasDuration ? defaults.integer(forKey: Key.reminderDurationMinutes) : fallback.reminderDurationMinutes,
            reminderPanelAppearance: ReminderPanelAppearance(
                width: integer(forKey: Key.reminderPanelWidth, fallback: fallbackAppearance.width),
                height: integer(forKey: Key.reminderPanelHeight, fallback: fallbackAppearance.height),
                location: location,
                displayMode: displayMode,
                fillColor: fillColor(fallback: fallbackAppearance.fillColor),
                borderColor: color(forKey: Key.reminderPanelBorderColor, fallback: fallbackAppearance.borderColor),
                headingFontName: string(forKey: Key.reminderHeadingFontName, fallback: fallbackAppearance.headingFontName),
                headingFontSize: double(forKey: Key.reminderHeadingFontSize, fallback: fallbackAppearance.headingFontSize),
                headingTextColor: color(forKey: Key.reminderHeadingTextColor, fallback: fallbackAppearance.headingTextColor),
                supportiveFontName: string(forKey: Key.reminderSupportiveFontName, fallback: fallbackAppearance.supportiveFontName),
                supportiveFontSize: double(forKey: Key.reminderSupportiveFontSize, fallback: fallbackAppearance.supportiveFontSize),
                supportiveTextColor: color(forKey: Key.reminderSupportiveTextColor, fallback: fallbackAppearance.supportiveTextColor)
            )
        ).normalised()
    }

    func save(_ settings: AppSettings) {
        let normalised = settings.normalised()
        let appearance = normalised.reminderPanelAppearance
        defaults.set(normalised.startTimeMinutes, forKey: Key.startTimeMinutes)
        defaults.set(normalised.hasCustomStartTime, forKey: Key.hasCustomStartTime)
        defaults.set(normalised.reminderIntervalMinutes, forKey: Key.reminderIntervalMinutes)
        defaults.set(normalised.reminderDurationMinutes, forKey: Key.reminderDurationMinutes)
        defaults.set(appearance.width, forKey: Key.reminderPanelWidth)
        defaults.set(appearance.height, forKey: Key.reminderPanelHeight)
        defaults.set(appearance.location.rawValue, forKey: Key.reminderPanelLocation)
        defaults.set(appearance.displayMode.rawValue, forKey: Key.reminderPanelDisplayMode)
        defaults.set(appearance.fillColor.hexString, forKey: Key.reminderPanelFillColor)
        defaults.set(appearance.borderColor.hexString, forKey: Key.reminderPanelBorderColor)
        defaults.set(appearance.headingFontName, forKey: Key.reminderHeadingFontName)
        defaults.set(appearance.headingFontSize, forKey: Key.reminderHeadingFontSize)
        defaults.set(appearance.headingTextColor.hexString, forKey: Key.reminderHeadingTextColor)
        defaults.set(appearance.supportiveFontName, forKey: Key.reminderSupportiveFontName)
        defaults.set(appearance.supportiveFontSize, forKey: Key.reminderSupportiveFontSize)
        defaults.set(appearance.supportiveTextColor.hexString, forKey: Key.reminderSupportiveTextColor)
    }

    private func integer(forKey key: String, fallback: Int) -> Int {
        defaults.object(forKey: key) == nil ? fallback : defaults.integer(forKey: key)
    }

    private func double(forKey key: String, fallback: Double) -> Double {
        defaults.object(forKey: key) == nil ? fallback : defaults.double(forKey: key)
    }

    private func string(forKey key: String, fallback: String) -> String {
        let value = defaults.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value! : fallback
    }

    private func color(forKey key: String, fallback: AppColor) -> AppColor {
        guard let hex = defaults.string(forKey: key) else { return fallback }
        return (AppColor(hex: hex) ?? fallback).normalised()
    }

    private func fillColor(fallback: AppColor) -> AppColor {
        var color = color(forKey: Key.reminderPanelFillColor, fallback: fallback)
        let cleanedHex = defaults.string(forKey: Key.reminderPanelFillColor)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        if cleanedHex?.count == 6,
           defaults.object(forKey: Key.reminderPanelFillTransparencyPercent) != nil {
            let transparency = max(0, min(100, defaults.integer(forKey: Key.reminderPanelFillTransparencyPercent)))
            color.alpha = 1.0 - (Double(transparency) / 100.0)
        }
        return color.normalised()
    }
}

private extension AppSettings {
    func normalised() -> AppSettings {
        AppSettings(
            startTimeMinutes: max(0, min(1439, startTimeMinutes)),
            hasCustomStartTime: hasCustomStartTime,
            reminderIntervalMinutes: max(1, min(1440, reminderIntervalMinutes)),
            reminderDurationMinutes: max(1, min(1440, reminderDurationMinutes)),
            reminderPanelAppearance: reminderPanelAppearance.normalised()
        )
    }
}

private extension ReminderPanelAppearance {
    func normalised() -> ReminderPanelAppearance {
        ReminderPanelAppearance(
            width: max(240, min(720, width)),
            height: max(84, min(420, height)),
            location: location,
            displayMode: displayMode,
            fillColor: fillColor.normalised(),
            borderColor: borderColor.normalised(),
            headingFontName: headingFontName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "System" : headingFontName,
            headingFontSize: max(8, min(48, headingFontSize)),
            headingTextColor: headingTextColor.normalised(),
            supportiveFontName: supportiveFontName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "System" : supportiveFontName,
            supportiveFontSize: max(8, min(48, supportiveFontSize)),
            supportiveTextColor: supportiveTextColor.normalised()
        )
    }
}

private extension AppColor {
    func normalised() -> AppColor {
        AppColor(
            red: max(0, min(1, red)),
            green: max(0, min(1, green)),
            blue: max(0, min(1, blue)),
            alpha: max(0, min(1, alpha))
        )
    }
}
