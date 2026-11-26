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
    var notificationsEnabled: Bool = true
    var soundsEnabled: Bool = true
    var darkTheme: Bool = true
    var fontSize: Double = 17
    var wallpaper: String = "telegram"
    var showLastSeen: Bool = true
    var readReceipts: Bool = true
    var autoDownloadMedia: Bool = false
    var offlineModeNotice: Bool = true
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
