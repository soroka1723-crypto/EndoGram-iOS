import SwiftUI

/// Настройки — корневой экран. Структура разделов повторяет Telegram
/// (инвентарь взят из submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift):
/// профиль → Избранное / Звёзды / Premium → Основные → Помощь → выход.
struct SettingsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showReset = false
    @State private var helpSheet: HelpTopic?

    enum Route: Hashable {
        case profile, stars, premium, notifications, privacy, data
        case folders, devices, language, stickers, appearance, ledger, about
    }

    enum HelpTopic: String, Identifiable {
        case question, faq, policy
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                profileSection
                primarySection
                generalSection
                helpSection
                dangerSection
                versionSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .profile:      ProfileView().environmentObject(env)
            case .stars:        StarsView().environmentObject(env)
            case .premium:      PremiumView().environmentObject(env)
            case .notifications: NotificationsSettingsView().environmentObject(env)
            case .privacy:      PrivacySettingsView().environmentObject(env)
            case .data:         DataAndStorageSettingsView().environmentObject(env)
            case .folders:      FoldersView().environmentObject(env)
            case .devices:      DevicesSettingsView()
            case .language:     LanguageSettingsView().environmentObject(env)
            case .stickers:     StickersSettingsView()
            case .appearance:   AppearanceSettingsView().environmentObject(env)
            case .ledger:       LedgerView().environmentObject(env)
            case .about:        AboutView()
            }
        }
        .sheet(item: $helpSheet) { topic in
            HelpSheet(topic: topic)
        }
        .alert("Сбросить аккаунт?", isPresented: $showReset) {
            Button("Сбросить", role: .destructive) { env.resetAccount() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все чаты, сообщения, подарки и NFT будут удалены. Будет создан новый локальный аккаунт с 1 000 000 звёзд.")
        }
    }

    // MARK: - Секции

    private var profileSection: some View {
        Section {
            NavigationLink(value: Route.profile) {
                HStack(spacing: 14) {
                    AvatarView(title: env.profile.displayName, colorHex: env.profile.avatarColor, size: 62)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(env.profile.displayName)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("@" + env.profile.username)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                        if env.profile.premiumActive {
                            Text("Telegram Premium")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.star)
                        }
                    }
                    Spacer(minLength: 6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.disclosure)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Theme.panel)
        }
    }

    private var primarySection: some View {
        Section {
            NavigationLink(value: Route.ledger) {
                SettingsRow(icon: "bookmark.fill", title: "Избранное", tint: Theme.accent)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.stars) {
                SettingsRow(icon: "star.fill", title: "Мои звёзды",
                            value: Format.number(env.stars), tint: Theme.star)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.premium) {
                SettingsRow(icon: "crown.fill", title: "Telegram Premium",
                            value: env.profile.premiumActive ? "Активен" : nil, tint: Theme.star)
            }
            .listRowBackground(Theme.panel)
        }
    }

    private var generalSection: some View {
        Section("Основные") {
            NavigationLink(value: Route.notifications) {
                SettingsRow(icon: "bell.fill", title: "Уведомления и звуки", tint: Theme.danger)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.privacy) {
                SettingsRow(icon: "lock.fill", title: "Конфиденциальность", tint: Theme.accent)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.data) {
                SettingsRow(icon: "internaldrive.fill", title: "Данные и память",
                            value: env.storageDescription, tint: Theme.success)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.folders) {
                SettingsRow(icon: "folder.fill", title: "Папки с чатами",
                            value: "\(env.nonSystemFolders.count)", tint: Theme.warning)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.devices) {
                SettingsRow(icon: "laptopcomputer", title: "Устройства", tint: Theme.neutral)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.language) {
                SettingsRow(icon: "globe", title: "Язык", value: "Русский", tint: Theme.accent)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.stickers) {
                SettingsRow(icon: "face.smiling.fill", title: "Стикеры и эмодзи", tint: Theme.warning)
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.appearance) {
                SettingsRow(icon: "paintpalette.fill", title: "Оформление", tint: Color(hex: Palette.purple))
            }
            .listRowBackground(Theme.panel)
        }
    }

    private var helpSection: some View {
        Section("Помощь") {
            Button { helpSheet = .question } label: {
                SettingsRow(icon: "questionmark.circle.fill", title: "Задать вопрос", tint: Theme.accent)
            }
            .listRowBackground(Theme.panel)

            Button { helpSheet = .faq } label: {
                SettingsRow(icon: "text.book.closed.fill", title: "Telegram FAQ", tint: Theme.accent)
            }
            .listRowBackground(Theme.panel)

            Button { helpSheet = .policy } label: {
                SettingsRow(icon: "hand.raised.fill", title: "Политика конфиденциальности", tint: Theme.neutral)
            }
            .listRowBackground(Theme.panel)
        }
    }

    private var dangerSection: some View {
        Section {
            Button { showReset = true } label: {
                HStack {
                    Spacer()
                    Text("Сбросить аккаунт").foregroundColor(Theme.danger)
                    Spacer()
                }
            }
            .listRowBackground(Theme.panel)

            NavigationLink(value: Route.about) {
                SettingsRow(icon: "info.circle.fill", title: "О приложении", tint: Theme.neutral)
            }
            .listRowBackground(Theme.panel)
        } footer: {
            Text("EndoGram работает офлайн: серверы Telegram и собственные серверы не используются, данные хранятся на устройстве.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var versionSection: some View {
        Section {
            HStack {
                Text("Версия").foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(AppConfig.appVersion) · офлайн").foregroundColor(Theme.textListItemSecondary)
            }
            .listRowBackground(Theme.panel)
        }
    }
}

// MARK: - Помощь

struct HelpSheet: View {
    let topic: SettingsView.HelpTopic
    @Environment(\.dismiss) private var dismiss

    private var title: String {
        switch topic {
        case .question: return "Задать вопрос"
        case .faq:      return "Telegram FAQ"
        case .policy:   return "Политика конфиденциальности"
        }
    }

    private var text: String {
        switch topic {
        case .question:
            return """
            Это локальная тестовая сборка EndoGram. Она не подключена к Telegram, поэтому вопрос некуда отправить: сетевых запросов приложение не делает.

            Всё, что здесь происходит, — локальные действия на этом устройстве.
            """
        case .faq:
            return """
            EndoGram — офлайн-клон Telegram для тестирования интерфейса.

            • Аккаунт создаётся автоматически при первом запуске, без номера и кодов.
            • Стартовый баланс — 1 000 000 тестовых звёзд.
            • Чаты, подарки, NFT, Premium и история операций хранятся в файле на устройстве.
            • Собеседники не отвечают: это локальные записи, а не реальные люди.
            """
        case .policy:
            return """
            Приложение не собирает и не передаёт данные: у него нет сетевого доступа к каким-либо сервисам.

            Вся информация — профиль, чаты, сообщения, подарки, NFT и баланс звёзд — записывается только в локальное хранилище приложения на этом устройстве и удаляется вместе с приложением.
            """
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}