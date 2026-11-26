import SwiftUI
import UIKit

/// Экран переписки в стиле Telegram.
struct ChatDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let chatId: String

    @State private var draft = ""
    @State private var editing: Message?
    @State private var replyingTo: Message?
    @State private var forwarding: Message?
    @State private var showInfo = false
    @State private var showAttach = false
    @State private var showEmoji = false
    @State private var toast: String?
    @StateObject private var recorder = VoiceRecorder()
    @StateObject private var player = VoicePlayer()
    @FocusState private var inputFocused: Bool

    private var chat: Chat? { env.chat(chatId) }
    private var messages: [Message] { env.messages(in: chatId) }
    private var pinned: Message? { env.pinnedMessage(in: chatId) }
    private var isChannel: Bool { chat?.kind == .channel }
    private var wallpaperStyle: WallpaperStyle {
        env.wallpaperStyle(for: chatId)
    }

    var body: some View {
        ZStack {
            ChatWallpaper(style: wallpaperStyle)
            VStack(spacing: 0) {
                if let pinned {
                    pinnedBar(pinned)
                }
                messageList
                composer
                if showEmoji {
                    EmojiPanel { emoji in
                        draft += emoji
                    }
                    .frame(height: 296)
                    .transition(.move(edge: .bottom))
                }
            }
            if let toast {
                toastView(toast)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button { showInfo = true } label: {
                    HStack(spacing: 9) {
                        AvatarView(title: chat?.title ?? "?", colorHex: chat?.avatarColor ?? Palette.blue, size: 34)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(chat?.title ?? "")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.accentBright)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showInfo = true
                    } label: { Label("Информация", systemImage: "info.circle") }
                    Button {
                        env.setMuted(chatId, !(chat?.isMuted ?? false))
                    } label: {
                        Label(chat?.isMuted == true ? "Включить звук" : "Без звука", systemImage: "bell.slash")
                    }
                    Button {
                        env.setArchived(chatId, true)
                    } label: { Label("В архив", systemImage: "archivebox") }
                    Divider()
                    Button(role: .destructive) {
                        env.deleteChat(chatId)
                    } label: { Label("Удалить чат", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                }
                .tint(Theme.accentBright)
            }
        }
        .toolbarBackground(Theme.rootNavigationBar.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { env.markRead(chatId: chatId) }
        .onDisappear {
            player.stop()
            if recorder.isRecording { recorder.cancel() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .endoGramVoiceLimitReached)) { _ in
            if recorder.isRecording { finishRecording() }
        }
        .sheet(isPresented: $showInfo) {
            ChatInfoView(chatId: chatId).environmentObject(env)
        }
        .sheet(item: $forwarding) { message in
            ForwardPickerView(message: message, sourceChatId: chatId)
                .environmentObject(env)
        }
    }

    private var subtitle: String {
        guard let chat else { return "" }
        switch chat.kind {
        case .direct: return "локальный чат"
        case .group: return Format.members(chat.memberIds.count)
        case .channel: return "канал"
        }
    }

    // MARK: - Список сообщений

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if messages.isEmpty {
                        VStack(spacing: 8) {
                            Text("Сообщений пока нет")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                            Text("Напишите первым — это локальный чат.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary.opacity(0.8))
                        }
                        .padding(.top, 60)
                    }

                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let previous = index > 0 ? messages[index - 1] : nil
                        let showDay = previous.map {
                            !Calendar.current.isDate($0.createdAt, inSameDayAs: message.createdAt)
                        } ?? true

                        if showDay {
                            Text(Format.dayDivider(message.createdAt))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Theme.background.opacity(0.55)))
                                .padding(.vertical, 8)
                        }

                        MessageBubble(
                            message: message,
                            isMine: message.senderId == env.profile.id,
                            isGroup: chat?.kind == .group,
                            showAuthor: shouldShowAuthor(before: previous, current: message),
                            quoted: messages.first { $0.id == message.replyToId },
                            onReply: { replyingTo = message; inputFocused = true },
                            onCopy: {
                                UIPasteboard.general.string = message.text
                                showToast("Скопировано")
                            },
                            onPin: { env.togglePin(messageId: message.id) },
                            onEdit: editAction(for: message),
                            onDelete: { env.deleteMessage(id: message.id) },
                            onReact: { emoji in env.setReaction(messageId: message.id, emoji: emoji) },
                            onForward: { forwarding = message },
                            onSave: { saveToFavourites(message) },
                            isPlaying: player.playingFileName == message.voiceFileName,
                            playProgress: player.progress,
                            onTogglePlay: {
                                guard let fileName = message.voiceFileName else { return }
                                player.toggle(fileName: fileName)
                            }
                        )
                        .id(message.id)
                    }
                    Color.clear.frame(height: 6).id("bottom")
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) {
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private func shouldShowAuthor(before: Message?, current: Message) -> Bool {
        guard let before else { return true }
        if before.senderId != current.senderId { return true }
        return current.createdAt.timeIntervalSince(before.createdAt) > 600
    }

    /// Изменять можно только свои текстовые сообщения — как в Telegram.
    private func editAction(for message: Message) -> (() -> Void)? {
        guard message.senderId == env.profile.id, message.kind == .text else { return nil }
        return {
            editing = message
            replyingTo = nil
            draft = message.text
            inputFocused = true
        }
    }

    /// «В избранное» — пересылка в личный чат-хранилище.
    private func saveToFavourites(_ message: Message) {
        let saved = env.savedMessagesChat()
        guard saved.id != chatId else {
            showToast("Это уже «Избранное»")
            return
        }
        env.forwardMessage(id: message.id, toChatId: saved.id)
        showToast("Сохранено в «Избранное»")
    }

    private func pinnedBar(_ message: Message) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Theme.accentBright)
                .frame(width: 2)
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 1) {
                Text("Закреплённое сообщение")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accentBright)
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                env.togglePin(messageId: message.id)
            } label: {
                Image(systemName: "pin.slash")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.inputPanel)
    }

    // MARK: - Поле ввода

    private var composer: some View {
        VStack(spacing: 0) {
            if recorder.isRecording {
                recordingBar
            }
            if let replyingTo {
                replyBar(replyingTo)
            }
            if let editing {
                HStack(spacing: 10) {
                    Image(systemName: "pencil")
                        .foregroundColor(Theme.accentBright)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Редактирование")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.accentBright)
                        Text(editing.text)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        self.editing = nil
                        draft = ""
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.panel)
            }

            if !recorder.isRecording {
                HStack(alignment: .bottom, spacing: 8) {
                Button {
                    showEmoji = true
                    inputFocused = false
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 34, height: 38)
                }
                .accessibilityLabel("Эмодзи и стикеры")

                TextField(isChannel ? "Написать в канал…" : "Сообщение", text: $draft, axis: .vertical)
                    .lineLimit(1...6)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.inputField)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.inputStroke, lineWidth: 1)
                    )
                    .focused($inputFocused)

                Button {
                    showAttach = true
                    inputFocused = false
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 32, height: 38)
                }
                .accessibilityLabel("Прикрепить")

                Button(action: submit) {
                    Image(systemName: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          ? (editing == nil ? "mic.fill" : "checkmark")
                          : "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.accent))
                }
                .disabled(!recorder.isRecording
                          && draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          && editing == nil)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Theme.inputPanel)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Theme.inputSeparator)
                    .frame(height: 0.5)
            }
            }
        }
        .sheet(isPresented: $showAttach) {
            AttachmentMenu { title in
                showAttach = false
                showToast("Офлайн-режим: «\(title)» пока не поддерживается, сообщение не отправлено")
            }
            .presentationDetents([.height(292)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Theme.panelElevated)
        }
    }

    /// Полоса ответа над полем ввода — как в Telegram.
    private func replyBar(_ message: Message) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.accent)
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 2)
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 1) {
                Text(message.senderId == env.profile.id ? "Вы" : message.authorName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .lineLimit(1)
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                replyingTo = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Theme.inputPanel)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.inputSeparator).frame(height: 0.5)
        }
    }

    /// Полоса записи голосового — красная точка, таймер и полоски громкости.
    private var recordingBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.danger)
                .frame(width: 9, height: 9)
            Text(Format.voiceDuration(recorder.elapsed))
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 44, alignment: .leading)

            VoiceWaveform(levels: recorder.levels, progress: 1, tint: Theme.danger)
                .frame(height: 22)

            Button {
                recorder.cancel()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.danger)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("Отменить запись")

            Button(action: finishRecording) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.accent))
            }
            .accessibilityLabel("Отправить голосовое")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.inputPanel)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.inputSeparator).frame(height: 0.5)
        }
    }

    private func submit() {
        if recorder.isRecording {
            finishRecording()
            return
        }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            startRecording()
            return
        }
        if let editing {
            env.editMessage(id: editing.id, text: text)
            self.editing = nil
        } else {
            env.sendMessage(chatId: chatId, text: text, replyToId: replyingTo?.id)
            replyingTo = nil
        }
        draft = ""
        inputFocused = true
    }

    private func startRecording() {
        inputFocused = false
        player.stop()
        recorder.requestPermission { granted in
            guard granted else {
                showToast("Нет доступа к микрофону: разрешите его в настройках iOS")
                return
            }
            recorder.start()
            if let error = recorder.error { showToast(error) }
        }
    }

    private func finishRecording() {
        guard let result = recorder.finish() else {
            if let error = recorder.error { showToast(error) }
            return
        }
        env.sendVoiceMessage(
            chatId: chatId,
            fileName: result.fileName,
            duration: result.duration,
            waveform: result.waveform
        )
        showToast("Голосовое сохранено на этом устройстве")
    }

    private func toastView(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.78)))
                .padding(.bottom, 90)
        }
        .transition(.opacity)
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { if toast == text { toast = nil } }
        }
    }
}

/// Пузырь сообщения.
struct MessageBubble: View {
    let message: Message
    let isMine: Bool
    let isGroup: Bool
    let showAuthor: Bool
    /// Сообщение, на которое отвечали — для цитаты над текстом.
    var quoted: Message? = nil
    /// Доступные действия из контекстного меню (как в оригинале).
    var onReply: () -> Void = {}
    var onCopy: () -> Void = {}
    var onPin: () -> Void = {}
    var onEdit: (() -> Void)? = nil
    var onDelete: () -> Void = {}
    var onReact: (String?) -> Void = { _ in }
    var onForward: () -> Void = {}
    var onSave: () -> Void = {}
    /// Состояние проигрывателя голосовых.
    var isPlaying: Bool = false
    var playProgress: Double = 0
    var onTogglePlay: () -> Void = {}

    /// Быстрые реакции Telegram.
    private static let quickReactions = ["👍", "❤️", "🔥", "🎉", "😁", "🤔"]

    /// Заливка пузыря как в Telegram: исходящее — вертикальный градиент,
    /// входящее — сплошной 0x1D1D1D с альфой 0.9, служебное — блок 0x2C2C2E.
    private var bubbleFill: AnyShapeStyle {
        if message.kind == .service {
            return AnyShapeStyle(Theme.panelElevated.opacity(0.9))
        }
        if isMine {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Theme.bubbleOutgoingTop, Theme.bubbleOutgoingBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        return AnyShapeStyle(Theme.bubbleIncoming)
    }

    /// Цвет «хвостика» — нижняя точка градиента для исходящих.
    private var tailColor: Color {
        if message.kind == .service { return Theme.panelElevated.opacity(0.9) }
        return isMine ? Theme.bubbleOutgoingBottom : Theme.bubbleIncoming
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMine { Spacer(minLength: 50) }

            if !isMine && isGroup {
                AvatarView(title: message.authorName, colorHex: Palette.peerColor(for: message.authorName), size: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                if !isMine && isGroup && showAuthor {
                    Text(message.authorName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: Palette.peerColor(for: message.authorName)))
                }
                if let forwardedFrom = message.forwardedFrom {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Переслано от \(forwardedFrom)")
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(isMine ? Color.white.opacity(0.85) : Theme.accent)
                    .padding(.bottom, 1)
                }
                if let quoted {
                    quoteBlock(quoted)
                }
                if message.kind == .voice {
                    voiceContent
                } else {
                    Text(message.text)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textPrimary)
                        .textSelection(.enabled)
                }

                HStack(spacing: 4) {
                    if message.isPinned {
                        Image(systemName: "pin.fill").font(.system(size: 9))
                    }
                    if message.isEdited {
                        Text("изм.").font(.system(size: 10))
                    }
                    Text(Format.time(message.createdAt)).font(.system(size: 10.5))
                    if isMine {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .foregroundColor(Theme.bubbleSecondaryMine)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.bubbleCorner, style: .continuous)
                    .fill(bubbleFill)
            )
            .overlay(alignment: isMine ? .bottomTrailing : .bottomLeading) {
                Circle()
                    .fill(tailColor)
                    .frame(width: 12, height: 12)
                    .offset(x: isMine ? 4 : -4, y: 4)
                    .clipped()
            }
            .overlay(alignment: isMine ? .bottomLeading : .bottomTrailing) {
                if let reaction = message.reaction {
                    reactionChip(reaction)
                        .offset(x: isMine ? -6 : 6, y: 12)
                }
            }
            .contextMenu { menu }

            if !isMine { Spacer(minLength: 50) }
        }
        .padding(.vertical, 1)
        .padding(.bottom, message.reaction == nil ? 0 : 12)
    }

    /// Голосовое сообщение: кнопка воспроизведения, полоски и длительность.
    private var voiceContent: some View {
        HStack(spacing: 10) {
            Button(action: onTogglePlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isMine ? .white : Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(isMine ? Color.white.opacity(0.24) : Theme.accent.opacity(0.16))
                    )
            }
            .buttonStyle(.plain)

            VoiceWaveform(
                levels: message.voiceWaveform ?? [],
                progress: isPlaying ? playProgress : 0,
                tint: isMine ? .white : Theme.accent
            )
            .frame(width: 128, height: 24)

            Text(Format.voiceDuration(message.voiceDuration))
                .font(.system(size: 12))
                .foregroundColor(isMine ? Color.white.opacity(0.85) : Theme.textSecondary)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    /// Цитата ответа — вертикальная черта и подпись автора, как в Telegram.
    private func quoteBlock(_ quoted: Message) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(isMine ? Color.white.opacity(0.85) : Theme.accent)
                .frame(width: 2)
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 1) {
                Text(quoted.senderId == message.senderId ? "Вы" : quoted.authorName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isMine ? .white : Theme.accent)
                    .lineLimit(1)
                Text(quoted.text)
                    .font(.system(size: 13))
                    .foregroundColor(isMine ? Color.white.opacity(0.85) : Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: 220, alignment: .leading)
        .padding(.bottom, 2)
    }

    private func reactionChip(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 13))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(isMine ? Theme.bubbleOutgoingBottom : Theme.panelElevated)
            )
            .overlay(Capsule().stroke(Theme.background.opacity(0.6), lineWidth: 1))
    }

    @ViewBuilder
    private var menu: some View {
        ControlGroup {
            ForEach(Self.quickReactions, id: \.self) { emoji in
                Button(emoji) { onReact(emoji) }
            }
        }
        if message.reaction != nil {
            Button {
                onReact(nil)
            } label: {
                Label("Убрать реакцию", systemImage: "face.smiling")
            }
        }
        Divider()
        Button(action: onReply) { Label("Ответить", systemImage: "arrowshape.turn.up.left") }
        Button(action: onForward) { Label("Переслать", systemImage: "arrowshape.turn.up.right") }
        Button(action: onSave) { Label("В избранное", systemImage: "bookmark") }
        Button(action: onCopy) { Label("Копировать", systemImage: "doc.on.doc") }
        Button(action: onPin) {
            Label(message.isPinned ? "Открепить" : "Закрепить", systemImage: message.isPinned ? "pin.slash" : "pin")
        }
        if let onEdit {
            Button(action: onEdit) { Label("Изменить", systemImage: "pencil") }
        }
        Divider()
        Button(role: .destructive, action: onDelete) {
            Label("Удалить", systemImage: "trash")
        }
    }
}

/// Выбор чата для пересылки — как `ForwardPicker` в Telegram.
struct ForwardPickerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let message: Message
    let sourceChatId: String

    @State private var query = ""
    @State private var done = false

    private var chats: [Chat] {
        let all = env.snapshot.chats
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let needle = query.lowercased()
        return all.filter { $0.title.lowercased().contains(needle) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(3)
                    } header: {
                        Text("Сообщение")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    }
                    .listRowBackground(Theme.panel)

                    Section {
                        ForEach(chats) { chat in
                            Button {
                                forward(to: chat)
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
                                    if chat.id == sourceChatId {
                                        Image(systemName: "arrowshape.turn.up.right.circle.fill")
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.panel)
                        }
                    } header: {
                        Text("Переслать в чат")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    } footer: {
                        Text("Пересылка создаёт локальную копию сообщения с пометкой автора. В сеть ничего не уходит.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск чата")
            }
            .navigationTitle("Переслать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                        .tint(Theme.accent)
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onChange(of: done) { _, finished in
            if finished { dismiss() }
        }
    }

    private func forward(to chat: Chat) {
        env.forwardMessage(id: message.id, toChatId: chat.id)
        done = true
    }
}


/// Полоски громкости голосового сообщения — как в пузыре Telegram.
struct VoiceWaveform: View {
    let levels: [Double]
    /// Доля проигранного: слева полоски ярче.
    let progress: Double
    var tint: Color = Theme.accent

    private var bars: [Double] {
        levels.isEmpty ? Array(repeating: 0.35, count: 40) : levels
    }

    var body: some View {
        GeometryReader { geometry in
            let count = max(1, bars.count)
            let spacing: CGFloat = 2
            let width = max(1.5, (geometry.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, level in
                    Capsule()
                        .fill(tint.opacity(played(index, of: count) ? 1 : 0.45))
                        .frame(width: width, height: max(3, CGFloat(level) * geometry.size.height))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func played(_ index: Int, of count: Int) -> Bool {
        guard progress > 0 else { return false }
        return Double(index) / Double(count) <= progress
    }
}

/// Меню вложений в стиле Telegram: сетка круглых значков.
/// Все пункты честно сообщают, что вложения в офлайн-режиме не отправляются.
struct AttachmentMenu: View {
    let onSelect: (String) -> Void

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: String
    }

    private var items: [Item] {
        [
            Item(title: "Фото или видео", icon: "photo.fill", color: Palette.blue),
            Item(title: "Файл", icon: "doc.fill", color: Palette.purple),
            Item(title: "Геопозиция", icon: "location.fill", color: Palette.green),
            Item(title: "Контакт", icon: "person.crop.circle.fill", color: Palette.orange),
            Item(title: "Опрос", icon: "chart.bar.fill", color: Palette.cyan),
            Item(title: "Музыка", icon: "music.note", color: Palette.pink)
        ]
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 14) {
            Text("Вложение")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 14)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    Button {
                        onSelect(item.title)
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: item.color))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: item.icon)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                )
                            Text(item.title)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            Text("Офлайн-режим: вложения не отправляются и не сохраняются.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.panelElevated)
    }
}