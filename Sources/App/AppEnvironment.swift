import Foundation
import SwiftUI

/// Единая точка доступа к данным для всех экранов.
///
/// Экраны знают только про `EndoBackend`. Чтобы позже подключить сервер EndoGram,
/// достаточно передать сюда `RemoteBackend` — код интерфейса останется прежним.
@MainActor
final class AppEnvironment: ObservableObject {

    @Published private(set) var snapshot: StoreSnapshot

    let backend: EndoBackend

    init(backend: EndoBackend = LocalBackend()) {
        self.backend = backend
        self.snapshot = backend.bootstrap()
    }

    // MARK: - Производные данные

    var profile: UserProfile { snapshot.profile }
    var stars: Int { snapshot.stars }
    var giftCatalog: [Gift] { Seed.giftCatalog }
    var nftCatalog: [NFTItem] { Seed.nftCatalog }

    var activeChats: [Chat] {
        snapshot.chats.filter { !$0.isArchived }
    }

    var archivedChats: [Chat] {
        snapshot.chats.filter(\.isArchived)
    }

    var pinnedChats: [Chat] {
        sorted(activeChats.filter(\.isPinned))
    }

    var regularChats: [Chat] {
        sorted(activeChats.filter { !$0.isPinned })
    }

    var totalUnread: Int {
        snapshot.chats.reduce(0) { $0 + $1.unreadCount }
    }

    func sorted(_ chats: [Chat]) -> [Chat] {
        chats.sorted { lhs, rhs in
            let left = lastMessage(in: lhs.id)?.createdAt ?? lhs.createdAt
            let right = lastMessage(in: rhs.id)?.createdAt ?? rhs.createdAt
            return left > right
        }
    }

    func chat(_ id: String) -> Chat? {
        snapshot.chats.first { $0.id == id }
    }

    func contact(_ id: String) -> UserProfile? {
        snapshot.contacts.first { $0.id == id }
    }

    func messages(in chatId: String) -> [Message] {
        snapshot.messages
            .filter { $0.chatId == chatId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func lastMessage(in chatId: String) -> Message? {
        messages(in: chatId).last
    }

    func pinnedMessage(in chatId: String) -> Message? {
        messages(in: chatId).last { $0.isPinned }
    }

    func chats(for folder: ChatFolder) -> [Chat] {
        let base: [Chat]
        switch folder.id {
        case "folder.all":
            base = activeChats
        case "folder.personal":
            base = activeChats.filter { $0.kind == .direct }
        case "folder.groups":
            base = activeChats.filter { $0.kind == .group }
        case "folder.channels":
            base = activeChats.filter { $0.kind == .channel }
        default:
            base = snapshot.chats.filter { folder.chatIds.contains($0.id) }
        }
        return sorted(base)
    }

    func unread(in folder: ChatFolder) -> Int {
        chats(for: folder).reduce(0) { $0 + $1.unreadCount }
    }

    var nonSystemFolders: [ChatFolder] {
        snapshot.folders.filter { !$0.isSystem }
    }

    var ledger: [LedgerEntry] {
        snapshot.ledger.sorted { $0.createdAt > $1.createdAt }
    }

    var storageDescription: String {
        guard let local = backend as? LocalBackend else { return "локальное хранилище" }
        let bytes = local.fileSizeBytes
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Перерисовка после действий

    private func refresh() {
        snapshot = backend.snapshot
    }

    // MARK: - Действия

    @discardableResult
    func sendMessage(chatId: String, text: String, replyToId: String? = nil) -> Message {
        let message = backend.sendMessage(chatId: chatId, text: text, replyToId: replyToId)
        refresh()
        return message
    }

    func setReaction(messageId: String, emoji: String?) {
        backend.setReaction(messageId: messageId, emoji: emoji)
        refresh()
    }

    func editMessage(id: String, text: String) {
        backend.editMessage(id: id, text: text)
        refresh()
    }

    func deleteMessage(id: String) {
        backend.deleteMessage(id: id)
        refresh()
    }

    func togglePin(messageId: String) {
        backend.togglePinMessage(id: messageId)
        refresh()
    }

    func markRead(chatId: String) {
        guard chat(chatId)?.unreadCount ?? 0 > 0 else { return }
        backend.markChatRead(chatId: chatId)
        refresh()
    }

    func openDirectChat(with contact: UserProfile) -> Chat {
        let chat = backend.createDirectChat(peer: contact)
        refresh()
        return chat
    }

    func createGroup(title: String, memberIds: [String]) -> Chat {
        let chat = backend.createGroup(title: title, memberIds: memberIds)
        refresh()
        return chat
    }

    func createChannel(title: String, about: String) -> Chat {
        let chat = backend.createChannel(title: title, about: about)
        refresh()
        return chat
    }

    func setArchived(_ chatId: String, _ archived: Bool) {
        backend.setArchived(chatId: chatId, archived: archived)
        refresh()
    }

    func setPinned(_ chatId: String, _ pinned: Bool) {
        backend.setPinned(chatId: chatId, pinned: pinned)
        refresh()
    }

    func setMuted(_ chatId: String, _ muted: Bool) {
        backend.setMuted(chatId: chatId, muted: muted)
        refresh()
    }

    func deleteChat(_ chatId: String) {
        backend.deleteChat(chatId: chatId)
        refresh()
    }

    func addContact(displayName: String, username: String, phone: String = "") -> UserProfile {
        let contact = backend.addContact(displayName: displayName, username: username, phone: phone)
        refresh()
        return contact
    }

    func updateProfile(displayName: String, username: String, bio: String) {
        backend.updateProfile(displayName: displayName, username: username, bio: bio)
        refresh()
    }

    /// Покупка подарка. Возвращает текст ошибки или nil при успехе.
    func buyGift(_ gift: Gift, toChatId: String?) -> String? {
        guard stars >= gift.price else { return "Недостаточно звёзд: нужно \(Format.stars(gift.price))" }
        _ = backend.buyGift(gift, toChatId: toChatId)
        refresh()
        return nil
    }

    func buyNFT(_ item: NFTItem) -> String? {
        guard stars >= item.price else { return "Недостаточно звёзд: нужно \(Format.stars(item.price))" }
        _ = backend.buyNFT(item)
        refresh()
        return nil
    }

    func activatePremium() -> String? {
        if !profile.premiumActive, stars < AppConfig.premiumPrice {
            return "Недостаточно звёзд: нужно \(Format.stars(AppConfig.premiumPrice))"
        }
        _ = backend.activatePremium()
        refresh()
        return nil
    }

    func grantStars(_ amount: Int, title: String) {
        backend.grantStars(amount, title: title)
        refresh()
    }

    func transferStars(_ amount: Int, to name: String) {
        backend.transferStars(amount, to: name)
        refresh()
    }

    func createFolder(title: String, icon: String, chatIds: [String]) {
        _ = backend.createFolder(title: title, icon: icon, chatIds: chatIds)
        refresh()
    }

    func logCall(peerName: String, isVideo: Bool, isOutgoing: Bool, isMissed: Bool, duration: TimeInterval) {
        backend.logCall(peerName: peerName, isVideo: isVideo, isOutgoing: isOutgoing, isMissed: isMissed, duration: duration)
        refresh()
    }

    func updateSettings(_ transform: (inout AppSettings) -> Void) {
        var settings = snapshot.settings
        transform(&settings)
        backend.updateSettings(settings)
        refresh()
    }

    func resetAccount() {
        backend.resetAccount()
        refresh()
    }
}
