import SwiftUI
import Foundation

/// Палитра перенесена из официального клиента Telegram для iOS.
///
/// Источник: `submodules/TelegramPresentationData/Sources/DefaultDarkPresentationTheme.swift`
/// (ночная тема, акцент `0x3E88F7` — как в `defaultDarkColorPresentationTheme`).
/// Значения цветов не выдуманы: каждое соответствует конкретному полю темы Telegram,
/// имя поля указано в комментарии.
enum Theme {

    // MARK: - Поверхности

    /// `theme.list.blocksBackgroundColor` / `theme.chatList.backgroundColor` — 0x000000
    static let background = Color(hex: "#000000")
    /// `theme.list.itemBlocksBackgroundColor` — 0x1C1C1D (карточки, блоки настроек)
    static let panel = Color(hex: "#1C1C1D")
    /// `theme.list.itemModalBlocksBackgroundColor` — 0x2C2C2E
    static let panelElevated = Color(hex: "#2C2C2E")
    /// `theme.list.itemHighlightedBackgroundColor` — 0x313135
    static let hover = Color(hex: "#313135")
    /// `theme.chatList.itemSelectedBackgroundColor` — 0x191919
    static let selected = Color(hex: "#191919")
    /// Разделители: UIColor(rgb: 0x545458, alpha: 0.55)
    static let divider = Color(hex: "#545458").opacity(0.55)
    /// `theme.chatList.pinnedItemBackgroundColor` — 0x1C1C1D
    static let pinnedRow = Color(hex: "#1C1C1D")
    /// `theme.chatList.regularSearchBarColor` — 0x272728
    static let searchBar = Color(hex: "#272728")
    /// `theme.rootNavigationBar.opaqueBackgroundColor` — 0x1D1D1D
    static let rootNavigationBar = Color(hex: "#1D1D1D")
    /// `theme.rootNavigationBar.separatorColor` — 0x545458 @0.55
    static let rootNavigationBarSeparator = Color(hex: "#545458").opacity(0.55)

    // MARK: - Пузыри сообщений

    /// Исходящее: градиент `[0x61BCF9, 0x0088FF]` (theme.chat.message.outgoing.bubble.fill)
    static let bubbleOutgoingTop = Color(hex: "#61BCF9")
    static let bubbleOutgoingBottom = Color(hex: "#0088FF")
    /// Входящее: 0x1D1D1D с альфой 0.9 (theme.chat.message.incoming.bubble.fill)
    static let bubbleIncoming = Color(hex: "#1D1D1D").opacity(0.9)

    /// Совместимость: сплошные цвета пузырей.
    static let bubbleMine = Color(hex: "#0088FF")
    static let bubbleTheirs = Color(hex: "#1D1D1D").opacity(0.9)

    /// `theme.chat.message.outgoing.secondaryTextColor` — 0xffffff @ 0.5
    static let bubbleSecondaryMine = Color.white.opacity(0.5)
    /// `theme.chat.message.incoming.secondaryTextColor` — 0xffffff @ 0.5
    static let bubbleSecondaryTheirs = Color.white.opacity(0.5)

    // MARK: - Текст

    /// `theme.list.itemPrimaryTextColor` — 0xffffff
    static let textPrimary = Color.white
    /// `theme.chatList.dateTextColor` / `theme.list.sectionHeaderTextColor` — 0x8D8E93
    static let textSecondary = Color(hex: "#8D8E93")
    /// `theme.list.itemSecondaryTextColor` — 0x98989E
    static let textListItemSecondary = Color(hex: "#98989E")
    /// `theme.list.itemDisabledTextColor` — 0x8F8F8F
    static let textDisabled = Color(hex: "#8F8F8F")
    /// `theme.list.itemPlaceholderTextColor` — 0x4D4D4D
    static let textPlaceholder = Color(hex: "#4D4D4D")
    /// `theme.list.disclosureArrowColor` — 0xffffff @ 0.28
    static let disclosure = Color.white.opacity(0.28)

    // MARK: - Акценты и семантика

    /// Акцент `defaultDarkColorPresentationTheme` — 0x3E88F7
    static let accent = Color(hex: "#3E88F7")
    static let accentBright = Color(hex: "#3E88F7")
    /// `theme.chat.message.incoming.linkTextColor` при акценте
    static let link = Color(hex: "#3E88F7")
    /// `theme.chatList.onlineDotColor` — 0x4CC91F
    static let online = Color(hex: "#4CC91F")
    /// `theme.list.itemDestructiveColor` — 0xEB5545
    static let danger = Color(hex: "#EB5545")
    /// `theme.chat.message.textHighlightColor` — 0xF5C038
    static let star = Color(hex: "#F5C038")
    /// `theme.list.itemDisclosureActions.constructive` — 0x08A723
    static let success = Color(hex: "#08A723")
    /// `theme.list.itemDisclosureActions.warning` — 0xCD7800
    static let warning = Color(hex: "#CD7800")
    /// `theme.list.itemDisclosureActions.neutral1` — 0x666666
    static let neutral = Color(hex: "#666666")
    /// `badgeFillColor` при акценте — 0xEB5545
    static let badge = Color(hex: "#EB5545")
    /// `theme.chatList.reactionBadgeActiveBackgroundColor` — 0xFF2D55
    static let reaction = Color(hex: "#FF2D55")
    /// `theme.chatList.messageDraftTextColor` — 0xDD4B39
    static let draft = Color(hex: "#DD4B39")
    /// `theme.chatList.secretIconColor` — 0x00B12C
    static let secret = Color(hex: "#00B12C")
    /// `theme.list.itemSwitchColors.contentColor` — 0x67CE67 (зелёный включатель Telegram)
    static let switchOn = Color(hex: "#67CE67")
    /// `theme.list.itemSwitchColors.frameColor` — 0x39393D
    static let switchFrame = Color(hex: "#39393D")

    // MARK: - Панель ввода (theme.chat.inputPanel)

    /// Панель ввода поверх обоев — полупрозрачная тёмная (0x141414)
    static let inputPanel = Color(hex: "#141414").opacity(0.92)
    /// `inputPanel.inputBackgroundColor` — 0xffffff @ 0.14
    static let inputField = Color.white.opacity(0.14)
    /// `inputPanel.inputStrokeColor` — 0xffffff @ 0.10
    static let inputStroke = Color.white.opacity(0.10)
    /// `inputPanel.inputPlaceholderColor` — 0xffffff @ 0.48
    static let inputPlaceholder = Color.white.opacity(0.48)
    /// `inputPanel.panelSeparatorColor` — 0x545458 @ 0.55
    static let inputSeparator = Color(hex: "#545458").opacity(0.55)
    /// `contextMenu.backgroundColor` — 0x252525 @ 0.78
    static let contextMenu = Color(hex: "#252525").opacity(0.78)

    // MARK: - Метрики

    /// Радиус скругления блоков списка в Telegram — 10 pt.
    static let corner: CGFloat = 10
    /// Радиус пузыря сообщения — 17 pt.
    static let bubbleCorner: CGFloat = 17
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

/// Обои переписки ночной темы Telegram.
///
/// Telegram строит их из `defaultDarkWallpaperGradientColors`
/// (`0x598BF6, 0x7A5EEF, 0xD67CFF, 0xF38B58`) с интенсивностью -34,
/// то есть затемнённым градиентом поверх почти чёрной основы.
struct ChatWallpaper: View {
    var body: some View {
        ZStack {
            Color(hex: "#04070B")

            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#598BF6").opacity(0.20), location: 0.00),
                    .init(color: Color(hex: "#7A5EEF").opacity(0.17), location: 0.34),
                    .init(color: Color(hex: "#D67CFF").opacity(0.13), location: 0.68),
                    .init(color: Color(hex: "#F38B58").opacity(0.10), location: 1.00),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(hex: "#598BF6").opacity(0.16), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}