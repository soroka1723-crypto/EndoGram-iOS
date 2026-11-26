import SwiftUI

/// Главный экран: папки, поиск, список чатов, архив.
struct ChatsListView: View {
    @EnvironmentObject private var env: AppEnvironment

    @State private var query = ""
    @State private var activeFolderId = "folder.all"
    @State private var showCompose = false
    @State private var searchActive = false
    @State private var searchChat: Chat?
    @State private var selectedChat: Chat?
    @State private var editing = false
    @State private var selection = Set<String>()
    @FocusState private var searchFocused: Bool

    private var folders: [ChatFolder] { env.snapshot.folders }

    private var activeFolder: ChatFolder {
        folders.first { $0.id == activeFolderId } ?? ChatFolder(id: "folder.all", title: "Все", icon: "tray.full.fill", chatIds: [], isSystem: true)
    }

    private var visibleChats: [Chat] {
        let base = env.chats(for: activeFolder)
        guard !query.isEmpty else { return base }
        let needle = query.lowercased()
        return base.filter { chat in
            chat.title.lowercased().contains(needle)
                || (env.lastMessage(in: chat.id)?.text.lowercased().contains(needle) ?? false)
        }
    }

    private var pinned: [Chat] { visibleChats.filter(\.isPinned) }
    private var regular: [Chat] { visibleChats.filter { !$0.isPinned } }

    var body: some View {
        ZStack {
            // theme.chatList.backgroundColor — 0x000000
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if searchActive {
                    inlineSearchBar
                    SearchResultsView(query: $query, selectedChat: $searchChat)
                        .environmentObject(env)
                } else {
                    searchField
                    folderStrip
                    StoriesStrip()
                        .environmentObject(env)

                    if visibleChats.isEmpty && env.archivedChats.isEmpty {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: "У вас пока нет переписки",
                            subtitle: "Начните переписку кнопкой-карандашом в правом верхнем углу или перейдите в раздел «Контакты»."
                        )
                    } else {
                        chatList
                    }
                }
            }
            if editing {
                VStack {
                    Spacer()
                    editBar
                }
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle(editing
                         ? (selection.isEmpty ? "Выберите чаты" : "Выбрано: \(selection.count)")
                         : "Чаты")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !searchActive && !visibleChats.isEmpty {
                    Button(editing ? "Готово" : "Правка") {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            editing.toggle()
                            selection.removeAll()
                        }
                    }
                    .tint(Theme.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if searchActive {
                    Button("Отмена") {
                        query = ""
                        searchActive = false
                        searchFocused = false
                    }
                    .tint(Theme.accent)
                } else {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .tint(Theme.accentBright)
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCompose) {
            CreateChatView()
                .environmentObject(env)
        }
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chatId: chat.id)
                .environmentObject(env)
        }
        .navigationDestination(item: $searchChat) { chat in
            ChatDetailView(chatId: chat.id)
                .environmentObject(env)
        }
    }

    /// Поиск прямо в списке чатов — как в Telegram, вместо отдельного экрана.
    private var inlineSearchBar: some View {
        SearchField(placeholder: "Поиск сообщений и пользователей",
                    text: $query,
                    focused: $searchFocused)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 6)
            .onAppear { searchFocused = true }
    }

    // MARK: - Поиск и папки

    private var searchField: some View {
        Button {
            searchActive = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                Text("Поиск")
                    .font(.system(size: 16))
                Spacer()
            }
            .foregroundColor(Theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.searchBar)
            )
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    private var folderStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(folders) { folder in
                    let isActive = folder.id == activeFolderId
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { activeFolderId = folder.id }
                    } label: {
                        HStack(spacing: 6) {
                            Text(folder.title)
                                .font(.system(size: 14, weight: .medium))
                            let unread = env.unread(in: folder)
                            if unread > 0 {
                                Text("\(unread)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(isActive ? Color.white.opacity(0.25) : Theme.accentBright))
                            }
                        }
                        .foregroundColor(isActive ? .white : Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isActive ? Theme.accent : Theme.background)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // В Telegram в полосе папок нет кнопки «плюс»: создание чата —
                // только карандашом в правом верхнем углу.
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Список

    private var chatList: some View {
        List {
            if !env.archivedChats.isEmpty {
                NavigationLink(value: ArchiveRoute()) {
                    HStack(spacing: 12) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Theme.accent))
                        Text("Архив")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("\(env.archivedChats.count)")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Theme.background)
            }

            if !pinned.isEmpty {
                Section {
                    ForEach(pinned) { chat in chatRow(chat, pinned: true) }
                }
            }

            Section {
                ForEach(regular) { chat in chatRow(chat, pinned: false) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationDestination(for: ArchiveRoute.self) { _ in
            ArchiveView().environmentObject(env)
        }
    }

    private func chatRow(_ chat: Chat, pinned: Bool) -> some View {
        Button {
            if editing {
                if selection.contains(chat.id) {
                    selection.remove(chat.id)
                } else {
                    selection.insert(chat.id)
                }
            } else {
                selectedChat = chat
            }
        } label: {
            HStack(spacing: 10) {
                if editing {
                    Image(systemName: selection.contains(chat.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 21))
                        .foregroundColor(selection.contains(chat.id) ? Theme.accent : Theme.textDisabled)
                        .transition(.scale.combined(with: .opacity))
                }
                ChatRowView(chat: chat)
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        // theme.chatList.pinnedItemBackgroundColor — 0x1C1C1D, обычные — 0x000000
        .listRowBackground(pinned ? Theme.pinnedRow : Theme.background)
        .listRowSeparatorTint(Theme.divider)
        .swipeActions(edge: .trailing, allowsFullSwipe: !editing) {
            Button(role: .destructive) {
                env.deleteChat(chat.id)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
            Button {
                env.setPinned(chat.id, !chat.isPinned)
            } label: {
                Label(chat.isPinned ? "Открепить" : "Закрепить", systemImage: "pin")
            }
            .tint(Theme.accent)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                env.setMuted(chat.id, !chat.isMuted)
            } label: {
                Label(chat.isMuted ? "Включить" : "Без звука", systemImage: chat.isMuted ? "bell" : "bell.slash")
            }
            .tint(Theme.textSecondary)
        }
        .contextMenu {
            Button {
                env.setPinned(chat.id, !chat.isPinned)
            } label: {
                Label(chat.isPinned ? "Открепить" : "Закрепить",
                      systemImage: chat.isPinned ? "pin.slash" : "pin")
            }
            Button {
                env.setMuted(chat.id, !chat.isMuted)
            } label: {
                Label(chat.isMuted ? "Включить звук" : "Без звука",
                      systemImage: chat.isMuted ? "bell" : "bell.slash")
            }
            Button {
                if chat.unreadCount > 0 {
                    env.markRead(chatId: chat.id)
                } else {
                    env.markUnread(chatId: chat.id)
                }
            } label: {
                Label(chat.unreadCount > 0 ? "Отметить прочитанным" : "Отметить непрочитанным",
                      systemImage: chat.unreadCount > 0 ? "checkmark.circle" : "circle")
            }
            Button {
                env.setArchived(chat.id, !chat.isArchived)
            } label: {
                Label(chat.isArchived ? "Из архива" : "В архив",
                      systemImage: chat.isArchived ? "tray.and.arrow.up" : "archivebox")
            }
            Button {
                // «Выбрать» из контекстного меню — `ChatList.Context.Select`.
                beginEditing(with: chat.id)
            } label: {
                Label("Выбрать", systemImage: "checkmark.circle")
            }
            Divider()
            Button(role: .destructive) {
                env.deleteChat(chat.id)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
    /// Нижняя панель режима «Правка» — действия над выбранными чатами.
    private var editBar: some View {
        HStack(spacing: 0) {
            editAction(icon: "checkmark.circle", title: "Прочитано", enabled: !selection.isEmpty) {
                for id in selection { env.markRead(chatId: id) }
                finishEditing()
            }
            editAction(icon: "pin", title: "Закрепить", enabled: !selection.isEmpty) {
                for id in selection { env.setPinned(id, true) }
                finishEditing()
            }
            editAction(icon: "bell.slash", title: "Без звука", enabled: !selection.isEmpty) {
                for id in selection { env.setMuted(id, true) }
                finishEditing()
            }
            editAction(icon: "archivebox", title: "В архив", enabled: !selection.isEmpty) {
                for id in selection { env.setArchived(id, true) }
                finishEditing()
            }
            editAction(icon: "trash", title: "Удалить", enabled: !selection.isEmpty, destructive: true) {
                for id in selection { env.deleteChat(id) }
                finishEditing()
            }
        }
        .padding(.vertical, 8)
        .background(Theme.rootNavigationBar)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.divider).frame(height: 0.5)
        }
    }

    private func editAction(
        icon: String,
        title: String,
        enabled: Bool,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                Text(title)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(enabled ? (destructive ? Theme.danger : Theme.accent) : Theme.textDisabled)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func finishEditing() {
        withAnimation(.easeInOut(duration: 0.18)) {
            editing = false
            selection.removeAll()
        }
    }

    /// Вход в режим правки с уже отмеченным чатом — `ChatList.Context.Select`.
    private func beginEditing(with chatId: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            editing = true
            selection = [chatId]
        }
    }
}

struct ArchiveRoute: Hashable {}

/// Строка чата.
struct ChatRowView: View {
    @EnvironmentObject private var env: AppEnvironment
    let chat: Chat

    private var preview: String {
        guard let message = env.lastMessage(in: chat.id) else {
            return chat.kind == .channel ? "Канал" : "Нет сообщений"
        }
        let prefix = message.senderId == env.profile.id ? "Вы: " : ""
        // Как в Telegram: у медиа показывается тип вложения, а не пустая строка.
        let body: String
        switch message.kind {
        case .photo: body = message.text.isEmpty ? "Фото" : "Фото, " + message.text
        case .video: body = message.text.isEmpty ? "Видео" : "Видео, " + message.text
        case .voice: body = "Голосовое сообщение"
        case .service, .text: body = message.text
        }
        return prefix + body.replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        HStack(spacing: 11) {
            AvatarView(title: chat.title, colorHex: chat.avatarColor, size: 54)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if chat.kind == .channel {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Text(chat.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    if chat.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer(minLength: 4)
                    Text(env.lastMessage(in: chat.id).map { Format.chatTime($0.createdAt) } ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 6) {
                    Text(preview)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    UnreadBadge(count: chat.unreadCount, muted: chat.isMuted)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// Экран архива.
struct ArchiveView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selectedChat: Chat?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if env.archivedChats.isEmpty {
                EmptyStateView(icon: "archivebox", title: "Архив пуст", subtitle: "Смахивайте чаты влево и отправляйте в архив.")
            } else {
                List {
                    ForEach(env.sorted(env.archivedChats)) { chat in
                        Button { selectedChat = chat } label: { ChatRowView(chat: chat) }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.background)
                            .listRowSeparatorTint(Theme.divider)
                            .swipeActions {
                                Button {
                                    env.setArchived(chat.id, false)
                                } label: {
                                    Label("Вернуть", systemImage: "tray.and.arrow.up")
                                }
                                .tint(Theme.accent)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Архив")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chatId: chat.id).environmentObject(env)
        }
    }
}