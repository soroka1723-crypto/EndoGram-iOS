import SwiftUI

// MARK: - Контакты

/// Контакты — локальная адресная книга. Раскладка повторяет Telegram:
/// крупный заголовок, постоянная поисковая строка, шапка «КОНТАКТЫ» и сортировка по имени.
struct ContactsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var query = ""
    @State private var showNewContact = false
    @State private var selectedContact: UserProfile?

    private var filtered: [UserProfile] {
        let all = env.snapshot.contacts
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let needle = query.lowercased()
        return all.filter {
            $0.displayName.lowercased().contains(needle) || $0.username.lowercased().contains(needle)
        }
    }

    /// Единственная секция «КОНТАКТЫ» с сортировкой по имени — как в оригинале,
    /// где буквенный указатель прокручивает внутри одной секции.
    private var sorted: [UserProfile] {
        filtered.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if env.snapshot.contacts.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle.badge.plus",
                    title: "Контактов нет",
                    subtitle: "Добавьте локальный тестовый контакт — и начните с ним переписку. Контакт останется только на этом устройстве."
                )
            } else {
                List {
                    Section {
                        ForEach(sorted) { contact in
                            contactRow(contact)
                        }
                    } header: {
                        Text(ContactsStrings.topSection)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
                .listRowSeparatorTint(Theme.divider)
                .listRowBackground(Color.clear)
                .scrollContentBackground(.hidden)
                .searchable(
                    text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: ContactsStrings.searchLabel
                )
            }
        }
        .navigationTitle(ContactsStrings.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewContact = true } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 17, weight: .regular))
                }
                .tint(Theme.accent)
                .accessibilityLabel(ContactsStrings.newContact)
            }
        }
        .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showNewContact) {
            NewContactSheet().environmentObject(env)
        }
        .sheet(item: $selectedContact) { contact in
            ContactProfileView(contact: contact).environmentObject(env)
        }
    }

    private func contactRow(_ contact: UserProfile) -> some View {
        Button {
            selectedContact = contact
        } label: {
            HStack(spacing: 12) {
                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 48)
                VStack(alignment: .leading, spacing: 1) {
                    Text(contact.displayName)
                        .font(.system(size: 17))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text("@" + contact.username)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Тексты экрана контактов (ключи оригинала: `Contacts.*`, `NewContact.Title`).
enum ContactsStrings {
    static let title = "Контакты"
    static let topSection = "КОНТАКТЫ"
    static let searchLabel = "Поиск контактов и имён пользователей"
    static let newContact = "Новый контакт"
    static let firstName = "Имя"
    static let lastName = "Фамилия"
    static let phone = "Номер телефона"
    static let addPhoto = "Добавить фото"
    static let createFooter = "Контакт создаётся только на этом устройстве и никуда не отправляется."
}

// MARK: - Новый контакт

/// Экран создания локального контакта. Повторяет `NewContactController` из Telegram.
struct NewContactSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var created: UserProfile?

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        HStack {
                            Spacer()
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(Theme.panelElevated)
                                    .frame(width: 96, height: 96)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(Theme.textSecondary)
                                    )
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 15, weight: .semibold))
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
                        TextField(ContactsStrings.firstName, text: $firstName)
                            .foregroundColor(Theme.textPrimary)
                        TextField(ContactsStrings.lastName, text: $lastName)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .listRowBackground(Theme.panel)

                    Section {
                        TextField(ContactsStrings.phone, text: $phone)
                            .keyboardType(.phonePad)
                            .foregroundColor(Theme.textPrimary)
                    } footer: {
                        Text(ContactsStrings.createFooter)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(ContactsStrings.newContact)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .tint(Theme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { save() }
                        .disabled(!canSave)
                        .tint(canSave ? Theme.accent : Theme.textDisabled)
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $created) { contact in
                ChatDetailView(chatId: env.openDirectChat(with: contact).id)
                    .environmentObject(env)
            }
        }
    }

    private func save() {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        let last = lastName.trimmingCharacters(in: .whitespaces)
        guard !first.isEmpty else { return }
        let contact = env.addContact(
            displayName: last.isEmpty ? first : first + " " + last,
            username: "",
            phone: phone.trimmingCharacters(in: .whitespaces)
        )
        created = contact
    }
}

// MARK: - Профиль контакта

/// Профиль контакта. Раскладка повторяет `UserInfoScreen`: крупный аватар,
/// имя, @имя пользователя, круглые кнопки действий и блоки сведений.
struct ContactProfileView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let contact: UserProfile
    @State private var openChat: Chat?

    private var peerColor: Color { Color(hex: Palette.peerColor(for: contact.displayName)) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        actionRow
                        infoBlocks
                        offlineNote
                    }
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .tint(Theme.accent)
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $openChat) { chat in
                ChatDetailView(chatId: chat.id).environmentObject(env)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 110)
                .padding(.top, 8)
            Text(contact.displayName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("@" + contact.username)
                .font(.system(size: 15))
                .foregroundColor(peerColor)
            if !contact.bio.isEmpty {
                Text(contact.bio)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            roundAction(icon: "message.fill", title: "Написать") {
                openChat = env.openDirectChat(with: contact)
            }
            roundAction(icon: "phone.fill", title: "Звонок") {
                env.logCall(peerName: contact.displayName, isVideo: false, isOutgoing: true, isMissed: false, duration: 0)
            }
            roundAction(icon: "video.fill", title: "Видео") {
                env.logCall(peerName: contact.displayName, isVideo: true, isOutgoing: true, isMissed: false, duration: 0)
            }
        }
        .padding(.horizontal, 16)
    }

    private func roundAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 21, weight: .medium))
                            .foregroundColor(.white)
                    )
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accent)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var infoBlocks: some View {
        VStack(spacing: 22) {
            TelegramBlock {
                infoRow(icon: "phone.fill", title: ContactsStrings.phone,
                        value: contact.phone.isEmpty ? "не указан" : contact.phone, tint: Theme.accent)
                DividerLine()
                infoRow(icon: "at", title: "Имя пользователя", value: "@" + contact.username, tint: Theme.accent)
            }

            TelegramBlock {
                infoRow(icon: "info.circle.fill", title: "О контакте",
                        value: "Локальный контакт на этом устройстве", tint: Theme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
    }

    /// Строка сведения: иконка, подпись и значение — как в `UserInfoScreen`.
    private func infoRow(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private var offlineNote: some View {
        Text("Это тестовый профиль. Сообщения и звонки не уходят в сеть — переписка сохраняется только на этом устройстве.")
            .font(.system(size: 13))
            .foregroundColor(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
    }
}

// MARK: - Звонки

/// Звонки — журнал локальных тестовых вызовов. Сегменты «Все»/«Пропущенные»
/// и группировка по дням повторяют `CallListController` из Telegram.
struct CallsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showMissedOnly = false
    @State private var showPicker = false

    private var calls: [CallRecord] {
        let all = env.snapshot.calls
        return showMissedOnly ? all.filter { $0.isMissed } : all
    }

    private var sections: [(key: Date, calls: [CallRecord])] {
        let calendar = Calendar.current
        var result: [(key: Date, calls: [CallRecord])] = []
        for call in calls.sorted(by: { $0.startedAt > $1.startedAt }) {
            let day = calendar.startOfDay(for: call.startedAt)
            if let last = result.last, last.key == day {
                result[result.count - 1].calls.append(call)
            } else {
                result.append((day, [call]))
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TelegramSegmentedControl(
                    options: [(false, "Все"), (true, "Пропущенные")],
                    selection: $showMissedOnly
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if calls.isEmpty {
                    EmptyStateView(
                        icon: "phone.arrow.up.right",
                        title: showMissedOnly ? "Пропущенных нет" : "Нет звонков",
                        subtitle: "Позвоните локальному контакту — вызов останется в журнале только на этом устройстве."
                    )
                } else {
                    List {
                        ForEach(sections, id: \.key) { section in
                            Section {
                                ForEach(section.calls) { call in
                                    callRow(call)
                                }
                            } header: {
                                Text(Format.dayDivider(section.key))
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .listRowSeparatorTint(Theme.divider)
                    .listRowBackground(Color.clear)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Звонки")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showPicker = true } label: {
                    Image(systemName: "phone.badge.plus")
                        .font(.system(size: 17, weight: .regular))
                }
                .tint(Theme.accent)
                .accessibilityLabel("Новый звонок")
            }
        }
        .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPicker) {
            CallPickerView().environmentObject(env)
        }
    }

    private func callRow(_ call: CallRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(call))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(call.isMissed ? Theme.danger : Theme.success)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(call.peerName)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle(call))
                    .font(.system(size: 14))
                    .foregroundColor(call.isMissed ? Theme.danger : Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                if call.isVideo {
                    Image(systemName: "video.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                Text(Format.callTime(call.startedAt))
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconName(_ call: CallRecord) -> String {
        if call.isMissed { return "phone.down.fill" }
        return call.isOutgoing ? "phone.arrow.up.right.fill" : "phone.arrow.down.left.fill"
    }

    private func subtitle(_ call: CallRecord) -> String {
        if call.isMissed { return "Пропущенный" }
        return call.isOutgoing ? "Исходящий" : "Входящий"
    }
}

/// Выбор собеседника для звонка (ключ оригинала: `Calls.NewCall`).
struct CallPickerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if env.snapshot.contacts.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle",
                        title: "Нет контактов",
                        subtitle: "Сначала добавьте контакт на вкладке «Контакты»."
                    )
                } else {
                    List(env.snapshot.contacts) { contact in
                        Button {
                            env.logCall(peerName: contact.displayName, isVideo: false, isOutgoing: true, isMissed: false, duration: 12)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 44)
                                Text(contact.displayName)
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.accent)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .listRowSeparatorTint(Theme.divider)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Новый звонок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .tint(Theme.accent)
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
