import SwiftUI
import UIKit

/// Глобальный «хром» приложения — перенесён из ночной темы Telegram.
///
/// Значения взяты из `DefaultDarkPresentationTheme.swift` и соседних файлов
/// `TelegramPresentationData`, имя поля темы указано рядом:
/// `theme.rootNavigationBar` — `blurredBackgroundColor` 0x1D1D1D @0.9,
/// `separatorColor` 0x545458 @0.55; `theme.rootController.tabBar` — тот же фон
/// и разделитель; `theme.list.itemSwitchColors` — 0x67CE67 / 0x39393D;
/// `theme.list.segmentedControl` — 0xFFFFFF @0.11.
///
/// Настраивается один раз при старте, поэтому все экраны выглядят одинаково
/// и не переопределяют панели по одному.
enum Chrome {

    // MARK: - Токены ночной темы

    /// #1D1D1D — `blurredBackgroundColor` навигационной панели.
    static let barBackground = UIColor(red: 0.1137, green: 0.1137, blue: 0.1137, alpha: 0.94)
    /// #545458 @0.55 — `separatorColor` панелей.
    static let barSeparator = UIColor(red: 0.3294, green: 0.3294, blue: 0.3451, alpha: 0.55)
    /// #3E88F7 — акцент `defaultDarkColorPresentationTheme`.
    static let accent = UIColor(red: 0.2431, green: 0.5333, blue: 0.9686, alpha: 1)
    /// #8D8E93 — неактивный элемент таббара / `sectionHeaderTextColor`.
    static let inactive = UIColor(red: 0.5529, green: 0.5569, blue: 0.5765, alpha: 1)
    /// #EB5545 — `badgeFillColor`.
    static let badge = UIColor(red: 0.9216, green: 0.3333, blue: 0.2706, alpha: 1)
    /// #67CE67 — `itemSwitchColors.contentColor` (включённый переключатель).
    static let switchOn = UIColor(red: 0.4039, green: 0.8078, blue: 0.4039, alpha: 1)
    /// #39393D — `itemSwitchColors.frameColor`.
    static let switchFrame = UIColor(red: 0.2235, green: 0.2235, blue: 0.2392, alpha: 1)
    /// #000000 — `list.blocksBackgroundColor`.
    static let background = UIColor.black
    /// #1C1C1D — `list.itemBlocksBackgroundColor`.
    static let panel = UIColor(red: 0.1098, green: 0.1098, blue: 0.1137, alpha: 1)
    /// #1C1C1D — `pinnedItemBackgroundColor` (закреплённые чаты).
    static let pinned = UIColor(red: 0.1098, green: 0.1098, blue: 0.1137, alpha: 1)
    /// #313135 — `itemHighlightedBackgroundColor`.
    static let hover = UIColor(red: 0.1922, green: 0.1922, blue: 0.2078, alpha: 1)
    /// #272728 — `chatList.regularSearchBarColor`.
    static let searchBar = UIColor(red: 0.1529, green: 0.1529, blue: 0.1569, alpha: 1)

    // MARK: - Точка входа

    static func configure() {
        configureNavigationBar()
        configureTabBar()
        configureControls()
        configureLists()
    }

    // MARK: - Навигационные панели

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        // configureWithDefaultBackground оставляет блюр содержимого под панелью —
        // именно так выглядит панель Telegram поверх списка чатов.
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = barBackground
        appearance.shadowColor = barSeparator
        // `rootNavigationBar` в Telegram: заголовок 17 pt semibold, белый.
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
        ]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.compactAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactScrollEdgeAppearance = appearance
        bar.tintColor = accent
        bar.prefersLargeTitles = false

        // Кнопка «назад»: шеврон и подпись акцентом, как в оригинале.
        let backButton = UIBarButtonItemAppearance(style: .plain)
        backButton.normal.titleTextAttributes = [.foregroundColor: accent]
        backButton.highlighted.titleTextAttributes = [.foregroundColor: accent.withAlphaComponent(0.6)]
        appearance.buttonAppearance = backButton
        appearance.backButtonAppearance = backButton
        appearance.doneButtonAppearance = backButton
    }

    // MARK: - Таббар

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        // Панель вкладок в Telegram непрозрачная и с блюром по краю.
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.1137, green: 0.1137, blue: 0.1137, alpha: 0.94)
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        appearance.shadowColor = barSeparator

        configure(itemAppearance: appearance.stackedLayoutAppearance)
        configure(itemAppearance: appearance.inlineLayoutAppearance)
        configure(itemAppearance: appearance.compactInlineLayoutAppearance)

        let bar = UITabBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.tintColor = accent
        bar.unselectedItemTintColor = inactive
    }

    private static func configure(itemAppearance item: UITabBarItemAppearance) {
        item.normal.iconColor = inactive
        item.normal.titleTextAttributes = [
            .foregroundColor: inactive,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
        ]
        item.selected.iconColor = accent
        item.selected.titleTextAttributes = [
            .foregroundColor: accent,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
        ]
        // Значок непрочитанных: badgeBackgroundColor живёт на состоянии
        // элемента, а не на UITabBarItemAppearance (проверено — иначе падает).
        item.normal.badgeBackgroundColor = badge
        item.normal.badgeTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
        ]
    }

    // MARK: - Системные контролы

    private static func configureControls() {
        // `itemSwitchColors` — зелёный включатель Telegram, а не системный.
        UISwitch.appearance().onTintColor = switchOn

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(white: 1, alpha: 0.18)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(white: 1, alpha: 0.7)], for: .normal
        )

        // Курсор в полях ввода — акцентом, как в Telegram.
        UITextField.appearance().tintColor = accent
        UITextView.appearance().tintColor = accent
    }

    // MARK: - Списки

    private static func configureLists() {
        UITableView.appearance().backgroundColor = background
        UITableView.appearance().separatorColor = barSeparator
        UICollectionView.appearance().backgroundColor = background
    }
}

extension Notification.Name {
    /// Отправляется после настройки внешнего вида — для экранов, которым нужно
    /// перечитать тему (например, превью таббара).
    static let endoChromeConfigured = Notification.Name("endoChromeConfigured")
}

// MARK: - HUD-компоненты

/// Строка списка с подсветкой при нажатии — как `itemHighlightedBackgroundColor`
/// в Telegram: цвет меняется только под пальцем, без «прыжков» layout.
struct TelegramPressable<Content: View>: View {
    private let content: Content
    private let action: () -> Void
    private var cornerRadius: CGFloat = 0
    @State private var isPressed = false

    init(cornerRadius: CGFloat = 0,
         action: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isPressed ? Theme.hover : Color.clear)
            )
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(.easeOut(duration: 0.08)) { isPressed = true }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.12)) { isPressed = false }
                    }
            )
            .onTapGesture { action() }
    }
}

/// Переключатель в стиле Telegram: зелёный `itemSwitchColors.contentColor`.
struct TelegramSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer(minLength: 8)
            Toggle("", isOn: configuration.$isOn)
                .labelsHidden()
                .tint(Theme.switchOn)
        }
    }
}

/// Тонкий индикатор загрузки — как `activityIndicator` в списках Telegram.
struct TelegramActivityIndicator: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Theme.textSecondary)
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
                .textInputAutocapitalization(.never)
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

/// Подпись под блоком — `theme.list.footerTextColor`, 13 pt, вторичный.
struct TelegramSectionFooter: View {
    let text: String
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Theme.textSecondary)
            .multilineTextAlignment(alignment)
            .padding(.horizontal, 16)
            .padding(.top, 6)
    }
}