import SwiftUI

extension View {
    /// Контекстное меню, которое включается по условию.
    ///
    /// Нужно для режима выбора сообщений: пока он активен, долгое нажатие
    /// не должно открывать меню действий — как в Telegram.
    @ViewBuilder
    func contextMenuIf<MenuItems: View>(_ condition: Bool,
                                        @ViewBuilder menuItems: () -> MenuItems) -> some View {
        if condition {
            self.contextMenu(menuItems: menuItems)
        } else {
            self
        }
    }
}

/// Круглый аватар с инициалами — как заглушки Telegram.
struct AvatarView: View {
    let title: String
    let colorHex: String
    var size: CGFloat = 52
    var online: Bool = false

    private var initials: String {
        let parts = title.split(separator: " ").prefix(2)
        if parts.isEmpty { return "?" }
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: colorHex), Color(hex: colorHex).opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.white)
                )
            if online {
                Circle()
                    .fill(Theme.online)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay(Circle().stroke(Theme.panel, lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Счётчик непрочитанных.
struct UnreadBadge: View {
    let count: Int
    var muted: Bool = false

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(muted ? .black : .white)
                .padding(.horizontal, count > 9 ? 6 : 7)
                .padding(.vertical, 3)
                .background(
                    // theme.chatList.unreadBadge*BackgroundColor
                    Capsule().fill(muted ? Theme.neutral : Theme.accent)
                )
        }
    }
}

/// Кнопка со «звёздным» акцентом.
struct StarButtonStyle: ButtonStyle {
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(filled ? .white : Theme.accentBright)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filled ? Theme.accent : Theme.accent.opacity(0.15))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

/// Карточка раздела.
struct SectionCard<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
            }
            VStack(spacing: 0) { content }
                .background(Theme.panel)
                .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                .padding(.horizontal, 12)
        }
    }
}

/// Строка списка с иконкой, заголовком и значением.
struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var tint: Color = Theme.accentBright
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint))
            Text(title)
                .foregroundColor(Theme.textPrimary)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .foregroundColor(Theme.textListItemSecondary)
                    .lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.disclosure)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

struct DividerLine: View {
    /// Отступ слева — как в оригинале, разделитель начинается за аватаром/иконкой.
    var inset: CGFloat = 56

    var body: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

/// Блок сведений в стиле Telegram: скруглённый фон `list.itemBlocksBackgroundColor`
/// и строки, разделённые волосяной линией.
struct TelegramBlock<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.panel)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}

/// Пустой экран с подсказкой.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.textSecondary)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
