import SwiftUI

/// Поиск по настройкам — как `SettingsSearchableItems` в Telegram-iOS.
///
/// Каждая запись ведёт на реальный экран настроек, поэтому поиск не создаёт
/// «мёртвых» пунктов: всё, что находится, действительно открывается офлайн.
struct SettingsSearchEntry: Identifiable, Hashable {
    let id: String
    /// Название пункта, как он называется в Telegram.
    let title: String
    /// Экран, на который ведёт пункт, — заголовок раздела.
    let section: String
    let route: SettingsView.Route
    /// Дополнительные слова для поиска: синонимы и подписи из Telegram.
    let keywords: String

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return false }
        return title.lowercased().contains(needle)
            || section.lowercased().contains(needle)
            || keywords.lowercased().contains(needle)
    }
}

enum SettingsSearchIndex {

    /// Полный перечень пунктов настроек приложения.
    static let all: [SettingsSearchEntry] = [
        // Профиль
        entry("profile.name", "Имя и фамилия", "Профиль", .profile, "имя фамилия профиль name last name"),
        entry("profile.username", "Имя пользователя", "Профиль", .profile, "username ник ссылка"),
        entry("profile.bio", "О себе", "Профиль", .profile, "bio описание о себе"),
        entry("profile.phone", "Номер телефона", "Профиль", .profile, "телефон номер phone"),
        entry("profile.photo", "Фото профиля", "Профиль", .profile, "аватар фото профиля"),
        entry("profile.logout", "Выйти из аккаунта", "Профиль", .profile, "выход logout reset сброс"),

        // Основные
        entry("saved", "Избранное", "Избранное", .saved, "избранное saved messages заметки"),
        entry("stories", "Мои истории", "Мои истории", .stories, "истории stories"),
        entry("stars", "Мои звёзды", "Мои звёзды", .stars, "звёзды баланс stars баланс пополнить"),
        entry("premium", "Telegram Premium", "Telegram Premium", .premium,
              "премиум подписка premium"),
        entry("notifications", "Уведомления и звуки", "Основные", .notifications,
              "уведомления звук вибрация пуши notifications sound"),
        entry("privacy", "Конфиденциальность", "Основные", .privacy,
              "приватность безопасность конфиденциальность privacy security"),
        entry("privacy.phone", "Кто видит номер телефона", "Основные", .privacy,
              "номер телефона phone number видимость"),
        entry("privacy.activity", "Время захода", "Основные", .privacy,
              "последняя активность время захода last seen"),
        entry("privacy.photo", "Фото профиля — кто видит", "Основные", .privacy,
              "фото профиля profile photo видимость"),
        entry("privacy.bio", "О себе — кто видит", "Основные", .privacy,
              "био bio видимость"),
        entry("privacy.birthday", "Дата рождения — кто видит", "Основные", .privacy,
              "день рождения дата рождения birthday"),
        entry("privacy.calls", "Кто может звонить", "Основные", .privacy,
              "звонки calls кто может"),
        entry("privacy.forward", "Ссылка на аккаунт при пересылке", "Основные", .privacy,
              "пересылка forward ссылка"),
        entry("privacy.groups", "Кто может добавлять в группы", "Основные", .privacy,
              "группы groups добавление"),
        entry("privacy.gifts", "Подарки — кто видит", "Основные", .privacy,
              "подарки gifts видимость"),
        entry("privacy.music", "Сохранённая музыка — кто видит", "Основные", .privacy,
              "музыка music видимость"),
        entry("privacy.voice", "Голосовые сообщения — кто видит", "Основные", .privacy,
              "голосовые voice видимость"),
        entry("privacy.blocked", "Заблокированные пользователи", "Основные", .blocked,
              "чёрный список блокировка blocked blacklist"),
        entry("privacy.password", "Облачный пароль", "Основные", .privacy,
              "пароль двухфакторная аутентификация password 2fa"),
        entry("privacy.sessions", "Активные сеансы", "Основные", .privacy,
              "сеансы сессии sessions устройства"),
        entry("privacy.autoDelete", "Автоудаление сообщений", "Основные", .privacy,
              "автоудаление таймер self destruct"),
        entry("privacy.autoArchive", "Автоархив новых чатов", "Основные", .privacy,
              "автоархив archive"),
        entry("data", "Данные и память", "Основные", .data,
              "данные память трафик data storage"),
        entry("data.autoDownload", "Автозагрузка медиа", "Основные", .data,
              "автозагрузка скачивание media auto download"),
        entry("data.storage", "Использование памяти", "Основные", .data,
              "память хранилище storage кэш"),
        entry("folders", "Папки с чатами", "Основные", .folders,
              "папки фильтры folders"),
        entry("devices", "Устройства", "Основные", .devices,
              "устройства сеансы devices"),
        entry("language", "Язык", "Основные", .language,
              "язык language русский"),
        entry("stickers", "Стикеры и эмодзи", "Основные", .stickers,
              "стикеры эмодзи маски stickers emoji"),
        entry("appearance", "Оформление", "Основные", .appearance,
              "оформление тема обои шрифт appearance theme wallpaper"),
        entry("appearance.theme", "Тема", "Основные", .appearance,
              "тема ночная дневная theme night"),
        entry("appearance.textSize", "Размер текста", "Основные", .appearance,
              "размер текста шрифт text size"),
        entry("appearance.animations", "Анимации", "Основные", .appearance,
              "анимации эффекты animations"),

        // Сеть
        entry("energy", "Энергосбережение", "Сеть", .energy,
              "энергосбережение батарея battery energy"),
        entry("proxy", "Прокси", "Сеть", .proxy,
              "прокси proxy соединение"),

        // Прочее
        entry("about", "О приложении", "Помощь", .about,
              "о приложении версия about version"),
        entry("reset", "Сбросить аккаунт", "Помощь", .about,
              "сброс удалить аккаунт reset"),
    ]

    private static func entry(_ id: String, _ title: String, _ section: String,
                              _ route: SettingsView.Route, _ keywords: String) -> SettingsSearchEntry {
        SettingsSearchEntry(id: id, title: title, section: section, route: route, keywords: keywords)
    }

    static func results(for query: String) -> [SettingsSearchEntry] {
        all.filter { $0.matches(query) }
    }
}

/// Список результатов поиска по настройкам.
struct SettingsSearchResults: View {
    let query: String

    private var results: [SettingsSearchEntry] { SettingsSearchIndex.results(for: query) }

    private var grouped: [(section: String, items: [SettingsSearchEntry])] {
        var order: [String] = []
        var buckets: [String: [SettingsSearchEntry]] = [:]
        for item in results {
            if buckets[item.section] == nil {
                order.append(item.section)
                buckets[item.section] = []
            }
            buckets[item.section]?.append(item)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    var body: some View {
        List {
            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(Theme.textSecondary)
                    Text("Ничего не найдено")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text("Попробуйте другое слово, например «звонки» или «память».")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(grouped, id: \.section) { group in
                Section(group.section) {
                    ForEach(group.items) { item in
                        NavigationLink(value: item.route) {
                            HStack(spacing: 12) {
                                Image(systemName: icon(for: item.route))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 29, height: 29)
                                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(tint(for: item.route)))
                                Text(item.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer(minLength: 6)
                            }
                        }
                        .listRowBackground(Theme.panel)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
    }

    private func icon(for route: SettingsView.Route) -> String {
        switch route {
        case .profile:       return "person.fill"
        case .stars:         return "star.fill"
        case .premium:       return "crown.fill"
        case .notifications: return "bell.fill"
        case .privacy:       return "lock.fill"
        case .data:          return "internaldrive.fill"
        case .folders:       return "folder.fill"
        case .devices:       return "laptopcomputer"
        case .language:      return "globe"
        case .stickers:      return "face.smiling.fill"
        case .appearance:    return "paintpalette.fill"
        case .about:         return "info.circle.fill"
        case .energy:        return "battery.100.bolt"
        case .proxy:         return "network"
        case .blocked:       return "hand.raised.fill"
        case .saved:         return "bookmark.fill"
        case .stories:       return "circle.dashed"
        }
    }

    private func tint(for route: SettingsView.Route) -> Color {
        switch route {
        case .profile, .privacy, .language, .energy: return Theme.accent
        case .stars, .premium:                       return Theme.star
        case .notifications, .blocked:               return Theme.danger
        case .data:                                  return Theme.success
        case .folders, .stickers:                    return Theme.warning
        case .appearance:                            return Color(hex: Palette.purple)
        default:                                     return Theme.neutral
        }
    }
}
