import SwiftUI

/// Настройки: профиль, данные, звёзды, папки, оформление.
struct SettingsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showReset = false

    enum Route: Hashable {
        case profile, folders, data, about, ledger
    }

    var body: some View {
        ZStack {
            Theme.panel.ignoresSafeArea()
            List {
                Section {
                    NavigationLink(value: Route.profile) {
                        HStack(spacing: 14) {
                            AvatarView(title: env.profile.displayName, colorHex: env.profile.avatarColor, size: 62)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(env.profile.displayName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("@" + env.profile.username)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                                if env.profile.premiumActive {
                                    Text("Premium")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Theme.star)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.textSecondary.opacity(0.7))
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section("Аккаунт") {
                    NavigationLink(value: Route.profile) {
                        SettingsRow(icon: "person.fill", title: "Профиль", tint: Theme.accent)
                    }
                    .listRowBackground(Theme.panel)

                    NavigationLink(value: Route.ledger) {
                        SettingsRow(icon: "star.fill", title: "Мои звёзды", value: Format.number(env.stars), tint: Theme.star)
                    }
                    .listRowBackground(Theme.panel)

                    NavigationLink(value: Route.folders) {
                        SettingsRow(icon: "folder.fill", title: "Папки с чатами", value: "\(env.snapshot.folders.count)", tint: Theme.accentBright)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section("Оформление и уведомления") {
                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.notificationsEnabled },
                        set: { value in env.updateSettings { $0.notificationsEnabled = value } }
                    )) {
                        Label("Уведомления", systemImage: "bell.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)

                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.soundsEnabled },
                        set: { value in env.updateSettings { $0.soundsEnabled = value } }
                    )) {
                        Label("Звуки", systemImage: "speaker.wave.2.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Размер текста", systemImage: "textformat.size")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(Int(env.snapshot.settings.fontSize)) pt")
                                .foregroundColor(Theme.textSecondary)
                        }
                        Slider(
                            value: Binding(
                                get: { env.snapshot.settings.fontSize },
                                set: { value in env.updateSettings { $0.fontSize = value } }
                            ),
                            in: 13...23,
                            step: 1
                        )
                        .tint(Theme.accent)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section("Приватность") {
                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.showLastSeen },
                        set: { value in env.updateSettings { $0.showLastSeen = value } }
                    )) {
                        Label("Показывать время в сети", systemImage: "clock.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)

                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.readReceipts },
                        set: { value in env.updateSettings { $0.readReceipts = value } }
                    )) {
                        Label("Отчёты о прочтении", systemImage: "checkmark.message.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)
                }

                Section("Данные") {
                    NavigationLink(value: Route.data) {
                        SettingsRow(icon: "internaldrive.fill", title: "Хранилище", value: env.storageDescription, tint: Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section {
                    Button(role: .destructive) {
                        showReset = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Сбросить аккаунт")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Theme.panel)
                } footer: {
                    Text("EndoGram работает офлайн. Серверы Telegram и собственные серверы не используются.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Section {
                    HStack {
                        Text("Версия")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("1.0.0 · офлайн")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.panel, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .profile: ProfileView().environmentObject(env)
            case .folders: FoldersView().environmentObject(env)
            case .data: StorageView().environmentObject(env)
            case .about: AboutView()
            case .ledger: LedgerView().environmentObject(env)
            }
        }
        .alert("Сбросить аккаунт?", isPresented: $showReset) {
            Button("Сбросить", role: .destructive) { env.resetAccount() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все чаты, сообщения, подарки и NFT будут удалены. Будет создан новый локальный аккаунт с 1 000 000 звёзд.")
        }
    }
}

/// Редактирование профиля.
struct ProfileView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var saved = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    AvatarView(title: name.isEmpty ? env.profile.displayName : name, colorHex: env.profile.avatarColor, size: 96)
                        .padding(.top, 20)

                    VStack(spacing: 12) {
                        field("Имя", text: $name)
                        field("Имя пользователя", text: $username)
                        field("О себе", text: $bio)
                    }
                    .padding(.horizontal, 16)

                    Button {
                        env.updateProfile(displayName: name, username: username, bio: bio)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                    } label: {
                        Text(saved ? "Сохранено" : "Сохранить")
                    }
                    .buttonStyle(StarButtonStyle())
                    .padding(.horizontal, 16)

                    SectionCard(title: "Аккаунт") {
                        SettingsRow(icon: "number", title: "ID", value: String(env.profile.id.suffix(8)), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "calendar", title: "Создан", value: Format.fullDate(env.profile.createdAt), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "crown.fill", title: "Premium", value: env.profile.premiumActive ? "активен" : "нет", tint: Theme.star, showsChevron: false)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            name = env.profile.displayName
            username = env.profile.username
            bio = env.profile.bio
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            TextField(title, text: text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.panel))
        }
    }
}

/// Папки с чатами.
struct FoldersView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showCreate = false
    @State private var title = ""
    @State private var selected = Set<String>()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "Системные") {
                        ForEach(env.snapshot.folders.filter(\.isSystem)) { folder in
                            SettingsRow(icon: folder.icon, title: folder.title, value: "\(env.chats(for: folder).count) чатов", showsChevron: false)
                            if folder.id != env.snapshot.folders.filter(\.isSystem).last?.id {
                                DividerLine()
                            }
                        }
                    }

                    if !env.nonSystemFolders.isEmpty {
                        SectionCard(title: "Мои папки") {
                            ForEach(env.nonSystemFolders) { folder in
                                SettingsRow(icon: folder.icon, title: folder.title, value: "\(folder.chatIds.count)", showsChevron: false)
                                DividerLine()
                            }
                        }
                    }

                    Button { showCreate = true } label: {
                        Label("Создать папку", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Папки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 14) {
                            TextField("Название папки", text: $title)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.panel))
                                .padding(.horizontal, 16)

                            SectionCard(title: "Чаты в папке") {
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
                                                .foregroundColor(selected.contains(chat.id) ? Theme.accentBright : Theme.textSecondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                    if chat.id != env.sorted(env.snapshot.chats).last?.id { DividerLine() }
                                }
                            }

                            Button {
                                let name = title.trimmingCharacters(in: .whitespaces)
                                guard !name.isEmpty else { return }
                                env.createFolder(title: name, icon: "folder.fill", chatIds: Array(selected))
                                title = ""
                                selected = []
                                showCreate = false
                            } label: {
                                Text("Создать")
                            }
                            .buttonStyle(StarButtonStyle())
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 12)
                    }
                }
                .navigationTitle("Новая папка")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Отмена") { showCreate = false }
                    }
                }
                .toolbarBackground(Theme.panel, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
    }
}

/// Хранилище: где лежат данные и сколько занимают.
struct StorageView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showClear = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "Локальные данные") {
                        SettingsRow(icon: "internaldrive.fill", title: "Размер базы", value: env.storageDescription, tint: Theme.accent, showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "bubble.left.fill", title: "Сообщений", value: "\(env.snapshot.messages.count)", tint: Theme.accentBright, showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "folder.fill", title: "Чатов", value: "\(env.snapshot.chats.count)", tint: Theme.green, showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "gift.fill", title: "Подарков", value: "\(env.snapshot.ownedGifts.count)", tint: Color(hex: "#E4572E"), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "sparkles", title: "NFT", value: "\(env.snapshot.ownedNFTs.count)", tint: Color(hex: "#7C5CFF"), showsChevron: false)
                    }

                    Text("Данные хранятся в файле \(AppConfig.storageFile) внутри приложения и не передаются никуда.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Хранилище")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

/// О приложении.
struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Theme.accentBright)
                Text("EndoGram")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("Этап 1 · полностью офлайн")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                Text("Аккаунт создаётся автоматически при первом запуске. Чаты, подарки, NFT и Premium хранятся на устройстве. Сеть не используется.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 6)
                Spacer()
            }
            .padding(.top, 50)
        }
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
