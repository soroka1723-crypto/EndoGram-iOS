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
        Gift(id: "gift.crown", name: "Корона", emoji: "👑", price: 250, rarity: "Редкий",
             colorHex: "#F5C542", isLimited: true, stock: 120),
        Gift(id: "gift.diamond", name: "Алмаз", emoji: "💎", price: 500, rarity: "Эпический",
             colorHex: "#5BC8F5", isLimited: true, stock: 40),
        Gift(id: "gift.planet", name: "Планета", emoji: "🪐", price: 1_000, rarity: "Эпический",
             colorHex: "#9B7EDE", isLimited: true, stock: 12, isCollectible: true),
        Gift(id: "gift.unicorn", name: "Единорог", emoji: "🦄", price: 2_500, rarity: "Легендарный",
             colorHex: "#FF8FD0", isLimited: true, stock: 3, isCollectible: true),
        Gift(id: "gift.ufo", name: "НЛО", emoji: "🛸", price: 5_000, rarity: "Легендарный",
             colorHex: "#6EE7B7", isLimited: true, stock: 0, isCollectible: true),
    ]

    /// Коллекционные подарки Telegram.
    ///
    /// В официальном клиенте каталог приходит с сервера — в исходниках форка
    /// списка имён нет, только строки интерфейса (`Gift.Options.*`). Поэтому
    /// здесь собраны реальные названия коллекционных подарков Telegram,
    /// а цены, редкость и тиражи — локальные тестовые значения.
    static let nftCatalog: [NFTItem] = [
        NFTItem(id: "nft.plushpepe", name: "Plush Pepe", collection: "Telegram Gifts", emoji: "🐸",
                price: 1_200, rarity: "Обычный", colorHex: "#5BC86B",
                serial: 1042, totalSupply: 10_000,
                description: "Плюшевый Пепе — самый узнаваемый подарок Telegram."),
        NFTItem(id: "nft.durovcap", name: "Durov's Cap", collection: "Telegram Gifts", emoji: "🧢",
                price: 2_400, rarity: "Редкий", colorHex: "#7C5CFF",
                serial: 218, totalSupply: 5_000,
                description: "Кепка с логотипом — символ ранних подарков."),
        NFTItem(id: "nft.heartlocket", name: "Heart Locket", collection: "Telegram Gifts", emoji: "💝",
                price: 3_600, rarity: "Редкий", colorHex: "#FF8FD0",
                serial: 77, totalSupply: 2_500,
                description: "Медальон с сердцем, который открывается."),
        NFTItem(id: "nft.signetring", name: "Signet Ring", collection: "Telegram Gifts", emoji: "💍",
                price: 8_000, rarity: "Эпический", colorHex: "#F5C542",
                serial: 12, totalSupply: 500,
                description: "Перстень с гравировкой — редкий коллекционный подарок."),
        NFTItem(id: "nft.bear", name: "Bear", collection: "Telegram Gifts", emoji: "🧸",
                price: 950, rarity: "Обычный", colorHex: "#E8A87C",
                serial: 3_120, totalSupply: 20_000,
                description: "Классический плюшевый медведь."),
        NFTItem(id: "nft.bouquet", name: "Bouquet", collection: "Telegram Gifts", emoji: "💐",
                price: 1_500, rarity: "Обычный", colorHex: "#F2B5D4",
                serial: 2_040, totalSupply: 8_000,
                description: "Букет цветов для любого повода."),
        NFTItem(id: "nft.sakura", name: "Sakura Flower", collection: "Telegram Gifts", emoji: "🌸",
                price: 2_100, rarity: "Редкий", colorHex: "#FFB7C5",
                serial: 640, totalSupply: 4_000,
                description: "Цветок сакуры — весенний подарок."),
        NFTItem(id: "nft.diamondring", name: "Diamond Ring", collection: "Telegram Gifts", emoji: "💎",
                price: 4_500, rarity: "Эпический", colorHex: "#5BC8F5",
                serial: 88, totalSupply: 900,
                description: "Кольцо с бриллиантом."),
        NFTItem(id: "nft.evileye", name: "Evil Eye", collection: "Telegram Gifts", emoji: "🧿",
                price: 1_800, rarity: "Редкий", colorHex: "#3E88F7",
                serial: 512, totalSupply: 3_000,
                description: "Оберег от сглаза — синий глаз."),
        NFTItem(id: "nft.cupidheart", name: "Cupid's Heart", collection: "Telegram Gifts", emoji: "❤️‍🔥",
                price: 2_800, rarity: "Редкий", colorHex: "#FF4D6D",
                serial: 330, totalSupply: 2_000,
                description: "Пылающее сердце Купидона."),
        NFTItem(id: "nft.crystalball", name: "Crystal Ball", collection: "Telegram Gifts", emoji: "🔮",
                price: 3_200, rarity: "Эпический", colorHex: "#9B7EDE",
                serial: 145, totalSupply: 1_200,
                description: "Шар предсказаний с мерцанием внутри."),
        NFTItem(id: "nft.rocket", name: "Stellar Rocket", collection: "Telegram Gifts", emoji: "🚀",
                price: 5_000, rarity: "Эпический", colorHex: "#5288C1",
                serial: 60, totalSupply: 700,
                description: "Ракета, улетающая к звёздам."),
        NFTItem(id: "nft.lolpop", name: "Lol Pop", collection: "Telegram Gifts", emoji: "🍭",
                price: 1_100, rarity: "Обычный", colorHex: "#FF7AB6",
                serial: 1_700, totalSupply: 9_000,
                description: "Леденец, который любят все."),
        NFTItem(id: "nft.iongem", name: "Ion Gem", collection: "Telegram Gifts", emoji: "💠",
                price: 6_500, rarity: "Легендарный", colorHex: "#22D3EE",
                serial: 9, totalSupply: 300,
                description: "Кристалл ионизированного света."),
        NFTItem(id: "nft.icecream", name: "Ice Cream", collection: "Telegram Gifts", emoji: "🍦",
                price: 800, rarity: "Обычный", colorHex: "#FFD9A0",
                serial: 4_400, totalSupply: 25_000,
                description: "Мороженое, которое не тает."),
        NFTItem(id: "nft.tophat", name: "Top Hat", collection: "Telegram Gifts", emoji: "🎩",
                price: 3_900, rarity: "Эпический", colorHex: "#8E8E93",
                serial: 210, totalSupply: 1_000,
                description: "Цилиндр для особых случаев."),
        NFTItem(id: "nft.goldbar", name: "Gold Bar", collection: "Telegram Gifts", emoji: "🥇",
                price: 12_000, rarity: "Легендарный", colorHex: "#F5C038",
                serial: 24, totalSupply: 200,
                description: "Слиток золота — тяжёлый и дорогой."),
        NFTItem(id: "nft.spellbook", name: "Spell Book", collection: "Telegram Gifts", emoji: "📕",
                price: 7_500, rarity: "Легендарный", colorHex: "#C7508B",
                serial: 31, totalSupply: 150,
                description: "Книга заклинаний с светящимися рунами."),
        NFTItem(id: "nft.whale", name: "Ocean's Whale", collection: "Deep Sea", emoji: "🐳",
                price: 15_000, rarity: "Мифический", colorHex: "#3FA9F5",
                serial: 3, totalSupply: 100,
                description: "Кит из глубинной коллекции."),
        NFTItem(id: "nft.dragon", name: "Neon Dragon", collection: "Neon Beasts", emoji: "🐲",
                price: 25_000, rarity: "Мифический", colorHex: "#4ADE80",
                serial: 1, totalSupply: 10,
                description: "Легендарный дракон — редкость коллекции."),
    ]

    /// настроек всегда находило реальный вариант.
    static var wallpaperNames: [String] { WallpaperStyle.allCases.map(\.rawValue) }
}