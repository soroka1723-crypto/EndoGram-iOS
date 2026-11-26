import Foundation

/// Контракт источника данных.
///
/// Сейчас единственная реализация — `LocalBackend`: она держит всё в JSON-файле
/// на устройстве и не делает ни одного сетевого запроса. Когда появится сервер
/// EndoGram, достаточно добавить вторую реализацию (`RemoteBackend`) и подменить
/// её в `AppEnvironment` — интерфейс экранов не меняется.
protocol EndoBackend: AnyObject {
    var snapshot: StoreSnapshot { get }

    func bootstrap() -> StoreSnapshot
    func persist()

    func sendMessage(chatId: String, text: String, replyToId: String?) -> Message
    func sendVoiceMessage(chatId: String, fileName: String, duration: Double, waveform: [Double]) -> Message
    func setReaction(messageId: String, emoji: String?)
    func forwardMessage(id: String, toChatId: String) -> Message?
    /// Массовая пересылка выбранных сообщений.
    func forwardMessages(ids: [String], toChatId: String) -> [Message]
    func deleteMessages(ids: [String])
    func savedMessagesChat() -> Chat
    func editMessage(id: String, text: String)
    func deleteMessage(id: String)
    func togglePinMessage(id: String)
    func markChatRead(chatId: String)
    func markChatUnread(chatId: String)

    func createDirectChat(peer: UserProfile) -> Chat
    func createGroup(title: String, memberIds: [String]) -> Chat
    func createChannel(title: String, about: String) -> Chat
    func setArchived(chatId: String, archived: Bool)
    func setPinned(chatId: String, pinned: Bool)
    func setMuted(chatId: String, muted: Bool)
    /// Свои обои для чата. nil — вернуть обои из общих настроек.
    func setChatWallpaper(chatId: String, style: String?)
    func deleteChat(chatId: String)

    func addContact(displayName: String, username: String, phone: String) -> UserProfile
    func updateProfile(displayName: String, username: String, bio: String)
    /// «Ваш цвет» — `Settings_YourColor` из профиля Telegram.
    func setProfileColor(_ hex: String)

    func buyGift(_ gift: Gift, toChatId: String?) -> OwnedGift?
    func buyNFT(_ item: NFTItem) -> OwnedNFT?
    func activatePremium() -> Bool
    func grantStars(_ amount: Int, title: String)
    func transferStars(_ amount: Int, to name: String)

    func createFolder(title: String, icon: String, chatIds: [String]) -> ChatFolder
    func logCall(peerName: String, isVideo: Bool, isOutgoing: Bool, isMissed: Bool, duration: TimeInterval)

    func updateSettings(_ settings: AppSettings)
    func resetAccount()
}
