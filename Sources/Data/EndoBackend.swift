import Foundation

/// РљРѕРЅС‚СЂР°РєС‚ РёСЃС‚РѕС‡РЅРёРєР° РґР°РЅРЅС‹С….
///
/// РЎРµР№С‡Р°СЃ РµРґРёРЅСЃС‚РІРµРЅРЅР°СЏ СЂРµР°Р»РёР·Р°С†РёСЏ вЂ” `LocalBackend`: РѕРЅР° РґРµСЂР¶РёС‚ РІСЃС‘ РІ JSON-С„Р°Р№Р»Рµ
/// РЅР° СѓСЃС‚СЂРѕР№СЃС‚РІРµ Рё РЅРµ РґРµР»Р°РµС‚ РЅРё РѕРґРЅРѕРіРѕ СЃРµС‚РµРІРѕРіРѕ Р·Р°РїСЂРѕСЃР°. РљРѕРіРґР° РїРѕСЏРІРёС‚СЃСЏ СЃРµСЂРІРµСЂ
/// EndoGram, РґРѕСЃС‚Р°С‚РѕС‡РЅРѕ РґРѕР±Р°РІРёС‚СЊ РІС‚РѕСЂСѓСЋ СЂРµР°Р»РёР·Р°С†РёСЋ (`RemoteBackend`) Рё РїРѕРґРјРµРЅРёС‚СЊ
/// РµС‘ РІ `AppEnvironment` вЂ” РёРЅС‚РµСЂС„РµР№СЃ СЌРєСЂР°РЅРѕРІ РЅРµ РјРµРЅСЏРµС‚СЃСЏ.
protocol EndoBackend: AnyObject {
    var snapshot: StoreSnapshot { get }

    func bootstrap() -> StoreSnapshot
    func persist()

    func sendMessage(chatId: String, text: String) -> Message
    func editMessage(id: String, text: String)
    func deleteMessage(id: String)
    func togglePinMessage(id: String)
    func markChatRead(chatId: String)

    func createDirectChat(peer: UserProfile) -> Chat
    func createGroup(title: String, memberIds: [String]) -> Chat
    func createChannel(title: String, about: String) -> Chat
    func setArchived(chatId: String, archived: Bool)
    func setPinned(chatId: String, pinned: Bool)
    func setMuted(chatId: String, muted: Bool)
    func deleteChat(chatId: String)

    func addContact(displayName: String, username: String) -> UserProfile
    func updateProfile(displayName: String, username: String, bio: String)

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

