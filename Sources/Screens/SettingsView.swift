import SwiftUI

/// РќР°СЃС‚СЂРѕР№РєРё: РїСЂРѕС„РёР»СЊ, РґР°РЅРЅС‹Рµ, Р·РІС‘Р·РґС‹, РїР°РїРєРё, РѕС„РѕСЂРјР»РµРЅРёРµ.
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

                Section("РђРєРєР°СѓРЅС‚") {
                    NavigationLink(value: Route.profile) {
                        SettingsRow(icon: "person.fill", title: "РџСЂРѕС„РёР»СЊ", tint: Theme.accent)
                    }
                    .listRowBackground(Theme.panel)

                    NavigationLink(value: Route.ledger) {
                        SettingsRow(icon: "star.fill", title: "РњРѕРё Р·РІС‘Р·РґС‹", value: Format.number(env.stars), tint: Theme.star)
                    }
                    .listRowBackground(Theme.panel)

                    NavigationLink(value: Route.folders) {
                        SettingsRow(icon: "folder.fill", title: "РџР°РїРєРё СЃ С‡Р°С‚Р°РјРё", value: "\(env.snapshot.folders.count)", tint: Theme.accentBright)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section("РћС„РѕСЂРјР»РµРЅРёРµ Рё СѓРІРµРґРѕРјР»РµРЅРёСЏ") {
                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.notificationsEnabled },
                        set: { value in env.updateSettings { $0.notificationsEnabled = value } }
                    )) {
                        Label("РЈРІРµРґРѕРјР»РµРЅРёСЏ", systemImage: "bell.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)

                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.soundsEnabled },
                        set: { value in env.updateSettings { $0.soundsEnabled = value } }
                    )) {
                        Label("Р—РІСѓРєРё", systemImage: "speaker.wave.2.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Р Р°Р·РјРµСЂ С‚РµРєСЃС‚Р°", systemImage: "textformat.size")
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

                Section("РџСЂРёРІР°С‚РЅРѕСЃС‚СЊ") {
                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.showLastSeen },
                        set: { value in env.updateSettings { $0.showLastSeen = value } }
                    )) {
                        Label("РџРѕРєР°Р·С‹РІР°С‚СЊ РІСЂРµРјСЏ РІ СЃРµС‚Рё", systemImage: "clock.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)

                    Toggle(isOn: Binding(
                        get: { env.snapshot.settings.readReceipts },
                        set: { value in env.updateSettings { $0.readReceipts = value } }
                    )) {
                        Label("РћС‚С‡С‘С‚С‹ Рѕ РїСЂРѕС‡С‚РµРЅРёРё", systemImage: "checkmark.message.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.panel)
                }

                Section("Р”Р°РЅРЅС‹Рµ") {
                    NavigationLink(value: Route.data) {
                        SettingsRow(icon: "internaldrive.fill", title: "РҐСЂР°РЅРёР»РёС‰Рµ", value: env.storageDescription, tint: Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section {
                    Button(role: .destructive) {
                        showReset = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("РЎР±СЂРѕСЃРёС‚СЊ Р°РєРєР°СѓРЅС‚")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Theme.panel)
                } footer: {
                    Text("EndoGram СЂР°Р±РѕС‚Р°РµС‚ РѕС„Р»Р°Р№РЅ. РЎРµСЂРІРµСЂС‹ Telegram Рё СЃРѕР±СЃС‚РІРµРЅРЅС‹Рµ СЃРµСЂРІРµСЂС‹ РЅРµ РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Section {
                    HStack {
                        Text("Р’РµСЂСЃРёСЏ")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("1.0.0 В· РѕС„Р»Р°Р№РЅ")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("РќР°СЃС‚СЂРѕР№РєРё")
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
        .alert("РЎР±СЂРѕСЃРёС‚СЊ Р°РєРєР°СѓРЅС‚?", isPresented: $showReset) {
            Button("РЎР±СЂРѕСЃРёС‚СЊ", role: .destructive) { env.resetAccount() }
            Button("РћС‚РјРµРЅР°", role: .cancel) {}
        } message: {
            Text("Р’СЃРµ С‡Р°С‚С‹, СЃРѕРѕР±С‰РµРЅРёСЏ, РїРѕРґР°СЂРєРё Рё NFT Р±СѓРґСѓС‚ СѓРґР°Р»РµРЅС‹. Р‘СѓРґРµС‚ СЃРѕР·РґР°РЅ РЅРѕРІС‹Р№ Р»РѕРєР°Р»СЊРЅС‹Р№ Р°РєРєР°СѓРЅС‚ СЃ 1 000 000 Р·РІС‘Р·Рґ.")
        }
    }
}

/// Р РµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ РїСЂРѕС„РёР»СЏ.
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
                        field("РРјСЏ", text: $name)
                        field("РРјСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ", text: $username)
                        field("Рћ СЃРµР±Рµ", text: $bio)
                    }
                    .padding(.horizontal, 16)

                    Button {
                        env.updateProfile(displayName: name, username: username, bio: bio)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                    } label: {
                        Text(saved ? "РЎРѕС…СЂР°РЅРµРЅРѕ" : "РЎРѕС…СЂР°РЅРёС‚СЊ")
                    }
                    .buttonStyle(StarButtonStyle())
                    .padding(.horizontal, 16)

                    SectionCard(title: "РђРєРєР°СѓРЅС‚") {
                        SettingsRow(icon: "number", title: "ID", value: String(env.profile.id.suffix(8)), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "calendar", title: "РЎРѕР·РґР°РЅ", value: Format.fullDate(env.profile.createdAt), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "crown.fill", title: "Premium", value: env.profile.premiumActive ? "Р°РєС‚РёРІРµРЅ" : "РЅРµС‚", tint: Theme.star, showsChevron: false)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("РџСЂРѕС„РёР»СЊ")
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

/// РџР°РїРєРё СЃ С‡Р°С‚Р°РјРё.
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
                    SectionCard(title: "РЎРёСЃС‚РµРјРЅС‹Рµ") {
                        ForEach(env.snapshot.folders.filter(\.isSystem)) { folder in
                            SettingsRow(icon: folder.icon, title: folder.title, value: "\(env.chats(for: folder).count) С‡Р°С‚РѕРІ", showsChevron: false)
                            if folder.id != env.snapshot.folders.filter(\.isSystem).last?.id {
                                DividerLine()
                            }
                        }
                    }

                    if !env.nonSystemFolders.isEmpty {
                        SectionCard(title: "РњРѕРё РїР°РїРєРё") {
                            ForEach(env.nonSystemFolders) { folder in
                                SettingsRow(icon: folder.icon, title: folder.title, value: "\(folder.chatIds.count)", showsChevron: false)
                                DividerLine()
                            }
                        }
                    }

                    Button { showCreate = true } label: {
                        Label("РЎРѕР·РґР°С‚СЊ РїР°РїРєСѓ", systemImage: "plus")
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
        .navigationTitle("РџР°РїРєРё")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 14) {
                            TextField("РќР°Р·РІР°РЅРёРµ РїР°РїРєРё", text: $title)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.panel))
                                .padding(.horizontal, 16)

                            SectionCard(title: "Р§Р°С‚С‹ РІ РїР°РїРєРµ") {
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
                                Text("РЎРѕР·РґР°С‚СЊ")
                            }
                            .buttonStyle(StarButtonStyle())
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 12)
                    }
                }
                .navigationTitle("РќРѕРІР°СЏ РїР°РїРєР°")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("РћС‚РјРµРЅР°") { showCreate = false }
                    }
                }
                .toolbarBackground(Theme.panel, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
    }
}

/// РҐСЂР°РЅРёР»РёС‰Рµ: РіРґРµ Р»РµР¶Р°С‚ РґР°РЅРЅС‹Рµ Рё СЃРєРѕР»СЊРєРѕ Р·Р°РЅРёРјР°СЋС‚.
struct StorageView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showClear = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "Р›РѕРєР°Р»СЊРЅС‹Рµ РґР°РЅРЅС‹Рµ") {
                        SettingsRow(icon: "internaldrive.fill", title: "Р Р°Р·РјРµСЂ Р±Р°Р·С‹", value: env.storageDescription, tint: Theme.accent, showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "bubble.left.fill", title: "РЎРѕРѕР±С‰РµРЅРёР№", value: "\(env.snapshot.messages.count)", tint: Theme.accentBright, showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "folder.fill", title: "Р§Р°С‚РѕРІ", value: "\(env.snapshot.chats.count)", tint: Color(hex: "#4DCD5E"), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "gift.fill", title: "РџРѕРґР°СЂРєРѕРІ", value: "\(env.snapshot.ownedGifts.count)", tint: Color(hex: "#E4572E"), showsChevron: false)
                        DividerLine()
                        SettingsRow(icon: "sparkles", title: "NFT", value: "\(env.snapshot.ownedNFTs.count)", tint: Color(hex: "#7C5CFF"), showsChevron: false)
                    }

                    Text("Р”Р°РЅРЅС‹Рµ С…СЂР°РЅСЏС‚СЃСЏ РІ С„Р°Р№Р»Рµ \(AppConfig.storageFile) РІРЅСѓС‚СЂРё РїСЂРёР»РѕР¶РµРЅРёСЏ Рё РЅРµ РїРµСЂРµРґР°СЋС‚СЃСЏ РЅРёРєСѓРґР°.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("РҐСЂР°РЅРёР»РёС‰Рµ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

/// Рћ РїСЂРёР»РѕР¶РµРЅРёРё.
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
                Text("Р­С‚Р°Рї 1 В· РїРѕР»РЅРѕСЃС‚СЊСЋ РѕС„Р»Р°Р№РЅ")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                Text("РђРєРєР°СѓРЅС‚ СЃРѕР·РґР°С‘С‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РїСЂРё РїРµСЂРІРѕРј Р·Р°РїСѓСЃРєРµ. Р§Р°С‚С‹, РїРѕРґР°СЂРєРё, NFT Рё Premium С…СЂР°РЅСЏС‚СЃСЏ РЅР° СѓСЃС‚СЂРѕР№СЃС‚РІРµ. РЎРµС‚СЊ РЅРµ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 6)
                Spacer()
            }
            .padding(.top, 50)
        }
        .navigationTitle("Рћ РїСЂРёР»РѕР¶РµРЅРёРё")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

