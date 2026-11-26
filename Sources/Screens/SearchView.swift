import SwiftUI

/// Категории поиска — ключи оригинала `ChatList.Search.Filter*`.
enum SearchFilter: String, CaseIterable, Identifiable {
    case all
    case chats
    case messages
    case files
    case links
    case music
    case voice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Все"
        case .chats: return "Чаты"
        case .messages: return "Сообщения"
        case .files: return "Файлы"
        case .links: return "Ссылки"
        case .music: return "Музыка"
        case .voice: return "Голосовые"
        }
    }

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .chats: return "bubble.left.and.bubble.right.fill"
        case .messages: return "text.bubble.fill"
        case .files: return "doc.fill"
        case .links: return "link"
        case .music: return "music.note"
        case .voice: return "mic.fill"
        }
    }

    /// Категории, которых в офлайн-режиме физически не может быть.
    var isMediaCategory: Bool {
        switch self {
        case .files, .links, .music, .voice: return true
        default: return false
        }
    }
}

/// Поиск — повторяет экран поиска Telegram: недавние запросы, категории
/// и раздельные секции «Чаты и контакты» и «Сообщения».
struct SearchView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var filter: SearchFilter = .all
    @State private var selectedChat: Chat?
    @AppStorage("endogram.recentSearches") private var recentRaw = ""

    // MARK: - Совпадения

    private var chatHits: [Chat] {
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        return env.snapshot.chats.filter { $0.title.lowercased().contains(needle) }
    }

    private var contactHits: [UserProfile] {
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        return env.snapshot.contacts.filter {
            $0.displayName.lowercased().contains(needle) || $0.username.lowercased().contains(needle)
        }
    }

    private var messageHits: [Message] {
        guard query.count >= 1 else { return [] }
        let needle = query.lowercased()
        return env.snapshot.messages
            .filter { $0.text.lowercased().contains(needle) }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(60)
            .map { $0 }
    }

    private var recent: [String] {
        recentRaw.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }

    private var hasAnyHit: Bool {
        !chatHits.isEmpty || !contactHits.isEmpty || !messageHits.isEmpty
    }

    // MARK: - Тело

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    if query.isEmpty {
                        if !recent.isEmpty {
                            Section {
                                ForEach(recent, id: \.self) { term in
                                    Button {
                                        query = term
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 16))
                                                .foregroundColor(Theme.textSecondary)
                                                .frame(width: 24)
                                            Text(term)
                                                .font(.system(size: 16))
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Theme.panel)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            removeRecent(term)
                                        } label: { Label("Удалить", systemImage: "trash") }
                                    }
                                }
                            } header: { sectionHeader("НЕДАВНИЕ") }
                        }
                        categorySection
                        Section {
                            Text("Поиск идёт только по данным на этом устройстве. В интернет ничего не отправляется.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                                .listRowBackground(Color.clear)
                        }
                    } else {
                        switch filter {
                        case .all:
                            dialogsSection
                            messagesSection
                            if !hasAnyHit { nothingFound }
                            categorySection
                        case .chats:
                            dialogsSection
                            if chatHits.isEmpty && contactHits.isEmpty { nothingFound }
                            categorySection
                        case .messages:
                            messagesSection
                            if messageHits.isEmpty { nothingFound }
                            categorySection
                        default:
                            mediaEmpty
                            categorySection
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Поиск сообщений и пользователей"
            )
            .onSubmit(of: .search) { remember(query) }
            .navigationTitle(filter == .all ? "Поиск" : filter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if filter != .all {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Все") { filter = .all }
                            .tint(Theme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                        .tint(Theme.accent)
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedChat) { chat in
                ChatDetailView(chatId: chat.id).environmentObject(env)
            }
        }
    }

    // MARK: - Секции

    @ViewBuilder
    private var dialogsSection: some View {
        if !chatHits.isEmpty || !contactHits.isEmpty {
            Section {
                ForEach(contactHits) { contact in
                    Button {
                        remember(query)
                        selectedChat = env.openDirectChat(with: contact)
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 44)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(contact.displayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.textPrimary)
                                Text("@" + contact.username)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.panel)
                }
                ForEach(chatHits) { chat in
                    Button {
                        remember(query)
                        selectedChat = chat
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(title: chat.title, colorHex: chat.avatarColor, size: 44)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(chat.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.textPrimary)
                                Text(chat.kind.title)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.panel)
                }
            } header: { sectionHeader("ЧАТЫ И КОНТАКТЫ") }
        }
    }

    @ViewBuilder
    private var messagesSection: some View {
        if !messageHits.isEmpty {
            Section {
                ForEach(messageHits) { message in
                    Button {
                        if let chat = env.chat(message.chatId) {
                            remember(query)
                            selectedChat = chat
                        }
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(title: env.chat(message.chatId)?.title ?? "Чат",
                                       colorHex: env.chat(message.chatId)?.avatarColor ?? Palette.blue,
                                       size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(env.chat(message.chatId)?.title ?? "Чат")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text(highlighted(message.text))
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                                    .lineLimit(2)
                                Text(Format.fullDate(message.createdAt))
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.panel)
                }
            } header: { sectionHeader("СООБЩЕНИЯ") }
        }
    }

    private var categorySection: some View {
        Section {
            ForEach(SearchFilter.allCases.filter { $0 != .all }) { item in
                Button {
                    filter = item
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Theme.accent)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: item.icon)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        Text(item.title)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        if filter == item {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Theme.panel)
            }
        } header: { sectionHeader("КАТЕГОРИИ") }
    }

    private var mediaEmpty: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("В этой категории пусто")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text("В офлайн-режиме приложение не принимает и не хранит медиафайлы, ссылки, музыку и голосовые сообщения — искать нечего.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.vertical, 4)
            .listRowBackground(Theme.panel)
        }
    }

    private var nothingFound: some View {
        Section {
            Text("Ничего не найдено")
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .listRowBackground(Theme.panel)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Theme.textSecondary)
            .textCase(nil)
    }

    // MARK: - Мелочи

    /// Подсветка совпадения — как в результатах поиска Telegram.
    private func highlighted(_ text: String) -> AttributedString {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return AttributedString(text) }
        var result = AttributedString()
        var rest = Substring(text)
        while let found = rest.range(of: needle, options: .caseInsensitive) {
            result += AttributedString(String(rest[rest.startIndex..<found.lowerBound]))
            var hit = AttributedString(String(rest[found]))
            hit.foregroundColor = Theme.accent
            hit.inlinePresentationIntent = .stronglyEmphasized
            result += hit
            rest = rest[found.upperBound...]
        }
        result += AttributedString(String(rest))
        return result
    }

    private func remember(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        var list = recent.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        list.insert(trimmed, at: 0)
        recentRaw = list.prefix(8).joined(separator: "\n")
    }

    private func removeRecent(_ term: String) {
        recentRaw = recent.filter { $0 != term }.joined(separator: "\n")
    }
}
