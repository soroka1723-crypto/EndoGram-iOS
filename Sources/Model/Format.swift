import Foundation

/// Форматирование дат, чисел и звёзд в русской локали.
enum Format {

    private static let ru = Locale(identifier: "ru_RU")

    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func chatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return time(date) }
        if calendar.isDateInYesterday(date) { return "вчера" }
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = calendar.isDate(date, equalTo: Date(), toGranularity: .year) ? "d MMM" : "dd.MM.yy"
        return formatter.string(from: date)
    }

    static func dayDivider(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Сегодня" }
        if calendar.isDateInYesterday(date) { return "Вчера" }
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }

    static func callTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return time(date) }
        if calendar.isDateInYesterday(date) { return "вчера" }
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let secs = total % 60
        if minutes >= 60 {
            return String(format: "%d:%02d:%02d", minutes / 60, minutes % 60, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    static func stars(_ value: Int) -> String {
        number(value) + " ⭐️"
    }

    static func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = ru
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func signedStars(_ value: Int) -> String {
        (value > 0 ? "+" : value < 0 ? "−" : "") + number(abs(value)) + " ⭐️"
    }

    static func members(_ count: Int) -> String {
        plural(count, one: "участник", few: "участника", many: "участников")
    }

    /// Русская форма числительного: «1 участник», «2 участника», «5 участников».
    static func plural(_ count: Int, one: String, few: String, many: String) -> String {
        let mod10 = abs(count) % 10
        let mod100 = abs(count) % 100
        let form: String
        if mod100 >= 11 && mod100 <= 14 {
            form = many
        } else {
            switch mod10 {
            case 1: form = one
            case 2, 3, 4: form = few
            default: form = many
            }
        }
        return "\(number(count)) \(form)"
    }

    /// Просмотры истории — как `Story.Footer.NoViews` / `Views_1` / `Views_any`.
    static func views(_ count: Int) -> String {
        guard count > 0 else { return "Нет просмотров" }
        return plural(count, one: "просмотр", few: "просмотра", many: "просмотров")
    }
}

extension Int {
    /// Компактная запись: 1 200 → 1,2K.
    var compact: String {
        if self >= 1_000_000 { return String(format: "%.1fM", Double(self) / 1_000_000) }
        if self >= 1_000 { return String(format: "%.1fK", Double(self) / 1_000) }
        return String(self)
    }
}
