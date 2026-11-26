import SwiftUI

/// Главный экран: папки, поиск, список чатов, архив.
struct ChatsListView: View {
    @EnvironmentObject private var env: AppEnvironment

    @State private var query = ""
    @State private var activeFolderId = "folder.all"
    @State private var showCompose = false
    @State private var showSearch = false
    @State private var selectedChat: Chat?

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
                searchField
                folderStrip

                if visibleChats.isEmpty && env.archivedChats.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "Пока нет чатов",
                        subtitle: "Нажмите на карандаш в правом верхнем углу, чтобы создать чат, группу или канал."
                    )
                } else {
                    chatList
                }
            }
        }
        .navigationTitle("Чаты")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                }
                .tint(Theme.accentBright)
            }
        }
        .toolbarBackground(Theme.panel, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCompose) {
            CreateChatView()
                .environmentObject(env)
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
                .environmentObject(env)
        }
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chatId: chat.id)
                .environmentObject(env)
        }
    }

    // MARK: - Поиск и папки

    private var searchField: some View {
        Button {
            showSearch = true
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
                    .fill(Theme.background)
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

                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.background))
                }
                .buttonStyle(.plain)
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
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.accent))
                        Text("Архив")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("\(env.archivedChats.count)")
                            .foregroundColor(Theme.accentBright)
                    }
                }
                .listRowBackground(Theme.panel)
            }

            if !pinned.isEmpty {
                Section {
                    ForEach(pinned) { chat in chatRow(chat) }
                } header: {
                    Text("Закреплённые").font(.system(size: 12, weight: .semibold))
                }
            }

            Section {
                ForEach(regular) { chat in chatRow(chat) }
            } header: {
                if !pinned.isEmpty {
                    Text("Все чаты").font(.system(size: 12, weight: .semibold))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.panel)
        .navigationDestination(for: ArchiveRoute.self) { _ in
            ArchiveView().environmentObject(env)
        }
    }

    private func chatRow(_ chat: Chat) -> some View {
        Button {
            selectedChat = chat
        } label: {
            ChatRowView(chat: chat)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        .listRowBackground(Theme.panel)
        .listRowSeparatorTint(Theme.divider)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
        return prefix + message.text.replacingOccurrences(of: "\n", with: " ")
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
            Theme.panel.ignoresSafeArea()
            if env.archivedChats.isEmpty {
                EmptyStateView(icon: "archivebox", title: "Архив пуст", subtitle: "Смахивайте чаты влево и отправляйте в архив.")
            } else {
                List {
                    ForEach(env.sorted(env.archivedChats)) { chat in
                        Button { selectedChat = chat } label: { ChatRowView(chat: chat) }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.panel)
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
