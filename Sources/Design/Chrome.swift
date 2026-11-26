import SwiftUI
import UIKit

/// Глобальный «хром» приложения: навигационные панели, таббар, поиск.
///
/// Значения взяты из ночной темы Telegram:
/// `theme.rootNavigationBar` — `blurredBackgroundColor` 0x1D1D1D @0.9 и
/// `separatorColor` 0x545458 @0.55; `theme.rootController.tabBar` — тот же фон
/// и разделитель. Применяется один раз при старте, поэтому все экраны выглядят
/// одинаково и не переопределяют панель по одному.
enum Chrome {

    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }

    /// #1D1D1D
    private static let barBackground = UIColor(red: 0.1137, green: 0.1137, blue: 0.1137, alpha: 0.94)
    /// #545458 @0.55
    private static let barSeparator = UIColor(red: 0.3294, green: 0.3294, blue: 0.3451, alpha: 0.55)
    /// #3E88F7 — акцент ночной темы
    private static let accent = UIColor(red: 0.2431, green: 0.5333, blue: 0.9686, alpha: 1)
    /// #8D8E93 — неактивный элемент таббара
    private static let inactive = UIColor(red: 0.5529, green: 0.5569, blue: 0.5765, alpha: 1)
    /// #EB5545 — значок на иконке
    private static let badge = UIColor(red: 0.9216, green: 0.3333, blue: 0.2706, alpha: 1)

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        // configureWithDefaultBackground даёт блюр содержимого под панелью.
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = barBackground
        appearance.shadowColor = barSeparator
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.compactAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactScrollEdgeAppearance = appearance
        bar.tintColor = accent
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.1137, green: 0.1137, blue: 0.1137, alpha: 1)
        appearance.shadowColor = barSeparator

        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = inactive
        item.normal.titleTextAttributes = [.foregroundColor: inactive]
        item.selected.iconColor = accent
        item.selected.titleTextAttributes = [.foregroundColor: accent]
        // Значок непрочитанных: badgeBackgroundColor/badgeTextAttributes
        // объявлены на состоянии элемента, а не на UITabBarItemAppearance.
        item.normal.badgeBackgroundColor = badge
        item.normal.badgeTextAttributes = [.foregroundColor: UIColor.white]

        // Компактная раскладка (iPhone в портрете) использует тот же набор.
        appearance.compactInlineLayoutAppearance.normal.iconColor = inactive
        appearance.compactInlineLayoutAppearance.selected.iconColor = accent

        let bar = UITabBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
    }
}

/// Строка поиска как `theme.chatList.regularSearchBarColor` — 0x272728.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding? = nil
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            field
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Очистить")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.searchBar)
        )
    }

    @ViewBuilder
    private var field: some View {
        if let focused {
            TextField(placeholder, text: $text).focused(focused)
        } else {
            TextField(placeholder, text: $text)
        }
    }
}

/// Заголовок секции списка: 13 pt, вторичный цвет, без капса —
/// как `theme.list.sectionHeaderTextColor` (0x8D8E93).
struct TelegramSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13))
            .foregroundColor(Theme.textSecondary)
            .textCase(nil)
    }
}