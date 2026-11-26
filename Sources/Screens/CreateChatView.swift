import SwiftUI

/// Создание личного чата, группы или канала.
struct CreateChatView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable {
        case direct = "Чат"
        case group = "Группа"
        case channel = "Канал"
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
                        Picker("Тип", selection: $mode) {
                            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        if mode != .direct {
                            VStack(spacing: 10) {
                                TextField(mode == .group ? "Название группы" : "Название канала", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.panel))
                                if mode == .channel {
                                    TextField("Описание канала", text: $about, axis: .vertical)
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

                        Text("Всё создаётся локально: это тестовый режим без серверов и без реальных собеседников.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Новое")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Новый контакт", isPresented: $showNewContact) {
                TextField("Имя", text: $newContactName)
                Button("Создать") {
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
                Button("Отмена", role: .cancel) { newContactName = "" }
            } message: {
                Text("Контакт существует только на этом устройстве.")
            }
        }
    }

    private var contactPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mode == .group ? "Участники" : "Кому написать")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 16)

            if env.snapshot.contacts.isEmpty {
                Text("Контактов пока нет — добавьте кнопкой сверху.")
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
        case .direct: return "Выбрать собеседника ниже"
        case .group: return "Создать группу"
        case .channel: return "Создать канал"
        }
    }

    private func create() {
        let name = title.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .direct:
            error = "Выберите контакта или добавьте нового"
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

/// Информация о чате.
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

                        SectionCard(title: "О чате") {
                            SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Сообщений", value: "\(env.messages(in: chatId).count)", showsChevron: false)
                            DividerLine()
                            SettingsRow(icon: "person.3.fill", title: "Участников", value: "\(chat?.memberIds.count ?? 0)", showsChevron: false)
                            DividerLine()
                            SettingsRow(icon: "calendar", title: "Создан", value: chat.map { Format.fullDate($0.createdAt) } ?? "", showsChevron: false)
                        }

                        if chat?.kind == .group {
                            SectionCard(title: "Участники") {
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
                                        Text("Добавить участника")
                                            .foregroundColor(Theme.accentBright)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        SectionCard(title: "Настройки") {
                            Toggle(isOn: Binding(
                                get: { chat?.isMuted ?? false },
                                set: { env.setMuted(chatId, $0) }
                            )) {
                                Label("Без звука", systemImage: "bell.slash.fill")
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
                                Label("Закрепить", systemImage: "pin.fill")
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
                            Text("Удалить чат")
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
            .navigationTitle("Информация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Добавить участника", isPresented: $showAdd) {
                TextField("Имя", text: $newMemberName)
                Button("Добавить") {
                    let name = newMemberName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let contact = env.addContact(displayName: name, username: "")
                    newMemberName = ""
                    _ = contact
                }
                Button("Отмена", role: .cancel) { newMemberName = "" }
            }
        }
    }

    private func memberRow(_ id: String) -> some View {
        HStack(spacing: 12) {
            if id == env.profile.id {
                AvatarView(title: env.profile.displayName, colorHex: env.profile.avatarColor, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(env.profile.displayName).foregroundColor(Theme.textPrimary)
                    Text("вы").font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                }
            } else if let contact = env.contact(id) {
                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(contact.displayName).foregroundColor(Theme.textPrimary)
                    Text("локальный контакт").font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                }
            } else {
                AvatarView(title: "?", colorHex: Palette.blue, size: 38)
                Text("Участник").foregroundColor(Theme.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
