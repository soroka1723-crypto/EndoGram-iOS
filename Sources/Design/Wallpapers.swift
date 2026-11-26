import SwiftUI

/// Один слой градиента обоев: цвет, прозрачность и позиция.
struct WallpaperStop {
    let hex: String
    let opacity: Double
    let location: Double
}

/// Варианты обоев чата, доступные офлайн.
///
/// `telegram` — ровно то, что использует ночная тема оригинального клиента:
/// градиент из `defaultDarkWallpaperGradientColors`
/// (`0x598BF6, 0x7A5EEF, 0xD67CFF, 0xF38B58`) с интенсивностью -34.
/// Остальные варианты собраны из тех же токенов палитры и меняют только
/// прозрачности и базовую заливку.
enum WallpaperStyle: String, CaseIterable, Identifiable {
    case telegram
    case gradient = "градиент"
    case night = "ночной"
    case ocean = "океан"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .telegram: return "Telegram"
        case .gradient: return "Градиент"
        case .night:    return "Ночной"
        case .ocean:    return "Океан"
        }
    }

    var detail: String {
        switch self {
        case .telegram: return "как в ночной теме Telegram"
        case .gradient: return "те же цвета, но ярче"
        case .night:    return "почти чёрный фон"
        case .ocean:    return "сине-бирюзовый градиент"
        }
    }

    /// Значение из настроек может быть любым: неизвестное трактуем как Telegram.
    static func resolve(_ raw: String) -> WallpaperStyle {
        WallpaperStyle(rawValue: raw) ?? .telegram
    }

    var base: Color {
        switch self {
        case .telegram, .night: return Color(hex: "#04070B")
        case .gradient:         return Color(hex: "#0A0A12")
        case .ocean:            return Color(hex: "#03121C")
        }
    }

    var stops: [WallpaperStop] {
        switch self {
        case .telegram:
            return [
                WallpaperStop(hex: "#598BF6", opacity: 0.20, location: 0.00),
                WallpaperStop(hex: "#7A5EEF", opacity: 0.17, location: 0.34),
                WallpaperStop(hex: "#D67CFF", opacity: 0.13, location: 0.68),
                WallpaperStop(hex: "#F38B58", opacity: 0.10, location: 1.00),
            ]
        case .gradient:
            return [
                WallpaperStop(hex: "#598BF6", opacity: 0.42, location: 0.00),
                WallpaperStop(hex: "#7A5EEF", opacity: 0.36, location: 0.34),
                WallpaperStop(hex: "#D67CFF", opacity: 0.30, location: 0.68),
                WallpaperStop(hex: "#F38B58", opacity: 0.26, location: 1.00),
            ]
        case .night:
            return [
                WallpaperStop(hex: "#1B2A44", opacity: 0.55, location: 0.00),
                WallpaperStop(hex: "#0B1220", opacity: 0.30, location: 1.00),
            ]
        case .ocean:
            return [
                WallpaperStop(hex: "#0E7490", opacity: 0.42, location: 0.00),
                WallpaperStop(hex: "#1D4ED8", opacity: 0.34, location: 0.45),
                WallpaperStop(hex: "#0EA5E9", opacity: 0.24, location: 1.00),
            ]
        }
    }

    var glowHex: String {
        switch self {
        case .telegram: return "#598BF6"
        case .gradient: return "#D67CFF"
        case .night:    return "#1B2A44"
        case .ocean:    return "#22D3EE"
        }
    }

    var glowOpacity: Double {
        switch self {
        case .telegram: return 0.16
        case .gradient: return 0.26
        case .night:    return 0.10
        case .ocean:    return 0.22
        }
    }
}

/// Обои переписки: фон под сообщениями.
struct ChatWallpaper: View {
    var style: WallpaperStyle = .telegram

    var body: some View {
        ZStack {
            style.base

            LinearGradient(
                stops: style.stops.map {
                    Gradient.Stop(color: Color(hex: $0.hex).opacity($0.opacity), location: $0.location)
                },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(hex: style.glowHex).opacity(style.glowOpacity), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}

/// Плитка-превью обоев для выбора в настройках.
struct WallpaperThumbnail: View {
    let style: WallpaperStyle
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ChatWallpaper(style: style)
                .frame(height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Theme.accent : Color.white.opacity(0.10),
                                lineWidth: isSelected ? 2 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .background(Circle().fill(Theme.accent).padding(2))
                            .padding(6)
                    }
                }

            Text(style.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
        }
    }
}
