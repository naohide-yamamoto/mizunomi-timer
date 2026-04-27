import Foundation

enum TimeFormatter {
    static func displayTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }

    static func displayTime(minutesSinceMidnight minutes: Int) -> String {
        displayTime(from: dateForMinutes(minutes))
    }

    static func parseTime(_ text: String) -> Int? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")

        guard !cleaned.isEmpty else { return nil }

        for format in ["h:mm a", "h:mma"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            formatter.isLenient = true

            if let date = formatter.date(from: cleaned.uppercased()) {
                return minutesSinceMidnight(from: date)
            }
        }

        return nil
    }

    static func minutesSinceMidnight(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    static func nextOccurrence(minutesSinceMidnight minutes: Int, after referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = minutes / 60
        components.minute = minutes % 60
        components.second = 0

        guard let today = calendar.date(from: components) else {
            return referenceDate
        }

        if today > referenceDate {
            return today
        }

        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    static func dateForMinutes(_ minutes: Int, referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = minutes / 60
        components.minute = minutes % 60
        components.second = 0
        return calendar.date(from: components) ?? referenceDate
    }
}
