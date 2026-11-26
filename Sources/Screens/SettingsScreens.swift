import SwiftUI

// MARK: - Общие элементы экранов настроек

extension View {
    /// Список в стиле Telegram: фон #000000, блоки #1C1C1D.
    func telegramList() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func telegramNavTitle(_ title: String, large: Bool = false) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(large ? .large : .inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

/// Строка-переключатель как `theme.list.itemSwitchColors` (зелёный включатель).
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var tint: Color = Theme.accent
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint))
            Toggle(isOn: $isOn) {
                Text(title).foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.switchOn)
        }
        .padding(.vertical, 2)
    }
}

/// Строка с выбором значения через меню.
struct SettingsPickerRow: View {
    let icon: String
    let title: String
    let options: [(String, String)]
    @Binding var selection: String
    var tint: Color = Theme.accent

    private var currentTitle: String {
        options.first(where: { $0.0 == selection })?.1 ?? selection
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint))
            Menu {
                ForEach(options, id: \.0) { option in
                    Button {
                        selection = option.0
                    } label: {
                        if option.0 == selection {
                            Label(option.1, systemImage: "checkmark")
                        } else {
                            Text(option.1)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(title).foregroundColor(Theme.textPrimary)
                    Spacer(minLength: 8)
                    Text(currentTitle)
                        .foregroundColor(Theme.textListItemSecondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.disclosure)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Профиль

struct ProfileView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var saved = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    VStack(spacing: 12) {
                        AvatarView(title: name.isEmpty ? env.profile.displayName : name,
                                   colorHex: env.profile.avatarColor, size: 96)
                        Text("Изменить фото профиля")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .listRowBackground(Theme.panel)

                Section {
                    field("Имя", text: $name)
                    field("О себе", text: $bio)
                    field("Имя пользователя", text: $username)
                } footer: {
                    Text("Имя пользователя можно использовать для упоминания вас в чатах.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    HStack {
                        Text("Мой ID").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(String(env.profile.id)).foregroundColor(Theme.textListItemSecondary)
                            .font(.system(size: 14, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    HStack {
                        Text("Аккаунт создан").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(Format.fullDate(env.profile.createdAt)).foregroundColor(Theme.textListItemSecondary)
                    }
                    HStack {
                        Text("Telegram Premium").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(env.profile.premiumActive ? "Активен" : "Нет")
                            .foregroundColor(env.profile.premiumActive ? Theme.star : Theme.textListItemSecondary)
                    }
                } footer: {
                    Text("Локальный аккаунт создан автоматически при первом запуске. Номер телефона не запрашивается.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Изменить профиль")
        .onAppear {
            name = env.profile.displayName
            username = env.profile.username
            bio = env.profile.bio
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(saved ? "Сохранено" : "Готово") {
                    env.updateProfile(displayName: name, username: username, bio: bio)
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                }
                .font(.system(size: 16, weight: .semibold))
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            TextField(title, text: text)
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Мои звёзды

struct MyStarsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 46))
                            .foregroundColor(Theme.star)
                        Text(Format.number(env.stars))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("тестовых звёзд на балансе")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .listRowBackground(Theme.panel)

                Section {
                    NavigationLink { LedgerView().environmentObject(env) } label: {
                        SettingsRow(icon: "clock.arrow.circlepath", title: "История операций",
                                    value: "\(env.ledger.count)", tint: Theme.accent)
                    }
                    NavigationLink { InventoryView().environmentObject(env) } label: {
                        SettingsRow(icon: "gift.fill", title: "Подарки",
                                    value: "\(env.snapshot.ownedGifts.count)", tint: Theme.danger)
                    }
                    NavigationLink { InventoryView().environmentObject(env) } label: {
                        SettingsRow(icon: "sparkles", title: "NFT",
                                    value: "\(env.snapshot.ownedNFTs.count)", tint: Color(hex: Palette.purple))
                    }
                }
                .listRowBackground(Theme.panel)

                Section {
                    Text("Звёзды тестовые: они существуют только в локальном хранилище приложения и не имеют отношения к настоящим звёздам Telegram.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .listRowBackground(Theme.panel)
                }
            }
            .telegramList()
        }
        .telegramNavTitle("Мои звёзды")
    }
}

// MARK: - Уведомления и звуки

struct NotificationsSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    SettingsToggleRow(icon: "bell.fill", title: "Уведомления", tint: Theme.danger,
                                      isOn: bind(\.notificationsEnabled))
                    SettingsToggleRow(icon: "speaker.wave.2.fill", title: "Звуки", tint: Theme.warning,
                                      isOn: bind(\.soundsEnabled))
                    SettingsToggleRow(icon: "eye.fill", title: "Предпросмотр сообщений", tint: Theme.accent,
                                      isOn: bind(\.messagePreview))
                } footer: {
                    Text("Уведомления локальные: других устройств и серверов нет, поэтому приходят только уведомления этого приложения.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section("Чаты") {
                    SettingsToggleRow(icon: "bubble.left.fill", title: "Личные чаты", tint: Theme.accent,
                                      isOn: bind(\.privateChatNotifications))
                    SettingsToggleRow(icon: "person.3.fill", title: "Группы", tint: Theme.success,
                                      isOn: bind(\.groupNotifications))
                    SettingsToggleRow(icon: "megaphone.fill", title: "Каналы", tint: Theme.warning,
                                      isOn: bind(\.channelNotifications))
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Уведомления и звуки")
    }

    private func bind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }
}

// MARK: - Конфиденциальность

struct PrivacySettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    private let visibilityOptions: [(String, String)] = [
        ("everybody", "Все"),
        ("contacts", "Мои контакты"),
        ("nobody", "Никто"),
    ]

    private let autoDeleteOptions: [(String, String)] = [
        ("off", "Выключено"),
        ("day", "1 день"),
        ("week", "1 неделя"),
        ("month", "1 месяц"),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section("Кто видит") {
                    SettingsPickerRow(icon: "clock.fill", title: "Время в сети",
                                      options: visibilityOptions, selection: stringBind(\.lastSeenVisibility))
                    SettingsPickerRow(icon: "person.crop.square.fill", title: "Фото профиля",
                                      options: visibilityOptions, selection: stringBind(\.profilePhotoVisibility))
                    SettingsPickerRow(icon: "phone.fill", title: "Номер телефона",
                                      options: visibilityOptions, selection: stringBind(\.phoneVisibility))
                    SettingsPickerRow(icon: "arrowshape.turn.up.right.fill", title: "Пересылка сообщений",
                                      options: visibilityOptions, selection: stringBind(\.forwardsVisibility))
                    SettingsPickerRow(icon: "info.circle.fill", title: "Био",
                                      options: visibilityOptions, selection: stringBind(\.bioVisibility))
                    SettingsPickerRow(icon: "birthday.cake.fill", title: "День рождения",
                                      options: visibilityOptions, selection: stringBind(\.birthdayVisibility))
                    SettingsPickerRow(icon: "gift.fill", title: "Подарки",
                                      options: visibilityOptions, selection: stringBind(\.giftsVisibility))
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsPickerRow(icon: "bubble.left.fill", title: "Сообщения",
                                      options: visibilityOptions, selection: stringBind(\.messagesVisibility))
                    SettingsPickerRow(icon: "phone.arrow.up.right.fill", title: "Звонки",
                                      options: visibilityOptions, selection: stringBind(\.callsVisibility))
                    SettingsPickerRow(icon: "person.3.fill", title: "Группы и каналы",
                                      options: visibilityOptions, selection: stringBind(\.groupsVisibility))
                    SettingsPickerRow(icon: "music.note", title: "Сохранённая музыка",
                                      options: visibilityOptions, selection: stringBind(\.savedMusicVisibility))
                    SettingsPickerRow(icon: "mic.fill", title: "Голосовые сообщения",
                                      options: visibilityOptions, selection: stringBind(\.voiceMessagesVisibility))
                } header: {
                    Text("Кто может")
                } footer: {
                    Text("В офлайн-режиме рядом нет других людей: эти правила сохранены для совместимости с Telegram и вступят в силу при подключении сервера EndoGram.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsToggleRow(icon: "checkmark.message.fill", title: "Отчёты о прочтении",
                                      tint: Theme.success, isOn: boolBind(\.readReceipts))
                    SettingsToggleRow(icon: "person.crop.circle.badge.questionmark", title: "Показывать время в сети",
                                      tint: Theme.accent, isOn: boolBind(\.showLastSeen))
                    SettingsToggleRow(icon: "lock.shield.fill", title: "Код-пароль",
                                      tint: Theme.warning, isOn: boolBind(\.passcodeEnabled))
                    SettingsToggleRow(icon: "eye.trianglebadge.exclamationmark.fill", title: "Чувствительный контент",
                                      tint: Theme.danger, isOn: boolBind(\.sensitiveContent))
                    SettingsToggleRow(icon: "archivebox.fill", title: "Автоархив новых чатов",
                                      tint: Theme.neutral, isOn: boolBind(\.autoArchiveEnabled))
                } footer: {
                    Text("Код-пароль и ограничения действуют только внутри приложения: данные и так лежат в песочнице iOS.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsPickerRow(icon: "timer", title: "Автоудаление сообщений",
                                      options: autoDeleteOptions, selection: stringBind(\.autoDeleteMessages),
                                      tint: Theme.neutral)
                } footer: {
                    Text("Автоудаление применяется к новым сообщениям в локальных чатах.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    NavigationLink(value: SettingsView.Route.blocked) {
                        SettingsRow(icon: "hand.raised.fill", title: "Заблокированные пользователи",
                                    value: "\(env.snapshot.contacts.count) локальных", tint: Theme.danger,
                                    showsChevron: true)
                    }
                } footer: {
                    Text("Блокировка действует только внутри приложения: заблокированный контакт исчезает из списка, но сообщения ему и так не отправляются.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsValueRow(title: "Облачный пароль", value: "не задан")
                    SettingsValueRow(title: "Активные сеансы", value: "1")
                } footer: {
                    Text("Облачный пароль и сеансы — серверные функции Telegram. В офлайн-режиме они недоступны; все данные защищены песочницей iOS.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Конфиденциальность")
    }

    private func boolBind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }

    private func stringBind(_ keyPath: WritableKeyPath<AppSettings, String>) -> Binding<String> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }
}

// MARK: - Данные и память

struct DataAndStorageSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    private let keepMediaOptions: [(String, String)] = [
        ("week", "1 неделя"),
        ("month", "1 месяц"),
        ("forever", "Навсегда"),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    NavigationLink { StorageView().environmentObject(env) } label: {
                        SettingsRow(icon: "internaldrive.fill", title: "Использование памяти",
                                    value: env.storageDescription, tint: Theme.success)
                    }
                    SettingsPickerRow(icon: "clock.fill", title: "Хранить медиа",
                                      options: keepMediaOptions, selection: keepMediaBinding,
                                      tint: Theme.neutral)
                }
                .listRowBackground(Theme.panel)

                Section("Автозагрузка медиа") {
                    SettingsToggleRow(icon: "wifi", title: "Через Wi-Fi", tint: Theme.accent,
                                      isOn: boolBind(\.autoDownloadWiFi))
                    SettingsToggleRow(icon: "antenna.radiowaves.left.and.right", title: "Через мобильную сеть",
                                      tint: Theme.warning, isOn: boolBind(\.autoDownloadCellular))
                    SettingsToggleRow(icon: "arrow.counterclockwise", title: "Сброс настроек автозагрузки",
                                      tint: Theme.danger, isOn: boolBind(\.autoDownloadReset))
                    SettingsToggleRow(icon: "photo.fill", title: "Сохранять входящие фото",
                                      tint: Theme.success, isOn: boolBind(\.saveIncomingPhotos))
                    SettingsToggleRow(icon: "wand.and.stars", title: "Сохранять изменённые фото",
                                      tint: Color(hex: Palette.purple), isOn: boolBind(\.saveEditedPhotos))
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsToggleRow(icon: "phone.arrow.down.left.fill", title: "Экономить трафик в звонках",
                                      tint: Theme.accent, isOn: boolBind(\.dataSaverCalls))
                    SettingsToggleRow(icon: "ear.fill", title: "Поднимать для прослушивания",
                                      tint: Theme.warning, isOn: boolBind(\.raiseToListen))
                    SettingsToggleRow(icon: "music.note", title: "Пауза музыки при записи",
                                      tint: Color(hex: Palette.pink), isOn: boolBind(\.pauseMusicOnRecording))
                } header: {
                    Text("Звонки и медиа")
                } footer: {
                    Text("Сеть приложением не используется: настройки автозагрузки влияют только на локальное поведение.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Данные и память")
    }

    private var keepMediaBinding: Binding<String> {
        Binding(
            get: { env.snapshot.settings.keepMedia },
            set: { value in env.updateSettings { $0.keepMedia = value } }
        )
    }

    private func boolBind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }
}

// MARK: - Хранилище

struct StorageView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    SettingsRow(icon: "internaldrive.fill", title: "Размер базы",
                                value: env.storageDescription, tint: Theme.accent, showsChevron: false)
                    SettingsRow(icon: "bubble.left.fill", title: "Сообщений",
                                value: "\(env.snapshot.messages.count)", tint: Theme.success, showsChevron: false)
                    SettingsRow(icon: "folder.fill", title: "Чатов",
                                value: "\(env.snapshot.chats.count)", tint: Theme.warning, showsChevron: false)
                    SettingsRow(icon: "gift.fill", title: "Подарков",
                                value: "\(env.snapshot.ownedGifts.count)", tint: Theme.danger, showsChevron: false)
                    SettingsRow(icon: "sparkles", title: "NFT",
                                value: "\(env.snapshot.ownedNFTs.count)", tint: Color(hex: Palette.purple), showsChevron: false)
                    SettingsRow(icon: "phone.fill", title: "Звонков",
                                value: "\(env.snapshot.calls.count)", tint: Theme.accent, showsChevron: false)
                }
                .listRowBackground(Theme.panel)

                Section {
                    Text("Данные хранятся в файле \(AppConfig.storageFile) внутри приложения и никуда не передаются.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Использование памяти")
    }
}

// MARK: - Папки с чатами

struct FoldersView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showCreate = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    ForEach(env.snapshot.folders.sorted { $0.title < $1.title }) { folder in
                        HStack(spacing: 12) {
                            Image(systemName: folder.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.accent))
                            Text(folder.title).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(env.chats(for: folder).count)")
                                .foregroundColor(Theme.textListItemSecondary)
                        }
                    }
                } header: {
                    Text("Папки")
                } footer: {
                    Text("Папки меняют только то, какие чаты видны на вкладке «Чаты». Чаты не перемещаются.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsToggleRow(icon: "number", title: "Показывать теги папок",
                                      tint: Theme.neutral,
                                      isOn: Binding(
                                        get: { env.snapshot.settings.folderTags },
                                        set: { value in env.updateSettings { $0.folderTags = value } }
                                      ))
                    Button { showCreate = true } label: {
                        SettingsRow(icon: "plus", title: "Создать папку", tint: Theme.success)
                    }
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Папки с чатами")
        .sheet(isPresented: $showCreate) {
            NewFolderSheet().environmentObject(env)
        }
    }
}

struct NewFolderSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selected = Set<String>()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        TextField("Название папки", text: $title)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .listRowBackground(Theme.panel)

                    Section("Включённые чаты") {
                        ForEach(env.sorted(env.snapshot.chats)) { chat in
                            Button {
                                if selected.contains(chat.id) { selected.remove(chat.id) }
                                else { selected.insert(chat.id) }
                            } label: {
                                HStack(spacing: 10) {
                                    AvatarView(title: chat.title, colorHex: chat.avatarColor, size: 34)
                                    Text(chat.title).foregroundColor(Theme.textPrimary).lineLimit(1)
                                    Spacer()
                                    Image(systemName: selected.contains(chat.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selected.contains(chat.id) ? Theme.accent : Theme.disclosure)
                                }
                            }
                        }
                    }
                    .listRowBackground(Theme.panel)
                }
                .telegramList()
            }
            .telegramNavTitle("Новая папка")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") {
                        let name = title.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        env.createFolder(title: name, icon: "folder.fill", chatIds: Array(selected))
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Устройства

struct DevicesSettingsView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.accent))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Это устройство").foregroundColor(Theme.textPrimary)
                            Text("Текущий сеанс · активен").font(.system(size: 12))
                                .foregroundColor(Theme.success)
                        }
                        Spacer()
                    }
                } header: {
                    Text("Активные сеансы")
                } footer: {
                    Text("EndoGram не подключается к сети, поэтому список устройств ограничен этим iPhone. Другие сеансы появиться не могут.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    HStack {
                        Text("Завершить другие сеансы").foregroundColor(Theme.textDisabled)
                        Spacer()
                    }
                } footer: {
                    Text("Недоступно: активных сеансов, кроме текущего, нет.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Устройства")
    }
}

// MARK: - Язык

struct LanguageSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    HStack {
                        Text("Русский").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark").foregroundColor(Theme.accent)
                    }
                    HStack {
                        Text("English").foregroundColor(Theme.textDisabled)
                        Spacer()
                        Text("недоступно").font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                    }
                } header: {
                    Text("Язык интерфейса")
                } footer: {
                    Text("Интерфейс локализован на русский. Переключение языка появится вместе с сервером EndoGram — сейчас языковых пакетов нет.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsToggleRow(icon: "character.bubble.fill", title: "Переводить сообщения",
                                      tint: Theme.accent,
                                      isOn: Binding(
                                        get: { env.snapshot.settings.translationsEnabled },
                                        set: { value in env.updateSettings { $0.translationsEnabled = value } }
                                      ))
                    SettingsToggleRow(icon: "text.bubble.fill", title: "Переводить весь чат",
                                      tint: Theme.neutral,
                                      isOn: Binding(
                                        get: { env.snapshot.settings.translateEntireChats },
                                        set: { value in env.updateSettings { $0.translateEntireChats = value } }
                                      ))
                } footer: {
                    Text("Перевод выполняется только при наличии сети, поэтому в офлайн-режиме не работает.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Язык")
    }
}

// MARK: - Стикеры и эмодзи

struct StickersSettingsView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    HStack {
                        Text("Установленные наборы").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("0").foregroundColor(Theme.textListItemSecondary)
                    }
                    HStack {
                        Text("Архивные наборы").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("0").foregroundColor(Theme.textListItemSecondary)
                    }
                    HStack {
                        Text("Избранные стикеры").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("0").foregroundColor(Theme.textListItemSecondary)
                    }
                } header: {
                    Text("Стикеры")
                } footer: {
                    Text("Наборы стикеров не загружены: каталог стикеров приходит с сервера, а приложение работает офлайн.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    HStack {
                        Text("Маска для больших эмодзи").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .tint(Theme.switchOn)
                            .disabled(true)
                    }
                } footer: {
                    Text("Настройка появится вместе с поддержкой анимированных эмодзи.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Стикеры и эмодзи")
    }
}

// MARK: - Оформление

struct AppearanceSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    private let nightOptions: [(String, String)] = [
        ("off", "Выключена"),
        ("automatic", "Автоматически"),
        ("scheduled", "По расписанию"),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    HStack {
                        Text("Тёмная тема").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("Ночная · Telegram").foregroundColor(Theme.textListItemSecondary)
                    }
                    SettingsPickerRow(icon: "moon.stars.fill", title: "Автоночная тема",
                                      options: nightOptions, selection: nightBinding,
                                      tint: Color(hex: Palette.purple))
                } header: {
                    Text("Тема")
                } footer: {
                    Text("Палитра перенесена из официального клиента Telegram (ночная тема): фон #000000, блоки #1C1C1D, акцент #3E88F7.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section("Текст и пузыри") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Размер текста").foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(Int(env.snapshot.settings.fontSize)) pt")
                                .foregroundColor(Theme.textListItemSecondary)
                        }
                        Slider(value: Binding(
                            get: { env.snapshot.settings.fontSize },
                            set: { value in env.updateSettings { $0.fontSize = value } }
                        ), in: 13...23, step: 1)
                        .tint(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Уголки пузырей").foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(Int(env.snapshot.settings.bubbleCorners)) pt")
                                .foregroundColor(Theme.textListItemSecondary)
                        }
                        Slider(value: Binding(
                            get: { env.snapshot.settings.bubbleCorners },
                            set: { value in env.updateSettings { $0.bubbleCorners = value } }
                        ), in: 6...20, step: 1)
                        .tint(Theme.accent)
                    }
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsToggleRow(icon: "sparkles", title: "Анимации",
                                      tint: Theme.accent, isOn: boolBind(\.animationsEnabled))
                    SettingsToggleRow(icon: "photo.on.rectangle", title: "Следующее медиа по тапу",
                                      tint: Theme.success, isOn: boolBind(\.showNextMediaOnTap))
                    SettingsToggleRow(icon: "keyboard.fill", title: "Отправка по Enter",
                                      tint: Theme.neutral, isOn: boolBind(\.sendWithEnter))
                }
                .listRowBackground(Theme.panel)

                Section {
                    HStack {
                        Text("Обои чата").foregroundColor(Theme.textPrimary)
                        Spacer()
                        ChatWallpaper()
                            .frame(width: 44, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                } footer: {
                    Text("Обои собраны из defaultDarkWallpaperGradientColors ночной темы Telegram.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsValueRow(title: "Текущая тема", value: "Ночная · Telegram")
                    SettingsValueRow(title: "Иконка приложения", value: "по умолчанию")
                } header: {
                    Text("Темы")
                } footer: {
                    Text("Редактор своих тем и смена иконки — функции полноценного клиента Telegram. В офлайн-сборке доступна ночная тема, перенесённая из оригинала по токенам.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Оформление")
    }

    private var nightBinding: Binding<String> {
        Binding(
            get: { env.snapshot.settings.autoNightTheme },
            set: { value in env.updateSettings { $0.autoNightTheme = value } }
        )
    }

    private func boolBind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }
}

// MARK: - О приложении

struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accent)
                        Text(AppConfig.appName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Этап 1 · полностью офлайн")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Theme.panel)

                Section {
                    Text("Аккаунт создаётся автоматически при первом запуске: без номера телефона, SMS и экранов входа. Чаты, подарки, NFT, Premium и история звёзд хранятся на устройстве. Сеть не используется.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textPrimary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    HStack {
                        Text("Версия").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(AppConfig.appVersion).foregroundColor(Theme.textListItemSecondary)
                    }
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("О приложении")
    }
}

// MARK: - Энергосбережение

/// «Энергосбережение» — раздел оригинала `EnergySavingSettings`.
struct EnergySavingView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    SettingsToggleRow(icon: "battery.100.bolt", title: "Экономия заряда",
                                      tint: Theme.success, isOn: boolBind(\.energySavingEnabled))
                } footer: {
                    Text("Когда заряд низкий, приложение отключает тяжёлые эффекты и автозагрузку — так же, как в Telegram.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsToggleRow(icon: "arrow.down.circle.fill", title: "Отключить автозагрузку",
                                      tint: Theme.accent, isOn: boolBind(\.energySavingAutoDownload))
                    SettingsToggleRow(icon: "sparkles", title: "Отключить анимации",
                                      tint: Color(hex: Palette.purple), isOn: animationsBinding)
                } header: {
                    Text("При низком заряде")
                } footer: {
                    Text("Отключение анимаций применяется сразу ко всему интерфейсу.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Энергосбережение")
    }

    /// «Отключить анимации» — обратное к настройке «Анимации» из «Оформления».
    private var animationsBinding: Binding<Bool> {
        Binding(
            get: { !env.snapshot.settings.animationsEnabled },
            set: { value in env.updateSettings { $0.animationsEnabled = !value } }
        )
    }

    private func boolBind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }
}

// MARK: - Прокси

/// «Прокси» — раздел оригинала `ProxySettings`. Сеть приложением не используется,
/// поэтому включение честно помечено как нерабочее.
struct ProxySettingsView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    SettingsToggleRow(icon: "network", title: "Использовать прокси",
                                      tint: Theme.accent, isOn: boolBind(\.proxyEnabled))
                } footer: {
                    Text("Прокси не влияет ни на что: EndoGram не делает сетевых запросов. Переключатель сохранён для совместимости с будущим сервером EndoGram.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.textDisabled)
                        Text("Добавить прокси")
                            .foregroundColor(Theme.textDisabled)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                } footer: {
                    Text("Добавить прокси нельзя: в офлайн-режиме подключение к прокси-серверу невозможно.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)

                Section {
                    SettingsValueRow(title: "Тип", value: "SOCKS5")
                } header: {
                    Text("Соединение")
                } footer: {
                    Text("Настройки соединения появятся вместе с сервером EndoGram.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.panel)
            }
            .telegramList()
        }
        .telegramNavTitle("Прокси")
    }

    private func boolBind(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { env.snapshot.settings[keyPath: keyPath] },
            set: { value in env.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }
}

/// Строка «подпись → значение» в стиле Telegram.
struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundColor(Theme.textPrimary)
            Spacer()
            Text(value).foregroundColor(Theme.textListItemSecondary)
        }
    }
}

// MARK: - Избранное

/// «Избранное» — чат с самим собой (Saved Messages в Telegram).
/// Перенаправляет в обычный экран переписки на личном чате-хранилище.
struct SavedMessagesView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var chat: Chat?

    var body: some View {
        Group {
            if let chat {
                ChatDetailView(chatId: chat.id).environmentObject(env)
            } else {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ProgressView().tint(Theme.accent)
                }
            }
        }
        .onAppear {
            if chat == nil { chat = env.savedMessagesChat() }
        }
    }
}

// MARK: - Заблокированные пользователи

/// «Заблокированные пользователи» — раздел оригинала `BlockedUsersController`.
/// Список локальный: блокировка скрывает контакт из адресной книги приложения.
struct BlockedUsersView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var blocked = Set<String>()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                if env.snapshot.contacts.isEmpty {
                    Section {
                        Text("Контактов нет")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                } else {
                    Section {
                        ForEach(env.snapshot.contacts) { contact in
                            Button {
                                if blocked.contains(contact.id) {
                                    blocked.remove(contact.id)
                                } else {
                                    blocked.insert(contact.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 40)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(contact.displayName)
                                            .foregroundColor(Theme.textPrimary)
                                        Text(blocked.contains(contact.id) ? "заблокирован" : "@" + contact.username)
                                            .font(.system(size: 13))
                                            .foregroundColor(blocked.contains(contact.id) ? Theme.danger : Theme.textSecondary)
                                    }
                                    Spacer()
                                    if blocked.contains(contact.id) {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(Theme.danger)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.panel)
                        }
                    } header: {
                        Text("Нажмите, чтобы заблокировать или разблокировать")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    } footer: {
                        Text("Блокировка хранится только на этом устройстве и не отправляется никуда: в офлайн-режиме сообщения и так не доставляются.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .telegramList()
        }
        .telegramNavTitle("Заблокированные")
    }
}