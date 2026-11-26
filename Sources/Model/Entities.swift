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
    /// Свои обои для этого чата. nil — используются обои из настроек.
    var wallpaperId: String? = nil

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
    /// Голосовое сообщение: файл лежит в песочнице приложения.
    case voice
    /// Фото: JPEG в `Application Support/EndoGram/ChatMedia`.
    case photo
    /// Видео: MOV в `Application Support/EndoGram/ChatMedia`.
    case video
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
    /// Имя файла голосового сообщения внутри песочницы приложения.
    var voiceFileName: String? = nil
    /// Длительность голосового в секундах.
    var voiceDuration: Double? = nil
    /// Огибающая громкости для полосок в пузыре — как в Telegram.
    var voiceWaveform: [Double]? = nil
    /// Имя файла вложения (фото или видео) в песочнице приложения.
    var mediaFileName: String? = nil
    /// Длительность видео в секундах.
    var mediaDuration: Double? = nil

    var isMedia: Bool { kind == .photo || kind == .video }

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

// MARK: - Истории

/// Кто видит историю — как `Story.ContextPrivacy.Label*` в Telegram.
enum StoryPrivacy: String, CaseIterable, Identifiable {
    case everyone
    case contacts
    case closeFriends
    case onlyMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyone:     return "Все"
        case .contacts:     return "Мои контакты"
        case .closeFriends: return "Близкие друзья"
        case .onlyMe:       return "Только я"
        }
    }

    /// Пояснение — как `Story.PrivacyTooltip*` оригинала.
    var hint: String {
        switch self {
        case .everyone:     return "История видна всем."
        case .contacts:     return "История видна всем вашим контактам."
        case .closeFriends: return "История видна только близким друзьям."
        case .onlyMe:       return "Историю видите только вы."
        }
    }
}

/// Локальная история — как `Settings_MyStories` в Telegram.
///
/// Истории живут 24 часа, потом уходят в архив (`Settings_StoriesArchive`).
/// Картинок нет: обложка — градиент из палитры плюс подпись, чтобы всё
/// оставалось офлайн и без файлов, которые некуда загрузить.
struct Story: Codable, Identifiable, Hashable {
    var id: String
    var authorName: String
    var caption: String
    var colorHex: String
    var createdAt: Date
    var expiresAt: Date
    var isArchived: Bool = false
    var views: Int = 0
    /// Порядковый номер просмотра — сколько раз открывали.
    var lastViewedAt: Date? = nil
    /// «Кто видит» — `Story.Context.Privacy`. nil трактуется как «Все».
    var privacy: String? = nil
    /// Имя файла фото или видео в песочнице приложения.
    var mediaFileName: String? = nil
    /// `photo` или `video`.
    var mediaKind: String? = nil
    /// Длительность видео в секундах.
    var mediaDuration: Double? = nil

    var hasMedia: Bool { mediaFileName != nil }
    var isVideo: Bool { mediaKind == "video" }

    var privacyOption: StoryPrivacy {
        StoryPrivacy(rawValue: privacy ?? "") ?? .everyone
    }

    var isExpired: Bool { expiresAt <= Date() }

    /// Осталось часов до архива — для подписи «осталось N ч».
    var hoursLeft: Int {
        max(0, Int(ceil(expiresAt.timeIntervalSinceNow / 3600)))
    }
}

struct Gift: Codable, Identifiable, Hashable {    var id: String
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
    // Как в notificationSearchableItems официального клиента
    var storyNotifications: Bool = true
    var reactionNotifications: Bool = true
    var inAppSounds: Bool = true
    var inAppVibrate: Bool = true
    var inAppPreview: Bool = true
    var displayNamesOnLockScreen: Bool = false
    var badgeIncludeChannels: Bool = true
    var badgeCountUnreadMessages: Bool = false
    var contactJoinedNotifications: Bool = true

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
    // Как в privacySearchableItems официального клиента
    var topPeersEnabled: Bool = true
    var deleteDraftsOnLogout: Bool = false
    var contactsSyncEnabled: Bool = false
    var secretChatsLinkPreviews: Bool = true
    var passkeyEnabled: Bool = false
    var loginEmailEnabled: Bool = false

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
    var intentsEnabled: Bool = true
    var useLessDataForCalls: Bool = false

    // Язык и переводы
    var appLanguage: String = "ru"
    var translationsEnabled: Bool = false
    var translateEntireChats: Bool = false
    var showTranslateButton: Bool = false
    var doNotTranslate: Bool = false

    // Папки
    var folderTags: Bool = false

    // Стикеры и эмодзи — как в stickerSearchableItems
    var suggestStickers: Bool = true
    var largeEmoji: Bool = true
    var dynamicStickerOrder: Bool = true
    var archivedStickerPacks: Bool = false
    var featuredStickerPacks: Bool = true
    var quickReactionEnabled: Bool = true

    // Профиль — как в profileSearchableItems
    var profileColor: String = "blue"
    var birthday: String = ""
    var personalChannel: String = ""

    // Энергосбережение и прокси
    var energySavingEnabled: Bool = false
    var energySavingAutoDownload: Bool = true
    var proxyEnabled: Bool = false
    var proxyUseForCalls: Bool = false

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
        case storyNotifications, reactionNotifications, inAppSounds, inAppVibrate
        case inAppPreview, displayNamesOnLockScreen, badgeIncludeChannels
        case badgeCountUnreadMessages, contactJoinedNotifications
        case topPeersEnabled, deleteDraftsOnLogout, contactsSyncEnabled
        case secretChatsLinkPreviews, passkeyEnabled, loginEmailEnabled
        case intentsEnabled, useLessDataForCalls, proxyUseForCalls
        case suggestStickers, largeEmoji, dynamicStickerOrder
        case archivedStickerPacks, featuredStickerPacks, quickReactionEnabled
        case showTranslateButton, doNotTranslate
        case profileColor, birthday, personalChannel
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
        proxyUseForCalls = c.lenient(.proxyUseForCalls, false)

        storyNotifications = c.lenient(.storyNotifications, true)
        reactionNotifications = c.lenient(.reactionNotifications, true)
        inAppSounds = c.lenient(.inAppSounds, true)
        inAppVibrate = c.lenient(.inAppVibrate, true)
        inAppPreview = c.lenient(.inAppPreview, true)
        displayNamesOnLockScreen = c.lenient(.displayNamesOnLockScreen, false)
        badgeIncludeChannels = c.lenient(.badgeIncludeChannels, true)
        badgeCountUnreadMessages = c.lenient(.badgeCountUnreadMessages, false)
        contactJoinedNotifications = c.lenient(.contactJoinedNotifications, true)

        topPeersEnabled = c.lenient(.topPeersEnabled, true)
        deleteDraftsOnLogout = c.lenient(.deleteDraftsOnLogout, false)
        contactsSyncEnabled = c.lenient(.contactsSyncEnabled, false)
        secretChatsLinkPreviews = c.lenient(.secretChatsLinkPreviews, true)
        passkeyEnabled = c.lenient(.passkeyEnabled, false)
        loginEmailEnabled = c.lenient(.loginEmailEnabled, false)

        intentsEnabled = c.lenient(.intentsEnabled, true)
        useLessDataForCalls = c.lenient(.useLessDataForCalls, false)

        suggestStickers = c.lenient(.suggestStickers, true)
        largeEmoji = c.lenient(.largeEmoji, true)
        dynamicStickerOrder = c.lenient(.dynamicStickerOrder, true)
        archivedStickerPacks = c.lenient(.archivedStickerPacks, false)
        featuredStickerPacks = c.lenient(.featuredStickerPacks, true)
        quickReactionEnabled = c.lenient(.quickReactionEnabled, true)

        showTranslateButton = c.lenient(.showTranslateButton, false)
        doNotTranslate = c.lenient(.doNotTranslate, false)

        profileColor = c.lenient(.profileColor, "blue")
        birthday = c.lenient(.birthday, "")
        personalChannel = c.lenient(.personalChannel, "")
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
    var stories: [Story] = []

    /// Терпимое декодирование всего хранилища.
    ///
    /// Синтезированный декодер требует presence каждого неопционального поля:
    /// стоило добавить новую коллекцию — и файл, записанный прошлой версией,
    /// перестал бы читаться, а аккаунт сбросился бы в новый. Поэтому каждая
    /// коллекция читается через `decodeIfPresent` со значением по умолчанию,
    /// а обязательным остаётся только профиль — без него аккаунта нет.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = c.lenient(.schemaVersion, 1)
        createdAt = c.lenient(.createdAt, Date())
        updatedAt = c.lenient(.updatedAt, Date())
        profile = try c.decode(UserProfile.self, forKey: .profile)
        stars = c.lenient(.stars, 0)
        contacts = c.lenient(.contacts, [])
        chats = c.lenient(.chats, [])
        folders = c.lenient(.folders, [])
        messages = c.lenient(.messages, [])
        ledger = c.lenient(.ledger, [])
        ownedGifts = c.lenient(.ownedGifts, [])
        ownedNFTs = c.lenient(.ownedNFTs, [])
        calls = c.lenient(.calls, [])
        settings = c.lenient(.settings, AppSettings())
        stories = c.lenient(.stories, [])
    }

    init(schemaVersion: Int, createdAt: Date, updatedAt: Date, profile: UserProfile,
         stars: Int, contacts: [UserProfile], chats: [Chat], folders: [ChatFolder],
         messages: [Message], ledger: [LedgerEntry], ownedGifts: [OwnedGift],
         ownedNFTs: [OwnedNFT], calls: [CallRecord], settings: AppSettings,
         stories: [Story] = []) {
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profile = profile
        self.stars = stars
        self.contacts = contacts
        self.chats = chats
        self.folders = folders
        self.messages = messages
        self.ledger = ledger
        self.ownedGifts = ownedGifts
        self.ownedNFTs = ownedNFTs
        self.calls = calls
        self.settings = settings
        self.stories = stories
    }
}
