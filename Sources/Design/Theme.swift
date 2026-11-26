import SwiftUI
import Foundation

/// Цвета и размеры в духе Telegram (тёмная тема).
enum Theme {

    static let background = Color(hex: "#0E1621")
    static let panel = Color(hex: "#17212B")
    static let panelElevated = Color(hex: "#1C2733")
    static let hover = Color(hex: "#202B36")
    static let selected = Color(hex: "#2B5278")
    static let divider = Color(hex: "#101921")

    static let bubbleMine = Color(hex: "#2B5278")
    static let bubbleTheirs = Color(hex: "#182533")

    static let accent = Color(hex: "#5288C1")
    static let accentBright = Color(hex: "#2EA6FF")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#7F91A4")
    static let online = Color(hex: "#4DCD5E")
    static let danger = Color(hex: "#E17076")
    static let star = Color(hex: "#F5C542")

    static let corner: CGFloat = 14
    static let rowHeight: CGFloat = 72
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        default:
            r = 0.5; g = 0.5; b = 0.5; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// Фон переписки — мягкие пятна, как обои Telegram.
struct ChatWallpaper: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Color(hex: "#2B5278").opacity(0.35), .clear],
                center: .topLeading,
                startRadius: 8,
                endRadius: 420
            )
            RadialGradient(
                colors: [Color(hex: "#5288C1").opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 8,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}
