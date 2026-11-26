import SwiftUI

/// Тип создаваемой беседы.
enum ComposeKind: String, Identifiable {
    case group
    case channel

    var id: String { rawValue }

    var title: String { self == .group ? "Новая группа" : "Новый канал" }
    var namePlaceholder: String { self == .group ? "Название группы" : "Название канала" }
    var membersTitle: String { self == .group ? "Добавить участников" : "Добавить подписчиков" }
    var countLabel: String { self == .group ? "УЧАСТНИКИ" : "ПОДПИСЧИКИ" }
}

/// «Новое сообщение» — экран создания чата и входа в создание группы/канала.
/// Повторяет `ComposeChatController` из Telegram: поиск, список контактов
/// и две кнопки в шапке — новая группа и новый канал.
struct CreateChatView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var openChat: Chat?
    @State private var composeKind: ComposeKind?

    private var filtered: [UserProfile] {
        let all = env.snapshot.contacts
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let needle = query.lowercased()
        return all.filter {
            $0.displayName.lowercased().contains(needle) || $0.username.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if env.snapshot.contacts.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.plus",
                        title: "Контактов нет",
                        subtitle: "Добавьте локальный контакт на вкладке «Контакты» — и выберите его здесь для переписки."
                    )
                } else {
                    List {
                        Section {
                            ForEach(filtered) { contact in
                                Button {
                                    openChat = env.openDirectChat(with: contact)
                                } label: {
                                    HStack(spacing: 12) {
                                        AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 48)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(contact.displayName)
                                                .font(.system(size: 17))
                                                .foregroundColor(Theme.textPrimary)
                                            Text("@" + contact.username)
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text("КОНТАКТЫ")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                                .textCase(nil)
                        }
                    }
                    .listStyle(.plain)
                    .listRowSeparatorTint(Theme.divider)
                    .scrollContentBackground(.hidden)
                    .searchable(
                        text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Кому написать"
                    )
                }
            }
            .navigationTitle("Новое сообщение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .tint(Theme.accent)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { composeKind = .group } label: {
                        Image(systemName: "person.2.fill")
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Новая группа")

                    Button { composeKind = .channel } label: {
                        Image(systemName: "megaphone.fill")
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Новый канал")
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $openChat) { chat in
                ChatDetailView(chatId: chat.id).environmentObject(env)
            }
            .sheet(item: $composeKind) { kind in
                NewGroupChannelSheet(kind: kind) { chat in
                    composeKind = nil
                    openChat = chat
                }
                .environmentObject(env)
            }
        }
    }
}

/// Двухшаговое создание группы или канала: название и описание, затем участники.
struct NewGroupChannelSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let kind: ComposeKind
    /// Вызывается с созданным чатом — родитель открывает его на своём стеке.
    let onCreated: (Chat) -> Void

    private enum Step { case details, members }

    @State private var step: Step = .details
    @State private var title = ""
    @State private var about = ""
    @State private var selected = Set<String>()

    private var canContinue: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                switch step {
                case .details: detailsStep
                case .members: membersStep
                }
            }
            .navigationTitle(step == .details ? kind.title : kind.membersTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .details {
                        Button("Отмена") { dismiss() }.tint(Theme.accent)
                    } else {
                        Button("Назад") { step = .details }.tint(Theme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if step == .details {
                        Button("Далее") { step = .members }
                            .disabled(!canContinue)
                            .tint(canContinue ? Theme.accent : Theme.textDisabled)
                    } else {
                        Button("Создать") { create() }.tint(Theme.accent)
                    }
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Шаг 1

    private var detailsStep: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Theme.panelElevated)
                            .frame(width: 96, height: 96)
                            .overlay(
                                Image(systemName: kind == .group ? "person.2.fill" : "megaphone.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(Theme.textSecondary)
                            )
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                TextField(kind.namePlaceholder, text: $title)
                    .foregroundColor(Theme.textPrimary)
                TextField("Описание (необязательно)", text: $about, axis: .vertical)
                    .lineLimit(1...4)
                    .foregroundColor(Theme.textPrimary)
            } footer: {
                Text(kind == .group
                     ? "Группа создаётся только на этом устройстве. Приглашать в неё некого — собеседники локальные."
                     : "Канал создаётся только на этом устройстве. Подписчиков можно добавить на следующем шаге.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            }
            .listRowBackground(Theme.panel)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Шаг 2

    private var membersStep: some View {
        List {
            Section {
                if env.snapshot.contacts.isEmpty {
                    Text("Контактов нет. Можно создать \(kind == .group ? "группу" : "канал") без участников.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .listRowBackground(Theme.panel)
                } else {
                    ForEach(env.snapshot.contacts) { contact in
                        Button {
                            if selected.contains(contact.id) {
                                selected.remove(contact.id)
                            } else {
                                selected.insert(contact.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 44)
                                Text(contact.displayName)
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: selected.contains(contact.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selected.contains(contact.id) ? Theme.accent : Theme.textDisabled)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.panel)
                    }
                }
            } header: {
                Text(kind.countLabel)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func create() {
        let name = title.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let chat: Chat
        switch kind {
        case .group:
            chat = env.createGroup(title: name, memberIds: Array(selected))
        case .channel:
            chat = env.createChannel(title: name, about: about)
        }
        onCreated(chat)
        dismiss()
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
