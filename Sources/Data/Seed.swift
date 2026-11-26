import Foundation

/// Первичное наполнение локального аккаунта.
///
/// При первом запуске создаётся профиль, начисляется 1 000 000 тестовых звёзд,
/// инициализируются подарки, NFT, Premium и история операций.
enum Seed {

    static func makeInitialSnapshot() -> StoreSnapshot {
        let now = Date()
        let profile = makeProfile(now: now)

        var snapshot = StoreSnapshot(
            schemaVersion: AppConfig.schemaVersion,
            createdAt: now,
            updatedAt: now,
            profile: profile,
            stars: AppConfig.startingStars,
            contacts: [],
            chats: [],
            folders: [],
            messages: [],
            ledger: [],
            ownedGifts: [],
            ownedNFTs: [],
            calls: [],
            settings: AppSettings()
        )

        snapshot.ledger.append(
            LedgerEntry(
                id: IDs.next("ledger"),
                kind: .grant,
                title: "Стартовый баланс тестовых звёзд",
                amount: AppConfig.startingStars,
                createdAt: now,
                balanceAfter: AppConfig.startingStars
            )
        )

        // Избранное — обязательный чат самого с собой, как в Telegram.
        let saved = Chat(
            id: IDs.next("chat"),
            kind: .direct,
            title: "Избранное",
            avatarColor: Palette.blue,
            peerId: profile.id,
            memberIds: [profile.id],
            createdAt: now,
            isArchived: false,
            isPinned: true,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: now
        )
        snapshot.chats.append(saved)
        snapshot.messages.append(
            Message(
                id: IDs.next("msg"),
                chatId: saved.id,
                senderId: profile.id,
                authorName: profile.displayName,
                text: "EndoGram работает полностью офлайн. Этот чат — ваши заметки: всё, что здесь написано, остаётся только на устройстве.",
                createdAt: now,
                editedAt: nil,
                isPinned: true,
                kind: .service
            )
        )

        let service = Chat(
            id: IDs.next("chat"),
            kind: .channel,
            title: "EndoGram",
            avatarColor: Palette.blue,
            peerId: nil,
            memberIds: [profile.id],
            createdAt: now,
            isArchived: false,
            isPinned: false,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: now
        )
        snapshot.chats.append(service)
        snapshot.messages.append(
            Message(
                id: IDs.next("msg"),
                chatId: service.id,
                senderId: "system",
                authorName: "EndoGram",
                text: "Добро пожаловать! Это локальная версия мессенджера. Серверы не используются: чаты, подарки, NFT и Premium живут внутри приложения и сохраняются между запусками.",
                createdAt: now,
                editedAt: nil,
                isPinned: false,
                kind: .service
            )
        )

        // Папки по умолчанию, как в Telegram.
        snapshot.folders = [
            ChatFolder(id: "folder.all", title: "Все", icon: "tray.full.fill", chatIds: [], isSystem: true),
            ChatFolder(id: "folder.personal", title: "Личные", icon: "person.fill", chatIds: [], isSystem: true),
            ChatFolder(id: "folder.groups", title: "Группы", icon: "person.2.fill", chatIds: [], isSystem: true),
            ChatFolder(id: "folder.channels", title: "Каналы", icon: "megaphone.fill", chatIds: [], isSystem: true),
        ]

        return snapshot
    }

    static func makeProfile(now: Date) -> UserProfile {
        let names = ["Александр Орлов", "Мария Волкова", "Даниил Соколов", "Полина Ким"]
        let name = names.randomElement() ?? "Пользователь EndoGram"
        let handle = "endo_" + IDs.randomToken(length: 6).lowercased()
        return UserProfile(
            id: IDs.next("user"),
            username: handle,
            displayName: name,
            bio: "Локальный аккаунт EndoGram",
            phone: "+7 (000) 000-00-" + String(format: "%02d", Int.random(in: 0...99)),
            avatarColor: Palette.avatarColors.randomElement() ?? Palette.blue,
            createdAt: now,
            isPremium: false,
            premiumUntil: nil
        )
    }

    // MARK: - Каталоги (локальные, без сети)

    static let giftCatalog: [Gift] = [
        Gift(id: "gift.bear", name: "Плюшевый мишка", emoji: "🧸", price: 15, rarity: "Обычный", colorHex: "#E8A87C"),
        Gift(id: "gift.rose", name: "Роза", emoji: "🌹", price: 25, rarity: "Обычный", colorHex: "#E4572E"),
        Gift(id: "gift.cake", name: "Торт", emoji: "🎂", price: 50, rarity: "Обычный", colorHex: "#F2B5D4"),
        Gift(id: "gift.rocket", name: "Ракета", emoji: "🚀", price: 100, rarity: "Редкий", colorHex: "#5288C1"),
        Gift(id: "gift.crown", name: "Корона", emoji: "👑", price: 250, rarity: "Редкий", colorHex: "#F5C542"),
        Gift(id: "gift.diamond", name: "Алмаз", emoji: "💎", price: 500, rarity: "Эпический", colorHex: "#5BC8F5"),
        Gift(id: "gift.planet", name: "Планета", emoji: "🪐", price: 1_000, rarity: "Эпический", colorHex: "#9B7EDE"),
        Gift(id: "gift.unicorn", name: "Единорог", emoji: "🦄", price: 2_500, rarity: "Легендарный", colorHex: "#FF8FD0"),
        Gift(id: "gift.ufo", name: "НЛО", emoji: "🛸", price: 5_000, rarity: "Легендарный", colorHex: "#6EE7B7"),
    ]

    static let nftCatalog: [NFTItem] = [
        NFTItem(id: "nft.alpha", name: "Alpha Ape", collection: "Endo Apes", emoji: "🐵", price: 1_200, rarity: "Обычный", colorHex: "#C08457", serial: 1042, totalSupply: 10_000, description: "Первый выпуск локальной коллекции Endo Apes."),
        NFTItem(id: "nft.punk", name: "Endo Punk", collection: "Endo Punks", emoji: "👾", price: 2_400, rarity: "Редкий", colorHex: "#7C5CFF", serial: 218, totalSupply: 5_000, description: "Пиксельный аватар с уникальным номером."),
        NFTItem(id: "nft.cat", name: "Cosmic Cat", collection: "Cosmic Cats", emoji: "🐱", price: 3_600, rarity: "Редкий", colorHex: "#FFB86B", serial: 77, totalSupply: 2_500, description: "Кот, который видел весь блокчейн."),
        NFTItem(id: "nft.whale", name: "Golden Whale", collection: "Deep Sea", emoji: "🐳", price: 8_000, rarity: "Эпический", colorHex: "#3FA9F5", serial: 12, totalSupply: 500, description: "Редкий кит из глубинной коллекции."),
        NFTItem(id: "nft.dragon", name: "Neon Dragon", collection: "Neon Beasts", emoji: "🐲", price: 15_000, rarity: "Легендарный", colorHex: "#4ADE80", serial: 3, totalSupply: 100, description: "Легендарный дракон, всего 100 экземпляров."),
        NFTItem(id: "nft.star", name: "Endo Star", collection: "Endo Stars", emoji: "⭐️", price: 25_000, rarity: "Мифический", colorHex: "#FACC15", serial: 1, totalSupply: 10, description: "Мифическая звезда — редкость коллекции."),
    ]

    static let wallpaperNames = ["telegram", "градиент", "ночной", "океан"]
}
