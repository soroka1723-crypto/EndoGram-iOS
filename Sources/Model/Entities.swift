import Foundation

// MARK: - Пользователь

struct UserProfile: Codable, Identifiable, Hashable {
    var id: String
    var username: String
    var displayName: String
    var bio: String
    var phone: String
    var avatarColor: String
    var createdAt: Date
    var isPremium: Bool
    var premiumUntil: Date?

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        if parts.isEmpty { return "?" }
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var premiumActive: Bool {
        guard isPremium, let until = premiumUntil else { return false }
        return until > Date()
    }
}

// MARK: - Чаты

enum ChatKind: String, Codable, CaseIterable {
    case direct
    case group
    case channel

    var title: String {
        switch self {
        case .direct: return "Личный чат"
        case .group: return "Группа"
        case .channel: return "Канал"
        }
    }

    var icon: String {
        switch self {
        case .direct: return "person.fill"
        case .group: return "person.2.fill"
        case .channel: return "megaphone.fill"
        }
    }
}

struct Chat: Codable, Identifiable, Hashable {
    var id: String
    var kind: ChatKind
    var title: String
    var avatarColor: String
    /// Для личных чатов — id собеседника из локальной адресной книги.
    var peerId: String?
    var memberIds: [String]
    var createdAt: Date
    var isArchived: Bool
    var isPinned: Bool
    var isMuted: Bool
    var folderId: String?
    var unreadCount: Int
    var lastReadAt: Date?

    var subtitle: String {
        switch kind {
        case .direct: return "личный чат"
        case .group: return "\(memberIds.count) участников"
        case .channel: return "канал"
        }
    }
}

struct ChatFolder: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var icon: String
    var chatIds: [String]
    var isSystem: Bool = false
}

// MARK: - Сообщения

enum MessageKind: String, Codable {
    case text
    case service
}

struct Message: Codable, Identifiable, Hashable {
    var id: String
    var chatId: String
    var senderId: String
    var authorName: String
    var text: String
    var createdAt: Date
    var editedAt: Date?
    var isPinned: Bool = false
    var kind: MessageKind = .text
    /// Локальная отметка «прочитано мной» для галочек в канале.
    var isRead: Bool = true
    /// Ответ на сообщение — как `reply_to` в Telegram.
    var replyToId: String? = nil
    /// Реакция на сообщение. Хранится локально, в сеть не уходит.
    var reaction: String? = nil
    /// Имя автора при пересылке — как `forward` в Telegram.
    var forwardedFrom: String? = nil

    var isEdited: Bool { editedAt != nil }
}

// MARK: - Звёзды, подарки, NFT

enum LedgerKind: String, Codable {
    case grant
    case gift
    case nft
    case premium
    case transfer
    case refund

    var title: String {
        switch self {
        case .grant: return "Начисление"
        case .gift: return "Подарок"
        case .nft: return "NFT"
        case .premium: return "Premium"
        case .transfer: return "Перевод"
        case .refund: return "Возврат"
        }
    }

    var icon: String {
        switch self {
        case .grant: return "plus.circle.fill"
        case .gift: return "gift.fill"
        case .nft: return "sparkles"
        case .premium: return "crown.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .refund: return "arrow.uturn.left.circle.fill"
        }
    }
}

struct LedgerEntry: Codable, Identifiable, Hashable {
    var id: String
    var kind: LedgerKind
    var title: String
    var amount: Int
    var createdAt: Date
    var balanceAfter: Int
}

struct Gift: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var emoji: String
    var price: Int
    var rarity: String
    var colorHex: String
}

struct OwnedGift: Codable, Identifiable, Hashable {
    var id: String
    var giftId: String
    var name: String
    var emoji: String
    var rarity: String
    var colorHex: String
    var pricePaid: Int
    var receivedAt: Date
    var fromName: String
    var chatId: String?
}

struct NFTItem: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var collection: String
    var emoji: String
    var price: Int
    var rarity: String
    var colorHex: String
    var serial: Int
    var totalSupply: Int
    var description: String
}

struct OwnedNFT: Codable, Identifiable, Hashable {
    var id: String
    var itemId: String
    var name: String
    var collection: String
    var emoji: String
    var rarity: String
    var colorHex: String
    var serial: Int
    var totalSupply: Int
    var pricePaid: Int
    var acquiredAt: Date
}

// MARK: - Звонки

struct CallRecord: Codable, Identifiable, Hashable {
    var id: String
    var peerName: String
    var isVideo: Bool
    var isOutgoing: Bool
    var isMissed: Bool
    var startedAt: Date
    var duration: TimeInterval
}

// MARK: - Настройки

struct AppSettings: Codable, Hashable {
    // Уведомления и звуки
    var notificationsEnabled: Bool = true
    var soundsEnabled: Bool = true
    var messagePreview: Bool = true
    var privateChatNotifications: Bool = true
    var groupNotifications: Bool = true
    var channelNotifications: Bool = true

    // Внешний вид
    var darkTheme: Bool = true
    var fontSize: Double = 17
    var bubbleCorners: Double = 17
    var wallpaper: String = "telegram"
    var autoNightTheme: String = "off"
    var animationsEnabled: Bool = true
    var showNextMediaOnTap: Bool = true
    var sendWithEnter: Bool = false

    // Конфиденциальность
    var showLastSeen: Bool = true
    var readReceipts: Bool = true
    var lastSeenVisibility: String = "contacts"
    var profilePhotoVisibility: String = "everybody"
    var phoneVisibility: String = "contacts"
    var forwardsVisibility: String = "everybody"
    var passcodeEnabled: Bool = false
    var autoDeleteMessages: String = "off"
    var sensitiveContent: Bool = false
    var messagesVisibility: String = "everybody"
    var callsVisibility: String = "everybody"
    var groupsVisibility: String = "contacts"
    var bioVisibility: String = "contacts"
    var birthdayVisibility: String = "contacts"
    var giftsVisibility: String = "contacts"
    var savedMusicVisibility: String = "contacts"
    var voiceMessagesVisibility: String = "everybody"
    var autoArchiveEnabled: Bool = true

    // Данные и память
    var autoDownloadMedia: Bool = false
    var autoDownloadCellular: Bool = false
    var autoDownloadWiFi: Bool = true
    var autoDownloadReset: Bool = false
    var saveIncomingPhotos: Bool = true
    var saveEditedPhotos: Bool = true
    var keepMedia: String = "month"
    var cacheLimitMb: Double = 2048
    var dataSaverCalls: Bool = false
    var raiseToListen: Bool = true
    var pauseMusicOnRecording: Bool = true

    // Язык и переводы
    var appLanguage: String = "ru"
    var translationsEnabled: Bool = false
    var translateEntireChats: Bool = false

    // Папки
    var folderTags: Bool = false

    // Энергосбережение и прокси
    var energySavingEnabled: Bool = false
    var energySavingAutoDownload: Bool = true
    var proxyEnabled: Bool = false

    // Прочее
    var offlineModeNotice: Bool = true

    /// Декодирование терпимо к отсутствующим полям: старые файлы на устройстве
    /// продолжают читаться после добавления новых настроек.
    init() {}

    private enum CodingKeys: String, CodingKey {
        case notificationsEnabled, soundsEnabled, messagePreview
        case privateChatNotifications, groupNotifications, channelNotifications
        case darkTheme, fontSize, bubbleCorners, wallpaper, autoNightTheme
        case animationsEnabled, showNextMediaOnTap, sendWithEnter
        case showLastSeen, readReceipts, lastSeenVisibility, profilePhotoVisibility
        case phoneVisibility, forwardsVisibility, passcodeEnabled, autoDeleteMessages, sensitiveContent
        case messagesVisibility, callsVisibility, groupsVisibility, bioVisibility, birthdayVisibility
        case giftsVisibility, savedMusicVisibility, voiceMessagesVisibility, autoArchiveEnabled
        case autoDownloadMedia, autoDownloadCellular, autoDownloadWiFi, autoDownloadReset
        case saveIncomingPhotos, saveEditedPhotos, keepMedia, cacheLimitMb
        case dataSaverCalls, raiseToListen, pauseMusicOnRecording
        case appLanguage, translationsEnabled, translateEntireChats
        case folderTags, offlineModeNotice
        case energySavingEnabled, energySavingAutoDownload, proxyEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        notificationsEnabled = c.lenient(.notificationsEnabled, true)
        soundsEnabled = c.lenient(.soundsEnabled, true)
        messagePreview = c.lenient(.messagePreview, true)
        privateChatNotifications = c.lenient(.privateChatNotifications, true)
        groupNotifications = c.lenient(.groupNotifications, true)
        channelNotifications = c.lenient(.channelNotifications, true)

        darkTheme = c.lenient(.darkTheme, true)
        fontSize = c.lenient(.fontSize, 17)
        bubbleCorners = c.lenient(.bubbleCorners, 17)
        wallpaper = c.lenient(.wallpaper, "telegram")
        autoNightTheme = c.lenient(.autoNightTheme, "off")
        animationsEnabled = c.lenient(.animationsEnabled, true)
        showNextMediaOnTap = c.lenient(.showNextMediaOnTap, true)
        sendWithEnter = c.lenient(.sendWithEnter, false)

        showLastSeen = c.lenient(.showLastSeen, true)
        readReceipts = c.lenient(.readReceipts, true)
        lastSeenVisibility = c.lenient(.lastSeenVisibility, "contacts")
        profilePhotoVisibility = c.lenient(.profilePhotoVisibility, "everybody")
        phoneVisibility = c.lenient(.phoneVisibility, "contacts")
        forwardsVisibility = c.lenient(.forwardsVisibility, "everybody")
        passcodeEnabled = c.lenient(.passcodeEnabled, false)
        autoDeleteMessages = c.lenient(.autoDeleteMessages, "off")
        sensitiveContent = c.lenient(.sensitiveContent, false)
        messagesVisibility = c.lenient(.messagesVisibility, "everybody")
        callsVisibility = c.lenient(.callsVisibility, "everybody")
        groupsVisibility = c.lenient(.groupsVisibility, "contacts")
        bioVisibility = c.lenient(.bioVisibility, "contacts")
        birthdayVisibility = c.lenient(.birthdayVisibility, "contacts")
        giftsVisibility = c.lenient(.giftsVisibility, "contacts")
        savedMusicVisibility = c.lenient(.savedMusicVisibility, "contacts")
        voiceMessagesVisibility = c.lenient(.voiceMessagesVisibility, "everybody")
        autoArchiveEnabled = c.lenient(.autoArchiveEnabled, true)

        autoDownloadMedia = c.lenient(.autoDownloadMedia, false)
        autoDownloadCellular = c.lenient(.autoDownloadCellular, false)
        autoDownloadWiFi = c.lenient(.autoDownloadWiFi, true)
        autoDownloadReset = c.lenient(.autoDownloadReset, false)
        saveIncomingPhotos = c.lenient(.saveIncomingPhotos, true)
        saveEditedPhotos = c.lenient(.saveEditedPhotos, true)
        keepMedia = c.lenient(.keepMedia, "month")
        cacheLimitMb = c.lenient(.cacheLimitMb, 2048)
        dataSaverCalls = c.lenient(.dataSaverCalls, false)
        raiseToListen = c.lenient(.raiseToListen, true)
        pauseMusicOnRecording = c.lenient(.pauseMusicOnRecording, true)

        appLanguage = c.lenient(.appLanguage, "ru")
        translationsEnabled = c.lenient(.translationsEnabled, false)
        translateEntireChats = c.lenient(.translateEntireChats, false)

        folderTags = c.lenient(.folderTags, false)
        offlineModeNotice = c.lenient(.offlineModeNotice, true)

        energySavingEnabled = c.lenient(.energySavingEnabled, false)
        energySavingAutoDownload = c.lenient(.energySavingAutoDownload, true)
        proxyEnabled = c.lenient(.proxyEnabled, false)
    }
}

private extension KeyedDecodingContainer {
    func lenient<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
}

// MARK: - Корень хранилища

struct StoreSnapshot: Codable {
    var schemaVersion: Int
    var createdAt: Date
    var updatedAt: Date
    var profile: UserProfile
    var stars: Int
    var contacts: [UserProfile]
    var chats: [Chat]
    var folders: [ChatFolder]
    var messages: [Message]
    var ledger: [LedgerEntry]
    var ownedGifts: [OwnedGift]
    var ownedNFTs: [OwnedNFT]
    var calls: [CallRecord]
    var settings: AppSettings
}
