import Foundation

/// Идентификаторы и палитра.
enum IDs {
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz0123456789")

    static func randomToken(length: Int) -> String {
        String((0..<length).map { _ in alphabet.randomElement() ?? "a" })
    }

    static func next(_ prefix: String) -> String {
        "\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000))_\(randomToken(length: 4))"
    }
}

/// Цвета собеседников — точный список из официального клиента Telegram.
///
/// Источник: `submodules/AccountContext/Sources/PeerNameColors.swift`,
/// `PeerNameColors.defaultSingleColors` и `displayOrder`.
enum Palette {

    /// 0x368AD1 — индекс 5, первый в порядке отображения Telegram
    static let blue = "#368AD1"
    /// 0x40A920 — индекс 3
    static let green = "#40A920"
    /// 0xD67722 — индекс 1
    static let orange = "#D67722"
    /// 0xCC5049 — индекс 0
    static let red = "#CC5049"
    /// 0x955CDB — индекс 2
    static let purple = "#955CDB"
    /// 0x309EBA — индекс 4
    static let cyan = "#309EBA"
    /// 0xC7508B — индекс 6
    static let pink = "#C7508B"

    /// Порядок ровно как `displayOrder: [5, 3, 1, 0, 2, 4, 6]`.
    static let avatarColors = [
        blue, green, orange, red, purple, cyan, pink,
    ]

    /// Стабильный цвет для имени: одно и то же имя всегда получает один и тот же цвет.
    static func peerColor(for name: String) -> String {
        guard !avatarColors.isEmpty else { return blue }
        var hash: Int32 = 0
        for scalar in name.unicodeScalars {
            hash = hash &* 31 &+ Int32(bitPattern: scalar.value)
        }
        let index = Int(UInt32(bitPattern: hash) % UInt32(avatarColors.count))
        return avatarColors[index]
    }
}