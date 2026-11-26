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
                text: "\(gift.emoji) \(gift.name) — \(gift.price) ⭐️",
                createdAt: Date(),
                editedAt: nil,
                isPinned: false,
                kind: .text
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
