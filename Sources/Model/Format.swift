import Foundation

/// Р¤РѕСЂРјР°С‚РёСЂРѕРІР°РЅРёРµ РґР°С‚, С‡РёСЃРµР» Рё Р·РІС‘Р·Рґ РІ СЂСѓСЃСЃРєРѕР№ Р»РѕРєР°Р»Рё.
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
        if calendar.isDateInYesterday(date) { return "РІС‡РµСЂР°" }
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = calendar.isDate(date, equalTo: Date(), toGranularity: .year) ? "d MMM" : "dd.MM.yy"
        return formatter.string(from: date)
    }

    static func dayDivider(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "РЎРµРіРѕРґРЅСЏ" }
        if calendar.isDateInYesterday(date) { return "Р’С‡РµСЂР°" }
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
        if calendar.isDateInYesterday(date) { return "РІС‡РµСЂР°" }
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
        number(value) + " в­ђпёЏ"
    }

    static func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = ru
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func signedStars(_ value: Int) -> String {
        (value > 0 ? "+" : value < 0 ? "в€’" : "") + number(abs(value)) + " в­ђпёЏ"
    }

    static func members(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return "\(count) СѓС‡Р°СЃС‚РЅРёРєРѕРІ" }
        switch mod10 {
        case 1: return "\(count) СѓС‡Р°СЃС‚РЅРёРє"
        case 2, 3, 4: return "\(count) СѓС‡Р°СЃС‚РЅРёРєР°"
        default: return "\(count) СѓС‡Р°СЃС‚РЅРёРєРѕРІ"
        }
    }
}

extension Int {
    /// РљРѕРјРїР°РєС‚РЅР°СЏ Р·Р°РїРёСЃСЊ: 1 200 в†’ 1,2K.
    var compact: String {
        if self >= 1_000_000 { return String(format: "%.1fM", Double(self) / 1_000_000) }
        if self >= 1_000 { return String(format: "%.1fK", Double(self) / 1_000) }
        return String(self)
    }
}

