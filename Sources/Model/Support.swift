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

enum Palette {
    static let blue = "#5288C1"
    static let green = "#4DCD5E"
    static let orange = "#E8A87C"
    static let red = "#E17076"
    static let purple = "#9B7EDE"

    static let avatarColors = [
        "#E17076", "#7BC862", "#E5CA77", "#65AADD", "#A695E7",
        "#EE7AAE", "#6EC9CB", "#FAA774", "#5288C1", "#9B7EDE",
    ]
}
