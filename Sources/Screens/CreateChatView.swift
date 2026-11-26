import SwiftUI

/// РЎРѕР·РґР°РЅРёРµ Р»РёС‡РЅРѕРіРѕ С‡Р°С‚Р°, РіСЂСѓРїРїС‹ РёР»Рё РєР°РЅР°Р»Р°.
struct CreateChatView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable {
        case direct = "Р§Р°С‚"
        case group = "Р“СЂСѓРїРїР°"
        case channel = "РљР°РЅР°Р»"
    }

    @State private var mode: Mode = .direct
    @State private var title = ""
    @State private var about = ""
    @State private var selected = Set<String>()
    @State private var newContactName = ""
    @State private var showNewContact = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("РўРёРї", selection: $mode) {
                            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        if mode != .direct {
                            VStack(spacing: 10) {
                                TextField(mode == .group ? "РќР°Р·РІР°РЅРёРµ РіСЂСѓРїРїС‹" : "РќР°Р·РІР°РЅРёРµ РєР°РЅР°Р»Р°", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.panel))
                                if mode == .channel {
                                    TextField("РћРїРёСЃР°РЅРёРµ РєР°РЅР°Р»Р°", text: $about, axis: .vertical)
                                        .lineLimit(2...4)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.panel))
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if mode != .channel {
                            contactPicker
                        }

                        if let error {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.danger)
                                .padding(.horizontal, 16)
                        }

                        Button(action: create) {
                            Text(createTitle)
                        }
                        .buttonStyle(StarButtonStyle())
                        .padding(.horizontal, 16)
                        .disabled(!canCreate)

                        Text("Р’СЃС‘ СЃРѕР·РґР°С‘С‚СЃСЏ Р»РѕРєР°Р»СЊРЅРѕ: СЌС‚Рѕ С‚РµСЃС‚РѕРІС‹Р№ СЂРµР¶РёРј Р±РµР· СЃРµСЂРІРµСЂРѕРІ Рё Р±РµР· СЂРµР°Р»СЊРЅС‹С… СЃРѕР±РµСЃРµРґРЅРёРєРѕРІ.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("РќРѕРІРѕРµ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("РћС‚РјРµРЅР°") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("РќРѕРІС‹Р№ РєРѕРЅС‚Р°РєС‚", isPresented: $showNewContact) {
                TextField("РРјСЏ", text: $newContactName)
                Button("РЎРѕР·РґР°С‚СЊ") {
                    let name = newContactName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let contact = env.addContact(displayName: name, username: "")
                    newContactName = ""
                    if mode == .direct {
                        let chat = env.openDirectChat(with: contact)
                        dismiss()
                        _ = chat
                    } else {
                        selected.insert(contact.id)
                    }
                }
                Button("РћС‚РјРµРЅР°", role: .cancel) { newContactName = "" }
            } message: {
                Text("РљРѕРЅС‚Р°РєС‚ СЃСѓС‰РµСЃС‚РІСѓРµС‚ С‚РѕР»СЊРєРѕ РЅР° СЌС‚РѕРј СѓСЃС‚СЂРѕР№СЃС‚РІРµ.")
            }
        }
    }

    private var contactPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mode == .group ? "РЈС‡Р°СЃС‚РЅРёРєРё" : "РљРѕРјСѓ РЅР°РїРёСЃР°С‚СЊ")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 16)

            if env.snapshot.contacts.isEmpty {
                Text("РљРѕРЅС‚Р°РєС‚РѕРІ РїРѕРєР° РЅРµС‚ вЂ” РґРѕР±Р°РІСЊС‚Рµ РєРЅРѕРїРєРѕР№ СЃРІРµСЂС…Сѓ.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(env.snapshot.contacts) { contact in
                        Button {
                            if mode == .direct {
                                let chat = env.openDirectChat(with: contact)
                                dismiss()
                                _ = chat
                            } else if selected.contains(contact.id) {
                                selected.remove(contact.id)
                            } else {
                                selected.insert(contact.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 40)
                                Text(contact.displayName)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                if selected.contains(contact.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accentBright)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        if contact.id != env.snapshot.contacts.last?.id {
                            DividerLine()
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.panel))
                .padding(.horizontal, 16)
            }
        }
    }

    private var canCreate: Bool {
        switch mode {
        case .direct: return true
        case .group: return !title.trimmingCharacters(in: .whitespaces).isEmpty
        case .channel: return !title.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private var createTitle: String {
        switch mode {
        case .direct: return "Р’С‹Р±СЂР°С‚СЊ СЃРѕР±РµСЃРµРґРЅРёРєР° РЅРёР¶Рµ"
        case .group: return "РЎРѕР·РґР°С‚СЊ РіСЂСѓРїРїСѓ"
        case .channel: return "РЎРѕР·РґР°С‚СЊ РєР°РЅР°Р»"
        }
    }

    private func create() {
        let name = title.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .direct:
            error = "Р’С‹Р±РµСЂРёС‚Рµ РєРѕРЅС‚Р°РєС‚Р° РёР»Рё РґРѕР±Р°РІСЊС‚Рµ РЅРѕРІРѕРіРѕ"
        case .group:
            guard !name.isEmpty else { return }
            _ = env.createGroup(title: name, memberIds: Array(selected))
            dismiss()
        case .channel:
            guard !name.isEmpty else { return }
            _ = env.createChannel(title: name, about: about)
            dismiss()
        }
    }
}

/// РРЅС„РѕСЂРјР°С†РёСЏ Рѕ С‡Р°С‚Рµ.
struct ChatInfoView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let chatId: String

    @State private var newMemberName = ""
    @State private var showAdd = false

    private var chat: Chat? { env.chat(chatId) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 10) {
                            AvatarView(title: chat?.title ?? "?", colorHex: chat?.avatarColor ?? Palette.blue, size: 96)
                            Text(chat?.title ?? "")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text(chat?.kind.title ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.top, 20)

                        SectionCard(title: "Рћ С‡Р°С‚Рµ") {
                            SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: "РЎРѕРѕР±С‰РµРЅРёР№", value: "\(env.messages(in: chatId).count)", showsChevron: false)
                            DividerLine()
                            SettingsRow(icon: "person.3.fill", title: "РЈС‡Р°СЃС‚РЅРёРєРѕРІ", value: "\(chat?.memberIds.count ?? 0)", showsChevron: false)
                            DividerLine()
                            SettingsRow(icon: "calendar", title: "РЎРѕР·РґР°РЅ", value: chat.map { Format.fullDate($0.createdAt) } ?? "", showsChevron: false)
                        }

                        if chat?.kind == .group {
                            SectionCard(title: "РЈС‡Р°СЃС‚РЅРёРєРё") {
                                ForEach(chat?.memberIds ?? [], id: \.self) { id in
                                    memberRow(id)
                                    DividerLine()
                                }
                                Button {
                                    showAdd = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Theme.accentBright)
                                        Text("Р”РѕР±Р°РІРёС‚СЊ СѓС‡Р°СЃС‚РЅРёРєР°")
                                            .foregroundColor(Theme.accentBright)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        SectionCard(title: "РќР°СЃС‚СЂРѕР№РєРё") {
                            Toggle(isOn: Binding(
                                get: { chat?.isMuted ?? false },
                                set: { env.setMuted(chatId, $0) }
                            )) {
                                Label("Р‘РµР· Р·РІСѓРєР°", systemImage: "bell.slash.fill")
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .tint(Theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            DividerLine()
                            Toggle(isOn: Binding(
                                get: { chat?.isPinned ?? false },
                                set: { env.setPinned(chatId, $0) }
                            )) {
                                Label("Р—Р°РєСЂРµРїРёС‚СЊ", systemImage: "pin.fill")
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .tint(Theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }

                        Button(role: .destructive) {
                            env.deleteChat(chatId)
                            dismiss()
                        } label: {
                            Text("РЈРґР°Р»РёС‚СЊ С‡Р°С‚")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.danger.opacity(0.16)))
                                .foregroundColor(Theme.danger)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("РРЅС„РѕСЂРјР°С†РёСЏ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Р“РѕС‚РѕРІРѕ") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Р”РѕР±Р°РІРёС‚СЊ СѓС‡Р°СЃС‚РЅРёРєР°", isPresented: $showAdd) {
                TextField("РРјСЏ", text: $newMemberName)
                Button("Р”РѕР±Р°РІРёС‚СЊ") {
                    let name = newMemberName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let contact = env.addContact(displayName: name, username: "")
                    newMemberName = ""
                    _ = contact
                }
                Button("РћС‚РјРµРЅР°", role: .cancel) { newMemberName = "" }
            }
        }
    }

    private func memberRow(_ id: String) -> some View {
        HStack(spacing: 12) {
            if id == env.profile.id {
                AvatarView(title: env.profile.displayName, colorHex: env.profile.avatarColor, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(env.profile.displayName).foregroundColor(Theme.textPrimary)
                    Text("РІС‹").font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                }
            } else if let contact = env.contact(id) {
                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(contact.displayName).foregroundColor(Theme.textPrimary)
                    Text("Р»РѕРєР°Р»СЊРЅС‹Р№ РєРѕРЅС‚Р°РєС‚").font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                }
            } else {
                AvatarView(title: "?", colorHex: Palette.blue, size: 38)
                Text("РЈС‡Р°СЃС‚РЅРёРє").foregroundColor(Theme.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

