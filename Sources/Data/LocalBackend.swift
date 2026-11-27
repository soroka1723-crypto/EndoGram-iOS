import Foundation

/// Локальное хранилище: один JSON-файл в песочнице приложения.
///
/// Никаких сетевых вызовов: и чтение, и запись идут на диск устройства,
/// поэтому приложение полностью работает в авиарежиме.
final class LocalBackend: EndoBackend {

    private(set) var snapshot: StoreSnapshot
    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?

    init(fileURL: URL? = nil) {
        let directory = fileURL?.deletingLastPathComponent() ?? LocalBackend.defaultDirectory()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = fileURL ?? directory.appendingPathComponent(AppConfig.storageFile)
        self.snapshot = Seed.makeInitialSnapshot()
    }

    static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("EndoGram", isDirectory: true)
    }

    var storagePath: String { fileURL.path }

    var fileSizeBytes: Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
    }

    // MARK: - Загрузка и сохранение

    func bootstrap() -> StoreSnapshot {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder.endogram.decode(StoreSnapshot.self, from: data) {
            snapshot = decoded
            applyLaunchMaintenance()
        } else {
            snapshot = Seed.makeInitialSnapshot()
            persistNow()
        }
        return snapshot
    }

    /// Правки, которые должны происходить при каждом запуске.
    private func applyLaunchMaintenance() {
        // Снимаем флаг Premium, если срок истёк, и сообщаем об этом в истории.
        if snapshot.profile.isPremium, !snapshot.profile.premiumActive {
            snapshot.profile.isPremium = false
            snapshot.profile.premiumUntil = nil
            appendLedger(kind: .premium, title: "Premium истёк", amount: 0)
        }
        // История живёт 24 часа — как в Telegram, дальше уходит в архив.
        for index in snapshot.stories.indices
        where snapshot.stories[index].isExpired && !snapshot.stories[index].isArchived {
            snapshot.stories[index].isArchived = true
        }
        snapshot.updatedAt = Date()
        persist()
    }

    func persist() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.persistNow() }
        saveWorkItem = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    private func persistNow() {
        snapshot.updatedAt = Date()
        guard let data = try? JSONEncoder.endogram.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Сообщения

    func sendMessage(chatId: String, text: String, replyToId: String?) -> Message {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = Message(
            id: IDs.next("msg"),
            chatId: chatId,
            senderId: snapshot.profile.id,
            authorName: snapshot.profile.displayName,
            text: trimmed,
            createdAt: Date(),
            editedAt: nil,
            isPinned: false,
            kind: .text,
            isRead: true,
            replyToId: replyToId,
            reaction: nil
        )
        snapshot.messages.append(message)
        if let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) {
            snapshot.chats[index].lastReadAt = message.createdAt
        }
        snapshot.updatedAt = Date()
        persist()
        return message
    }

    func setReaction(messageId: String, emoji: String?) {
        guard let index = snapshot.messages.firstIndex(where: { $0.id == messageId }) else { return }
        snapshot.messages[index].reaction = emoji
        persist()
    }

    /// Голосовое сообщение: файл уже записан в песочницу, здесь только запись в базу.
    @discardableResult
    func sendVoiceMessage(chatId: String, fileName: String, duration: Double, waveform: [Double]) -> Message {
        let message = Message(
            id: IDs.next("msg"),
            chatId: chatId,
            senderId: snapshot.profile.id,
            authorName: snapshot.profile.displayName,
            text: "",
            createdAt: Date(),
            editedAt: nil,
            isPinned: false,
            kind: .voice,
            isRead: true,
            replyToId: nil,
            reaction: nil,
            forwardedFrom: nil,
            voiceFileName: fileName,
            voiceDuration: duration,
            voiceWaveform: waveform
        )
        snapshot.messages.append(message)
        if let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) {
            snapshot.chats[index].lastReadAt = message.createdAt
        }
        snapshot.updatedAt = Date()
        persist()
        return message
    }

    /// Фото или видео: файл уже скопирован в песочницу, здесь только запись в базу.
    @discardableResult
    func sendMediaMessage(chatId: String, fileName: String, kind: MessageKind,
                          duration: Double?, caption: String, replyToId: String?) -> Message {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = Message(
            id: IDs.next("msg"),
            chatId: chatId,
            senderId: snapshot.profile.id,
            authorName: snapshot.profile.displayName,
            text: trimmed,
            createdAt: Date(),
            editedAt: nil,
            isPinned: false,
            kind: kind,
            isRead: true,
            replyToId: replyToId,
            reaction: nil,
            forwardedFrom: nil,
            voiceFileName: nil,
            voiceDuration: nil,
            voiceWaveform: nil,
            mediaFileName: fileName,
            mediaDuration: duration
        )
        snapshot.messages.append(message)
        if let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) {
            snapshot.chats[index].lastReadAt = message.createdAt
        }
        snapshot.updatedAt = Date()
        persist()
        return message
    }

    /// Пересылка: копия сообщения с подписью автора — как `forward` в Telegram.
    func forwardMessage(id: String, toChatId: String) -> Message? {
        forwardMessages(ids: [id], toChatId: toChatId).first
    }

    /// Массовая пересылка — как выбор нескольких сообщений в Telegram.
    func forwardMessages(ids: [String], toChatId: String) -> [Message] {
        var forwards: [Message] = []
        for id in ids {
            guard let source = snapshot.messages.first(where: { $0.id == id }) else { continue }
            let forwarded = Message(
                id: IDs.next("msg"),
                chatId: toChatId,
                senderId: snapshot.profile.id,
                authorName: snapshot.profile.displayName,
                text: source.text,
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: source.kind,
                isRead: true,
                replyToId: nil,
                reaction: nil,
                forwardedFrom: source.senderId == snapshot.profile.id ? snapshot.profile.displayName : source.authorName,
                voiceFileName: source.voiceFileName,
                voiceDuration: source.voiceDuration,
                voiceWaveform: source.voiceWaveform,
                mediaFileName: source.mediaFileName,
                mediaDuration: source.mediaDuration
            )
            snapshot.messages.append(forwarded)
            forwards.append(forwarded)
        }
        guard !forwards.isEmpty else { return [] }
        if let index = snapshot.chats.firstIndex(where: { $0.id == toChatId }) {
            snapshot.chats[index].lastReadAt = forwards.last?.createdAt
        }
        snapshot.updatedAt = Date()
        persist()
        return forwards
    }

    /// «Избранное» — чат с самим собой, как Saved Messages в Telegram.
    func savedMessagesChat() -> Chat {
        if let existing = snapshot.chats.first(where: { $0.kind == .direct && $0.peerId == snapshot.profile.id }) {
            return existing
        }
        let chat = Chat(
            id: IDs.next("chat"),
            kind: .direct,
            title: "Избранное",
            avatarColor: Palette.avatarColors.first ?? Palette.blue,
            peerId: snapshot.profile.id,
            memberIds: [snapshot.profile.id],
            createdAt: Date(),
            isArchived: false,
            isPinned: false,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: Date()
        )
        snapshot.chats.append(chat)
        snapshot.messages.append(
            Message(
                id: IDs.next("msg"),
                chatId: chat.id,
                senderId: snapshot.profile.id,
                authorName: snapshot.profile.displayName,
                text: "Это «Избранное»: заметки и пересланные сообщения хранятся только на этом устройстве.",
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: .service
            )
        )
        persist()
        return chat
    }

    func editMessage(id: String, text: String) {
        guard let index = snapshot.messages.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        snapshot.messages[index].text = trimmed
        snapshot.messages[index].editedAt = Date()
        persist()
    }

    func deleteMessage(id: String) {
        snapshot.messages.removeAll { $0.id == id }
        persist()
    }

    func deleteMessages(ids: [String]) {
        guard !ids.isEmpty else { return }
        let removing = Set(ids)
        snapshot.messages.removeAll { removing.contains($0.id) }
        persist()
    }

    func togglePinMessage(id: String) {
        guard let index = snapshot.messages.firstIndex(where: { $0.id == id }) else { return }
        let chatId = snapshot.messages[index].chatId
        let newValue = !snapshot.messages[index].isPinned
        for i in snapshot.messages.indices where snapshot.messages[i].chatId == chatId {
            snapshot.messages[i].isPinned = false
        }
        snapshot.messages[index].isPinned = newValue
        persist()
    }

    func markChatRead(chatId: String) {
        guard let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) else { return }
        snapshot.chats[index].unreadCount = 0
        snapshot.chats[index].lastReadAt = Date()
        persist()
    }

    func markChatUnread(chatId: String) {
        guard let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) else { return }
        snapshot.chats[index].unreadCount = max(1, snapshot.chats[index].unreadCount)
        persist()
    }

    // MARK: - Чаты

    func createDirectChat(peer: UserProfile) -> Chat {
        if let existing = snapshot.chats.first(where: { $0.kind == .direct && $0.peerId == peer.id }) {
            return existing
        }
        let chat = Chat(
            id: IDs.next("chat"),
            kind: .direct,
            title: peer.displayName,
            avatarColor: peer.avatarColor,
            peerId: peer.id,
            memberIds: [snapshot.profile.id, peer.id],
            createdAt: Date(),
            isArchived: false,
            isPinned: false,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: Date()
        )
        snapshot.chats.append(chat)
        snapshot.messages.append(
            Message(
                id: IDs.next("msg"),
                chatId: chat.id,
                senderId: snapshot.profile.id,
                authorName: snapshot.profile.displayName,
                text: "Локальный тестовый чат с «\(peer.displayName)». Сообщения сохраняются только на этом устройстве.",
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: .service
            )
        )
        persist()
        return chat
    }

    func createGroup(title: String, memberIds: [String]) -> Chat {
        let chat = Chat(
            id: IDs.next("chat"),
            kind: .group,
            title: title,
            avatarColor: Palette.avatarColors.randomElement() ?? Palette.green,
            peerId: nil,
            memberIds: [snapshot.profile.id] + memberIds,
            createdAt: Date(),
            isArchived: false,
            isPinned: false,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: Date()
        )
        snapshot.chats.append(chat)
        snapshot.messages.append(
            Message(
                id: IDs.next("msg"),
                chatId: chat.id,
                senderId: "system",
                authorName: "EndoGram",
                text: "Группа «\(title)» создана локально. Участников: \(chat.memberIds.count).",
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: .service
            )
        )
        persist()
        return chat
    }

    func createChannel(title: String, about: String) -> Chat {
        let chat = Chat(
            id: IDs.next("chat"),
            kind: .channel,
            title: title,
            avatarColor: Palette.avatarColors.randomElement() ?? Palette.purple,
            peerId: nil,
            memberIds: [snapshot.profile.id],
            createdAt: Date(),
            isArchived: false,
            isPinned: false,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: Date()
        )
        snapshot.chats.append(chat)
        snapshot.messages.append(
            Message(
                id: IDs.next("msg"),
                chatId: chat.id,
                senderId: "system",
                authorName: "EndoGram",
                text: about.isEmpty ? "Канал «\(title)» создан локально." : about,
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: .service
            )
        )
        persist()
        return chat
    }

    func setArchived(chatId: String, archived: Bool) {
        guard let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) else { return }
        snapshot.chats[index].isArchived = archived
        if archived { snapshot.chats[index].isPinned = false }
        persist()
    }

    func setPinned(chatId: String, pinned: Bool) {
        guard let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) else { return }
        snapshot.chats[index].isPinned = pinned
        persist()
    }

    func setMuted(chatId: String, muted: Bool) {
        guard let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) else { return }
        snapshot.chats[index].isMuted = muted
        persist()
    }

    func setChatWallpaper(chatId: String, style: String?) {
        guard let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) else { return }
        snapshot.chats[index].wallpaperId = style
        persist()
    }

    func deleteChat(chatId: String) {
        snapshot.chats.removeAll { $0.id == chatId }
        snapshot.messages.removeAll { $0.chatId == chatId }
        for index in snapshot.folders.indices {
            snapshot.folders[index].chatIds.removeAll { $0 == chatId }
        }
        persist()
    }

    // MARK: - Контакты и профиль

    func addContact(displayName: String, username: String, phone: String) -> UserProfile {
        let contact = UserProfile(
            id: IDs.next("user"),
            username: username.isEmpty ? "user_" + IDs.randomToken(length: 5) : username,
            displayName: displayName,
            bio: "",
            phone: phone,
            avatarColor: Palette.avatarColors.randomElement() ?? Palette.blue,
            createdAt: Date(),
            isPremium: false,
            premiumUntil: nil
        )
        snapshot.contacts.append(contact)
        persist()
        return contact
    }

    func updateProfile(displayName: String, username: String, bio: String) {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { snapshot.profile.displayName = name }
        let handle = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !handle.isEmpty { snapshot.profile.username = handle }
        snapshot.profile.bio = bio
        // Имя в «Избранном» всегда совпадает с профилем.
        if let index = snapshot.chats.firstIndex(where: { $0.peerId == snapshot.profile.id }) {
            snapshot.chats[index].title = snapshot.profile.displayName
        }
        persist()
    }

    func setProfileColor(_ hex: String) {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        snapshot.settings.profileColor = value
        // Цвет применяется и к аватару, чтобы выбор был виден сразу везде.
        if value == "auto" {
            snapshot.profile.avatarColor = Palette.peerColor(for: snapshot.profile.displayName)
        } else if !value.isEmpty {
            snapshot.profile.avatarColor = value
        }
        persist()
    }

    // MARK: - Экономика

    func buyGift(_ gift: Gift, toChatId: String?) -> OwnedGift? {
        guard snapshot.stars >= gift.price else { return nil }
        let owned = OwnedGift(
            id: IDs.next("owned"),
            giftId: gift.id,
            name: gift.name,
            emoji: gift.emoji,
            rarity: gift.rarity,
            colorHex: gift.colorHex,
            pricePaid: gift.price,
            receivedAt: Date(),
            fromName: snapshot.profile.displayName,
            chatId: toChatId
        )
        snapshot.stars -= gift.price
        snapshot.ownedGifts.append(owned)
        appendLedger(kind: .gift, title: "Подарок: \(gift.name)", amount: -gift.price)

        if let chatId = toChatId, let index = snapshot.chats.firstIndex(where: { $0.id == chatId }) {
            let message = Message(
                id: IDs.next("msg"),
                chatId: chatId,
                senderId: snapshot.profile.id,
                authorName: snapshot.profile.displayName,
                text: gift.name,
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: .gift,
                giftId: gift.id
            )
            snapshot.messages.append(message)
            snapshot.chats[index].lastReadAt = message.createdAt
        }
        persist()
        return owned
    }

    func buyNFT(_ item: NFTItem) -> OwnedNFT? {
        guard snapshot.stars >= item.price else { return nil }
        let owned = OwnedNFT(
            id: IDs.next("ownednft"),
            itemId: item.id,
            name: item.name,
            collection: item.collection,
            emoji: item.emoji,
            rarity: item.rarity,
            colorHex: item.colorHex,
            serial: item.serial,
            totalSupply: item.totalSupply,
            pricePaid: item.price,
            acquiredAt: Date()
        )
        snapshot.stars -= item.price
        snapshot.ownedNFTs.append(owned)
        appendLedger(kind: .nft, title: "NFT: \(item.name) #\(item.serial)", amount: -item.price)
        persist()
        return owned
    }

    func activatePremium() -> Bool {
        let alreadyActive = snapshot.profile.premiumActive
        if !alreadyActive {
            guard snapshot.stars >= AppConfig.premiumPrice else { return false }
            snapshot.stars -= AppConfig.premiumPrice
            appendLedger(kind: .premium, title: "EndoGram Premium на год", amount: -AppConfig.premiumPrice)
        }
        snapshot.profile.isPremium = true
        snapshot.profile.premiumUntil = Calendar.current.date(
            byAdding: .day,
            value: AppConfig.premiumDays,
            to: Date()
        )
        persist()
        return true
    }

    func grantStars(_ amount: Int, title: String) {
        guard amount != 0 else { return }
        snapshot.stars += amount
        appendLedger(kind: .grant, title: title, amount: amount)
        persist()
    }

    func transferStars(_ amount: Int, to name: String) {
        guard amount > 0, snapshot.stars >= amount else { return }
        snapshot.stars -= amount
        appendLedger(kind: .transfer, title: "Перевод: \(name)", amount: -amount)
        persist()
    }

    private func appendLedger(kind: LedgerKind, title: String, amount: Int) {
        snapshot.ledger.append(
            LedgerEntry(
                id: IDs.next("ledger"),
                kind: kind,
                title: title,
                amount: amount,
                createdAt: Date(),
                balanceAfter: snapshot.stars
            )
        )
    }

    // MARK: - Папки, звонки, настройки

    func createFolder(title: String, icon: String, chatIds: [String]) -> ChatFolder {
        let folder = ChatFolder(
            id: IDs.next("folder"),
            title: title,
            icon: icon,
            chatIds: chatIds,
            isSystem: false
        )
        snapshot.folders.append(folder)
        persist()
        return folder
    }

    func logCall(peerName: String, isVideo: Bool, isOutgoing: Bool, isMissed: Bool, duration: TimeInterval) {
        snapshot.calls.insert(
            CallRecord(
                id: IDs.next("call"),
                peerName: peerName,
                isVideo: isVideo,
                isOutgoing: isOutgoing,
                isMissed: isMissed,
                startedAt: Date(),
                duration: duration
            ),
            at: 0
        )
        persist()
    }

    // MARK: - Истории

    func addStory(caption: String, colorHex: String, privacy: String, mediaFileName: String?, mediaKind: String?, mediaDuration: Double?) -> Story {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let story = Story(
            id: IDs.next("story"),
            authorName: snapshot.profile.displayName,
            caption: trimmed,
            colorHex: colorHex,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 3600),
            isArchived: false,
            views: 0,
            lastViewedAt: nil,
            privacy: privacy,
            mediaFileName: mediaFileName,
            mediaKind: mediaKind,
            mediaDuration: mediaDuration
        )
        snapshot.stories.insert(story, at: 0)
        appendLedger(kind: .grant, title: "История опубликована", amount: 0)
        persist()
        return story
    }

    func deleteStory(id: String) {
        // Медиа истории удаляем вместе с записью, чтобы файлы не копились.
        if let story = snapshot.stories.first(where: { $0.id == id }),
           let fileName = story.mediaFileName {
            StoryMediaStorage.delete(fileName: fileName)
        }
        snapshot.stories.removeAll { $0.id == id }
        persist()
    }

    func setStoryArchived(id: String, archived: Bool) {
        guard let index = snapshot.stories.firstIndex(where: { $0.id == id }) else { return }
        snapshot.stories[index].isArchived = archived
        persist()
    }

    func markStoryViewed(id: String) {
        guard let index = snapshot.stories.firstIndex(where: { $0.id == id }) else { return }
        snapshot.stories[index].views += 1
        snapshot.stories[index].lastViewedAt = Date()
        persist()
    }

    func updateSettings(_ settings: AppSettings) {
        snapshot.settings = settings
        persist()
    }

    func resetAccount() {
        snapshot = Seed.makeInitialSnapshot()
        persistNow()
    }
}

// MARK: - Кодирование дат

extension JSONEncoder {
    static let endogram: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

extension JSONDecoder {
    static let endogram: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
