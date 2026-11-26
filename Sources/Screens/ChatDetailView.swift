import SwiftUI
import UIKit

/// Р­РєСЂР°РЅ РїРµСЂРµРїРёСЃРєРё РІ СЃС‚РёР»Рµ Telegram.
struct ChatDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let chatId: String

    @State private var draft = ""
    @State private var editing: Message?
    @State private var actionMessage: Message?
    @State private var showInfo = false
    @State private var showAttach = false
    @State private var toast: String?
    @FocusState private var inputFocused: Bool

    private var chat: Chat? { env.chat(chatId) }
    private var messages: [Message] { env.messages(in: chatId) }
    private var pinned: Message? { env.pinnedMessage(in: chatId) }
    private var isChannel: Bool { chat?.kind == .channel }

    var body: some View {
        ZStack {
            ChatWallpaper()
            VStack(spacing: 0) {
                if let pinned {
                    pinnedBar(pinned)
                }
                messageList
                composer
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
                    } label: { Label("РРЅС„РѕСЂРјР°С†РёСЏ", systemImage: "info.circle") }
                    Button {
                        env.setMuted(chatId, !(chat?.isMuted ?? false))
                    } label: {
                        Label(chat?.isMuted == true ? "Р’РєР»СЋС‡РёС‚СЊ Р·РІСѓРє" : "Р‘РµР· Р·РІСѓРєР°", systemImage: "bell.slash")
                    }
                    Button {
                        env.setArchived(chatId, true)
                    } label: { Label("Р’ Р°СЂС…РёРІ", systemImage: "archivebox") }
                    Divider()
                    Button(role: .destructive) {
                        env.deleteChat(chatId)
                    } label: { Label("РЈРґР°Р»РёС‚СЊ С‡Р°С‚", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                }
                .tint(Theme.accentBright)
            }
        }
        .toolbarBackground(Theme.panel.opacity(0.96), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { env.markRead(chatId: chatId) }
        .sheet(isPresented: $showInfo) {
            ChatInfoView(chatId: chatId).environmentObject(env)
        }
        .confirmationDialog(
            "РЎРѕРѕР±С‰РµРЅРёРµ",
            isPresented: Binding(
                get: { actionMessage != nil },
                set: { if !$0 { actionMessage = nil } }
            ),
            presenting: actionMessage
        ) { message in
            Button("Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ") {
                editing = message
                draft = message.text
                actionMessage = nil
            }
            Button(message.isPinned ? "РћС‚РєСЂРµРїРёС‚СЊ" : "Р—Р°РєСЂРµРїРёС‚СЊ") {
                env.togglePin(messageId: message.id)
                actionMessage = nil
            }
            Button("РљРѕРїРёСЂРѕРІР°С‚СЊ") {
                UIPasteboard.general.string = message.text
                showToast("РЎРєРѕРїРёСЂРѕРІР°РЅРѕ")
                actionMessage = nil
            }
            Button("РЈРґР°Р»РёС‚СЊ", role: .destructive) {
                env.deleteMessage(id: message.id)
                actionMessage = nil
            }
            Button("РћС‚РјРµРЅР°", role: .cancel) { actionMessage = nil }
        }
    }

    private var subtitle: String {
        guard let chat else { return "" }
        switch chat.kind {
        case .direct: return "Р»РѕРєР°Р»СЊРЅС‹Р№ С‡Р°С‚"
        case .group: return Format.members(chat.memberIds.count)
        case .channel: return "РєР°РЅР°Р»"
        }
    }

    // MARK: - РЎРїРёСЃРѕРє СЃРѕРѕР±С‰РµРЅРёР№

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if messages.isEmpty {
                        VStack(spacing: 8) {
                            Text("РЎРѕРѕР±С‰РµРЅРёР№ РїРѕРєР° РЅРµС‚")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                            Text("РќР°РїРёС€РёС‚Рµ РїРµСЂРІС‹Рј вЂ” СЌС‚Рѕ Р»РѕРєР°Р»СЊРЅС‹Р№ С‡Р°С‚.")
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
                            onLongPress: { actionMessage = message }
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

    private func pinnedBar(_ message: Message) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Theme.accentBright)
                .frame(width: 2)
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 1) {
                Text("Р—Р°РєСЂРµРїР»С‘РЅРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ")
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
        .background(Theme.panel.opacity(0.95))
    }

    // MARK: - РџРѕР»Рµ РІРІРѕРґР°

    private var composer: some View {
        VStack(spacing: 0) {
            if let editing {
                HStack(spacing: 10) {
                    Image(systemName: "pencil")
                        .foregroundColor(Theme.accentBright)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Р РµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ")
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

            HStack(alignment: .bottom, spacing: 8) {
                Button {
                    showAttach = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 36, height: 38)
                }

                TextField(isChannel ? "РќР°РїРёСЃР°С‚СЊ РІ РєР°РЅР°Р»вЂ¦" : "РЎРѕРѕР±С‰РµРЅРёРµ", text: $draft, axis: .vertical)
                    .lineLimit(1...6)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.background)
                    )
                    .focused($inputFocused)

                Button(action: submit) {
                    Image(systemName: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          ? (editing == nil ? "mic.fill" : "checkmark")
                          : "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.accent))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && editing == nil)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Theme.panel)
        }
        .confirmationDialog("Р’Р»РѕР¶РµРЅРёРµ", isPresented: $showAttach) {
            Button("Р¤РѕС‚Рѕ РёР»Рё РІРёРґРµРѕ") { showToast("Р›РѕРєР°Р»СЊРЅС‹Р№ СЂРµР¶РёРј: РІР»РѕР¶РµРЅРёСЏ РЅРµ РѕС‚РїСЂР°РІР»СЏСЋС‚СЃСЏ") }
            Button("Р”РѕРєСѓРјРµРЅС‚") { showToast("Р›РѕРєР°Р»СЊРЅС‹Р№ СЂРµР¶РёРј: РІР»РѕР¶РµРЅРёСЏ РЅРµ РѕС‚РїСЂР°РІР»СЏСЋС‚СЃСЏ") }
            Button("Р“РµРѕР»РѕРєР°С†РёСЏ") { showToast("Р›РѕРєР°Р»СЊРЅС‹Р№ СЂРµР¶РёРј: РіРµРѕР»РѕРєР°С†РёСЏ РЅРµРґРѕСЃС‚СѓРїРЅР°") }
            Button("РћС‚РјРµРЅР°", role: .cancel) {}
        }
    }

    private func submit() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showToast("Р“РѕР»РѕСЃРѕРІС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ РїРѕСЏРІСЏС‚СЃСЏ РїРѕР·Р¶Рµ")
            return
        }
        if let editing {
            env.editMessage(id: editing.id, text: text)
            self.editing = nil
        } else {
            env.sendMessage(chatId: chatId, text: text)
        }
        draft = ""
        inputFocused = true
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

/// РџСѓР·С‹СЂСЊ СЃРѕРѕР±С‰РµРЅРёСЏ.
struct MessageBubble: View {
    let message: Message
    let isMine: Bool
    let isGroup: Bool
    let showAuthor: Bool
    let onLongPress: () -> Void

    private var bubbleColor: Color {
        message.kind == .service ? Theme.panelElevated.opacity(0.9) : (isMine ? Theme.bubbleMine : Theme.bubbleTheirs)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMine { Spacer(minLength: 50) }

            if !isMine && isGroup {
                AvatarView(title: message.authorName, colorHex: Palette.blue, size: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                if !isMine && isGroup && showAuthor {
                    Text(message.authorName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.accentBright)
                }
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textPrimary)
                    .textSelection(.enabled)

                HStack(spacing: 4) {
                    if message.isPinned {
                        Image(systemName: "pin.fill").font(.system(size: 9))
                    }
                    if message.isEdited {
                        Text("РёР·Рј.").font(.system(size: 10))
                    }
                    Text(Format.time(message.createdAt)).font(.system(size: 10.5))
                    if isMine {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accentBright)
                    }
                }
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bubbleColor)
            )
            .overlay(alignment: isMine ? .bottomTrailing : .bottomLeading) {
                Circle()
                    .fill(bubbleColor)
                    .frame(width: 12, height: 12)
                    .offset(x: isMine ? 4 : -4, y: 4)
                    .clipped()
            }
            .contextMenu {
                Button(action: onLongPress) {
                    Label("Р”РµР№СЃС‚РІРёСЏ", systemImage: "ellipsis.circle")
                }
            }
            .onLongPressGesture { onLongPress() }

            if !isMine { Spacer(minLength: 50) }
        }
        .padding(.vertical, 1)
    }
}

