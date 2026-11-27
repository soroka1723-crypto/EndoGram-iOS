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
    @State private var showCameraPhoto = false
    @State private var showCameraVideo = false
    @State private var showLibrary = false
    @State private var pendingAttachment: PendingAttachment?
    @State private var viewingMedia: Message?
    @State private var showEmoji = false
    @State private var toast: String?
    /// Режим выбора нескольких сообщений — как «Выбрать» в Telegram.
    @State private var selecting = false
    @State private var selectedIds = Set<String>()
    @State private var bulkForwarding = false
    @State private var confirmBulkDelete = false
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
                if selecting {
                    selectionBar
                } else {
                    composer
                    if showEmoji {
                        EmojiPanel { emoji in
                            draft += emoji
                        }
                        .frame(height: 296)
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            if let toast {
                toastView(toast)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if selecting {
                    VStack(spacing: 0) {
                        Text(selectedIds.isEmpty ? "Выберите сообщения" : "Выбрано: \(selectedIds.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text(chat?.title ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.accentBright)
                    }
                } else {
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
            }
            ToolbarItem(placement: .topBarTrailing) {
                if selecting {
                    Button("Отмена") { endSelection() }
                        .tint(Theme.accentBright)
                } else {
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
        }
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
        .sheet(isPresented: $bulkForwarding) {
            BulkForwardPicker(ids: selectedIds.sorted(), sourceChatId: chatId)
                .environmentObject(env)
        }
        .alert("Удалить выбранные сообщения?", isPresented: $confirmBulkDelete) {
            Button("Удалить", role: .destructive) {
                env.deleteMessages(ids: selectedIds.sorted())
                showToast("Удалено сообщений: \(selectedIds.count)")
                endSelection()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Сообщения будут удалены только на этом устройстве.")
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
                            largeEmojiEnabled: env.snapshot.settings.largeEmoji,
                            quickReactionsEnabled: env.snapshot.settings.quickReactionEnabled,
                            animationsEnabled: env.snapshot.settings.animationsEnabled,
                            selectionMode: selecting,
                            isSelected: selectedIds.contains(message.id),
                            onToggleSelect: { toggleSelection(message.id) },
                            onSelect: { beginSelection(with: message.id) },
                            onOpenMedia: { viewingMedia = message },
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
            AttachmentMenu { action in
                showAttach = false
                switch action {
                case .media:
                    openLibrary()
                case .cameraPhoto:
                    openCamera(.photo)
                case .cameraVideo:
                    openCamera(.video)
                case .file, .location, .contact, .poll, .music:
                    showToast("Офлайн-режим: «\(action.title)» пока не поддерживается")
                }
            }
            .presentationDetents([.height(292)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Theme.panelElevated)
        }
        .sheet(isPresented: $showLibrary) {
            MediaLibraryPicker(store: ChatMedia.store) { attachment in
                pendingAttachment = attachment
            }
        }
        .sheet(item: $pendingAttachment) { attachment in
            MediaSendSheet(chatId: chatId, attachment: attachment)
                .environmentObject(env)
        }
        .fullScreenCover(isPresented: $showCameraPhoto) {
            StoryCameraPicker(mode: .photo) { capture in
                showCameraPhoto = false
                handleCapture(capture)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCameraVideo) {
            StoryCameraPicker(mode: .video) { capture in
                showCameraVideo = false
                handleCapture(capture)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $viewingMedia) { message in
            MediaViewerView(message: message)
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

    // MARK: - Вложения

    private func openLibrary() {
        // Небольшая пауза: сначала закрывается меню, потом открывается галерея.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showLibrary = true
        }
    }

    private func openCamera(_ mode: StoryCameraPicker.Mode) {
        guard StoryCameraPicker.isAvailable else {
            showToast("Камера недоступна на этом устройстве")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            switch mode {
            case .photo: showCameraPhoto = true
            case .video: showCameraVideo = true
            }
        }
    }

    private func handleCapture(_ capture: StoryCapture?) {
        guard let capture else { return }
        switch capture {
        case .photo(let image):
            pendingAttachment = PendingAttachment(image: image, videoFileName: nil, videoDuration: 0)
        case .video(let url):
            guard let fileName = ChatMedia.store.saveVideo(from: url) else {
                showToast("Не удалось сохранить видео на устройство")
                return
            }
            let duration = ChatMedia.store.duration(ofVideo: fileName)
            pendingAttachment = PendingAttachment(image: nil, videoFileName: fileName,
                                                  videoDuration: duration)
        }
    }

    /// Нижняя панель в режиме выбора — как панель действий Telegram.
    private var selectionBar: some View {
        HStack(spacing: 0) {
            selectionAction(icon: "arrowshape.turn.up.right.fill", title: "Переслать") {
                bulkForwarding = true
            }
            selectionAction(icon: "doc.on.doc.fill", title: "Копировать") {
                copySelected()
            }
            selectionAction(icon: "trash.fill", title: "Удалить", destructive: true) {
                confirmBulkDelete = true
            }
        }
        .padding(.vertical, 10)
        .background(Theme.inputPanel)
    }

    private func selectionAction(icon: String, title: String,
                                 destructive: Bool = false,
                                 action: @escaping () -> Void) -> some View {
        let enabled = !selectedIds.isEmpty
        let tint = destructive ? Theme.danger : Theme.accentBright
        return Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 19, weight: .semibold))
                Text(title).font(.system(size: 11))
            }
            .foregroundColor(enabled ? tint : Theme.textDisabled)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func beginSelection(with id: String) {
        selecting = true
        selectedIds = [id]
        showEmoji = false
        inputFocused = false
    }

    private func endSelection() {
        selecting = false
        selectedIds.removeAll()
    }

    private func copySelected() {
        let texts = selectedMessages.map(\.text).filter { !$0.isEmpty }
        guard !texts.isEmpty else { return }
        UIPasteboard.general.string = texts.joined(separator: "\n")
        showToast(texts.count == 1 ? "Скопировано" : "Скопировано сообщений: \(texts.count)")
        endSelection()
    }

    private var selectedMessages: [Message] {
        messages.filter { selectedIds.contains($0.id) }
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
    @EnvironmentObject private var env: AppEnvironment
    let message: Message
    let isMine: Bool
    let isGroup: Bool
    let showAuthor: Bool
    /// Сообщение, на которое отвечали — для цитаты над текстом.
    var quoted: Message? = nil
    /// «Большие эмодзи» — одиночный эмодзи рисуется крупно.
    var largeEmojiEnabled: Bool = true
    /// «Быстрые реакции» — ряд эмодзи в контекстном меню.
    var quickReactionsEnabled: Bool = true
    /// Анимации подарков (из настроек).
    var animationsEnabled: Bool = true
    /// Режим выбора нескольких сообщений.
    var selectionMode: Bool = false
    var isSelected: Bool = false
    var onToggleSelect: () -> Void = {}
    /// Вход в режим выбора из контекстного меню.
    var onSelect: () -> Void = {}
    /// Открыть фото или видео на весь экран.
    var onOpenMedia: () -> Void = {}
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

    /// «Большие эмодзи» (`Appearance_LargeEmoji`): если сообщение целиком
    /// состоит из небольшого числа эмодзи, Telegram показывает их крупно.
    private var bigEmojiSize: CGFloat {
        guard largeEmojiEnabled else { return 16 }
        let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 3 else { return 16 }
        let allEmoji = trimmed.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji && !scalar.isASCII
        }
        return allEmoji ? 44 : 16
    }

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
            if selectionMode && isMine { selectionCircle }
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
                } else if message.kind == .gift {
                    giftContent
                } else if message.isMedia {
                    mediaContent
                    if !message.text.isEmpty {
                        Text(message.text)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textPrimary)
                            .textSelectionIf(!selectionMode)
                            .padding(.top, 2)
                    }
                } else {
                    Text(message.text)
                        .font(.system(size: bigEmojiSize))
                        .foregroundColor(Theme.textPrimary)
                        .textSelectionIf(!selectionMode)
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
            .contextMenuIf(!selectionMode) { menu }

            if !isMine { Spacer(minLength: 50) }

            if selectionMode && !isMine { selectionCircle }
        }
        .padding(.vertical, 1)
        .padding(.bottom, message.reaction == nil ? 0 : 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectionMode { onToggleSelect() }
        }
    }

    /// Кружок выбора сообщения — как в режиме «Выбрать» Telegram.
    private var selectionCircle: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundColor(isSelected ? Theme.accent : Theme.textDisabled)
            .padding(.horizontal, 4)
            .transition(.scale.combined(with: .opacity))
    }

    /// Подарок в пузыре: настоящая анимация, название и цена.
    ///
    /// Как `Gift.Bubble.*` в Telegram: подарок рисуется в пузыре вместе с
    /// подписью, при включённых анимациях проигрывается его `.tgs`.
    @ViewBuilder
    private var giftContent: some View {
        if let giftId = message.giftId, let gift = env.gift(id: giftId) {
            VStack(alignment: .leading, spacing: 6) {
                GiftAnimationView(
                    assetId: GiftCatalog.assetId(forGiftId: gift.id),
                    size: 132,
                    duration: gift.duration,
                    animated: animationsEnabled && env.snapshot.settings.animationsEnabled,
                    fallbackEmoji: gift.emoji
                )
                Text(gift.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                HStack(spacing: 4) {
                    Text("⭐️").font(.system(size: 11))
                    Text(Format.number(gift.price))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.star)
                }
            }
        } else {
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
        }
    }

/// Фото или видео в пузыре: превью с плейсхолдером и длительностью.
    @ViewBuilder
    private var mediaContent: some View {
        if let fileName = message.mediaFileName {
            ZStack {
                if message.kind == .video {
                    if let thumb = ChatMedia.store.thumbnail(forVideo: fileName) {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(Theme.panelElevated)
                    }
                } else if let image = ChatMedia.store.image(for: fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Theme.panelElevated)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.textSecondary)
                        )
                }
            }
            .frame(width: 220, height: 165)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if message.kind == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.92))
                        .shadow(radius: 6)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if message.kind == .video, let duration = message.mediaDuration, duration > 0 {
                    Text(Format.duration(duration))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                        .padding(7)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !selectionMode { onOpenMedia() }
            }
        }
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
        if quickReactionsEnabled {
            ControlGroup {
                ForEach(Self.quickReactions, id: \.self) { emoji in
                    Button(emoji) { onReact(emoji) }
                }
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
        Button(action: onSelect) { Label("Выбрать", systemImage: "checkmark.circle") }
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


/// Выбор чата для массовой пересылки выбранных сообщений.
struct BulkForwardPicker: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let ids: [String]
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
                        Text("Выбрано сообщений: \(ids.count)")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    } header: {
                        Text("К пересылке")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    }
                    .listRowBackground(Theme.panel)

                    Section {
                        ForEach(chats) { chat in
                            Button {
                                _ = env.forwardMessages(ids: ids, toChatId: chat.id)
                                done = true
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
                    } header: {
                        Text("Переслать в чат")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    } footer: {
                        Text("Каждое выбранное сообщение станет отдельной локальной копией с пометкой автора. В сеть ничего не уходит.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск чата")
            }
            .navigationTitle("Переслать \(ids.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                        .tint(Theme.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onChange(of: done) { _, finished in
            if finished { dismiss() }
        }
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
///
/// Фото, видео и камера работают по-настоящему и офлайн. Остальные пункты
/// честно сообщают, что требуют серверных данных.
enum AttachmentAction: String, CaseIterable, Identifiable {
    case media, cameraPhoto, cameraVideo, file, location, contact, poll, music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .media:       return "Фото или видео"
        case .cameraPhoto: return "Камера"
        case .cameraVideo: return "Видео"
        case .file:        return "Файл"
        case .location:    return "Геопозиция"
        case .contact:     return "Контакт"
        case .poll:        return "Опрос"
        case .music:       return "Музыка"
        }
    }

    var icon: String {
        switch self {
        case .media:       return "photo.fill"
        case .cameraPhoto: return "camera.fill"
        case .cameraVideo: return "video.fill"
        case .file:        return "doc.fill"
        case .location:    return "location.fill"
        case .contact:     return "person.crop.circle.fill"
        case .poll:        return "chart.bar.fill"
        case .music:       return "music.note"
        }
    }

    var color: String {
        switch self {
        case .media:       return Palette.blue
        case .cameraPhoto: return Palette.cyan
        case .cameraVideo: return Palette.red
        case .file:        return Palette.purple
        case .location:    return Palette.green
        case .contact:     return Palette.orange
        case .poll:        return Palette.cyan
        case .music:       return Palette.pink
        }
    }
}

struct AttachmentMenu: View {
    let onSelect: (AttachmentAction) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(spacing: 14) {
            Text("Вложение")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 14)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(AttachmentAction.allCases) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        VStack(spacing: 7) {
                            Circle()
                                .fill(Color(hex: action.color))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: action.icon)
                                        .font(.system(size: 23, weight: .medium))
                                        .foregroundColor(.white)
                                )
                            Text(action.title)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)

            Text("Фото и видео сохраняются на устройстве. Остальные вложения требуют данных с сервера — в офлайне они недоступны.")
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