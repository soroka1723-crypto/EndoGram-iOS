import SwiftUI

/// Контакты: локальная адресная книга, из которой создаются чаты.
struct ContactsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var query = ""
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newUsername = ""
    @State private var selectedContact: UserProfile?

    private var filtered: [UserProfile] {
        guard !query.isEmpty else { return env.snapshot.contacts }
        let needle = query.lowercased()
        return env.snapshot.contacts.filter {
            $0.displayName.lowercased().contains(needle) || $0.username.lowercased().contains(needle)
        }
    }

    var body: some View {
        ZStack {
            Theme.panel.ignoresSafeArea()
            if env.snapshot.contacts.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle.badge.plus",
                    title: "Контактов нет",
                    subtitle: "Добавьте локальный тестовый контакт — и начните с ним переписку."
                )
            } else {
                List {
                    ForEach(filtered) { contact in
                        Button {
                            selectedContact = contact
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 48)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.displayName)
                                        .foregroundColor(Theme.textPrimary)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("@" + contact.username)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "message.fill")
                                    .foregroundColor(Theme.accentBright)
                                    .padding(8)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.panel)
                        .listRowSeparatorTint(Theme.divider)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, prompt: "Поиск контактов")
            }
        }
        .navigationTitle("Контакты")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "person.badge.plus")
                }
                .tint(Theme.accentBright)
            }
        }
        .toolbarBackground(Theme.panel, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Новый контакт", isPresented: $showAdd) {
            TextField("Имя", text: $newName)
            TextField("Имя пользователя", text: $newUsername)
            Button("Добавить") {
                let name = newName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                let contact = env.addContact(displayName: name, username: newUsername.trimmingCharacters(in: .whitespaces))
                newName = ""
                newUsername = ""
                _ = contact
            }
            Button("Отмена", role: .cancel) {
                newName = ""
                newUsername = ""
            }
        } message: {
            Text("Контакт сохранится только на этом устройстве.")
        }
        .sheet(item: $selectedContact) { contact in
            ContactProfileView(contact: contact)
                .environmentObject(env)
        }
    }
}

/// Профиль контакта.
struct ContactProfileView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let contact: UserProfile
    @State private var openChat: Chat?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 10) {
                            AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 96)
                            Text(contact.displayName)
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("@" + contact.username)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.accentBright)
                            if !contact.bio.isEmpty {
                                Text(contact.bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.top, 24)

                        HStack(spacing: 10) {
                            actionButton(icon: "message.fill", title: "Написать") {
                                openChat = env.openDirectChat(with: contact)
                            }
                            actionButton(icon: "phone.fill", title: "Звонок") {
                                env.logCall(peerName: contact.displayName, isVideo: false, isOutgoing: true, isMissed: false, duration: 0)
                            }
                            actionButton(icon: "video.fill", title: "Видео") {
                                env.logCall(peerName: contact.displayName, isVideo: true, isOutgoing: true, isMissed: false, duration: 0)
                            }
                        }
                        .padding(.horizontal, 16)

                        SectionCard(title: "О контакте") {
                            SettingsRow(icon: "person.fill", title: "Имя", value: contact.displayName, showsChevron: false)
                            DividerLine()
                            SettingsRow(icon: "at", title: "Имя пользователя", value: "@" + contact.username, showsChevron: false)
                            DividerLine()
                            SettingsRow(icon: "info.circle", title: "Тип", value: "Локальный контакт", showsChevron: false)
                        }

                        Text("Это тестовый профиль: сообщения и звонки не уходят в сеть.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $openChat) { chat in
                ChatDetailView(chatId: chat.id).environmentObject(env)
            }
        }
    }

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.accentBright)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.panel))
        }
        .buttonStyle(.plain)
    }
}

/// Звонки: журнал локальных тестовых вызовов.
struct CallsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selected: UserProfile?
    @State private var showPicker = false

    var body: some View {
        ZStack {
            Theme.panel.ignoresSafeArea()
            if env.snapshot.calls.isEmpty {
                EmptyStateView(
                    icon: "phone.arrow.up.right",
                    title: "Нет звонков",
                    subtitle: "Позвоните локальному контакту — вызов останется в журнале на этом устройстве."
                )
            } else {
                List {
                    ForEach(env.snapshot.calls) { call in
                        HStack(spacing: 12) {
                            Image(systemName: call.isMissed ? "phone.down.fill" : (call.isOutgoing ? "phone.arrow.up.right.fill" : "phone.arrow.down.left.fill"))
                                .foregroundColor(call.isMissed ? Theme.danger : Theme.accentBright)
                                .frame(width: 26)
                            AvatarView(title: call.peerName, colorHex: Palette.avatarColors[abs(call.peerName.hashValue % Palette.avatarColors.count)], size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(call.peerName)
                                    .foregroundColor(Theme.textPrimary)
                                Text(call.isMissed ? "Пропущенный" : (call.isVideo ? "Видеозвонок" : "Аудиозвонок"))
                                    .font(.system(size: 13))
                                    .foregroundColor(call.isMissed ? Theme.danger : Theme.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Format.callTime(call.startedAt))
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                                if call.duration > 0 {
                                    Text(Format.duration(call.duration))
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                        .listRowBackground(Theme.panel)
                        .listRowSeparatorTint(Theme.divider)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Звонки")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showPicker = true } label: {
                    Image(systemName: "phone.badge.plus")
                }
                .tint(Theme.accentBright)
            }
        }
        .toolbarBackground(Theme.panel, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPicker) {
            CallPickerView().environmentObject(env)
        }
    }
}

/// Выбор собеседника для звонка.
struct CallPickerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.panel.ignoresSafeArea()
                if env.snapshot.contacts.isEmpty {
                    EmptyStateView(icon: "person.crop.circle", title: "Нет контактов", subtitle: "Сначала добавьте контакт на вкладке «Контакты».")
                } else {
                    List(env.snapshot.contacts) { contact in
                        Button {
                            env.logCall(peerName: contact.displayName, isVideo: false, isOutgoing: true, isMissed: false, duration: 12)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 44)
                                Text(contact.displayName).foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "phone.fill").foregroundColor(Theme.accentBright)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.panel)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Новый звонок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}