import Foundation

/// РџРµСЂРІРёС‡РЅРѕРµ РЅР°РїРѕР»РЅРµРЅРёРµ Р»РѕРєР°Р»СЊРЅРѕРіРѕ Р°РєРєР°СѓРЅС‚Р°.
///
/// РџСЂРё РїРµСЂРІРѕРј Р·Р°РїСѓСЃРєРµ СЃРѕР·РґР°С‘С‚СЃСЏ РїСЂРѕС„РёР»СЊ, РЅР°С‡РёСЃР»СЏРµС‚СЃСЏ 1 000 000 С‚РµСЃС‚РѕРІС‹С… Р·РІС‘Р·Рґ,
/// РёРЅРёС†РёР°Р»РёР·РёСЂСѓСЋС‚СЃСЏ РїРѕРґР°СЂРєРё, NFT, Premium Рё РёСЃС‚РѕСЂРёСЏ РѕРїРµСЂР°С†РёР№.
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
                title: "РЎС‚Р°СЂС‚РѕРІС‹Р№ Р±Р°Р»Р°РЅСЃ С‚РµСЃС‚РѕРІС‹С… Р·РІС‘Р·Рґ",
                amount: AppConfig.startingStars,
                createdAt: now,
                balanceAfter: AppConfig.startingStars
            )
        )

        // РР·Р±СЂР°РЅРЅРѕРµ вЂ” РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Р№ С‡Р°С‚ СЃР°РјРѕРіРѕ СЃ СЃРѕР±РѕР№, РєР°Рє РІ Telegram.
        let saved = Chat(
            id: IDs.next("chat"),
            kind: .direct,
            title: "РР·Р±СЂР°РЅРЅРѕРµ",
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
                text: "EndoGram СЂР°Р±РѕС‚Р°РµС‚ РїРѕР»РЅРѕСЃС‚СЊСЋ РѕС„Р»Р°Р№РЅ. Р­С‚РѕС‚ С‡Р°С‚ вЂ” РІР°С€Рё Р·Р°РјРµС‚РєРё: РІСЃС‘, С‡С‚Рѕ Р·РґРµСЃСЊ РЅР°РїРёСЃР°РЅРѕ, РѕСЃС‚Р°С‘С‚СЃСЏ С‚РѕР»СЊРєРѕ РЅР° СѓСЃС‚СЂРѕР№СЃС‚РІРµ.",
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
                text: "Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ! Р­С‚Рѕ Р»РѕРєР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ РјРµСЃСЃРµРЅРґР¶РµСЂР°. РЎРµСЂРІРµСЂС‹ РЅРµ РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ: С‡Р°С‚С‹, РїРѕРґР°СЂРєРё, NFT Рё Premium Р¶РёРІСѓС‚ РІРЅСѓС‚СЂРё РїСЂРёР»РѕР¶РµРЅРёСЏ Рё СЃРѕС…СЂР°РЅСЏСЋС‚СЃСЏ РјРµР¶РґСѓ Р·Р°РїСѓСЃРєР°РјРё.",
                createdAt: now,
                editedAt: nil,
                isPinned: false,
                kind: .service
            )
        )

        // РџР°РїРєРё РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ, РєР°Рє РІ Telegram.
        snapshot.folders = [
            ChatFolder(id: "folder.all", title: "Р’СЃРµ", icon: "tray.full.fill", chatIds: [], isSystem: true),
            ChatFolder(id: "folder.personal", title: "Р›РёС‡РЅС‹Рµ", icon: "person.fill", chatIds: [], isSystem: true),
            ChatFolder(id: "folder.groups", title: "Р“СЂСѓРїРїС‹", icon: "person.2.fill", chatIds: [], isSystem: true),
            ChatFolder(id: "folder.channels", title: "РљР°РЅР°Р»С‹", icon: "megaphone.fill", chatIds: [], isSystem: true),
        ]

        return snapshot
    }

    static func makeProfile(now: Date) -> UserProfile {
        let names = ["РђР»РµРєСЃР°РЅРґСЂ РћСЂР»РѕРІ", "РњР°СЂРёСЏ Р’РѕР»РєРѕРІР°", "Р”Р°РЅРёРёР» РЎРѕРєРѕР»РѕРІ", "РџРѕР»РёРЅР° РљРёРј"]
        let name = names.randomElement() ?? "РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ EndoGram"
        let handle = "endo_" + IDs.randomToken(length: 6).lowercased()
        return UserProfile(
            id: IDs.next("user"),
            username: handle,
            displayName: name,
            bio: "Р›РѕРєР°Р»СЊРЅС‹Р№ Р°РєРєР°СѓРЅС‚ EndoGram",
            phone: "+7 (000) 000-00-" + String(format: "%02d", Int.random(in: 0...99)),
            avatarColor: Palette.avatarColors.randomElement() ?? Palette.blue,
            createdAt: now,
            isPremium: false,
            premiumUntil: nil
        )
    }

    // MARK: - РљР°С‚Р°Р»РѕРіРё (Р»РѕРєР°Р»СЊРЅС‹Рµ, Р±РµР· СЃРµС‚Рё)

    static let giftCatalog: [Gift] = [
        Gift(id: "gift.bear", name: "РџР»СЋС€РµРІС‹Р№ РјРёС€РєР°", emoji: "рџ§ё", price: 15, rarity: "РћР±С‹С‡РЅС‹Р№", colorHex: "#E8A87C"),
        Gift(id: "gift.rose", name: "Р РѕР·Р°", emoji: "рџЊ№", price: 25, rarity: "РћР±С‹С‡РЅС‹Р№", colorHex: "#E4572E"),
        Gift(id: "gift.cake", name: "РўРѕСЂС‚", emoji: "рџЋ‚", price: 50, rarity: "РћР±С‹С‡РЅС‹Р№", colorHex: "#F2B5D4"),
        Gift(id: "gift.rocket", name: "Р Р°РєРµС‚Р°", emoji: "рџљЂ", price: 100, rarity: "Р РµРґРєРёР№", colorHex: "#5288C1"),
        Gift(id: "gift.crown", name: "РљРѕСЂРѕРЅР°", emoji: "рџ‘‘", price: 250, rarity: "Р РµРґРєРёР№", colorHex: "#F5C542"),
        Gift(id: "gift.diamond", name: "РђР»РјР°Р·", emoji: "рџ’Ћ", price: 500, rarity: "Р­РїРёС‡РµСЃРєРёР№", colorHex: "#5BC8F5"),
        Gift(id: "gift.planet", name: "РџР»Р°РЅРµС‚Р°", emoji: "рџЄђ", price: 1_000, rarity: "Р­РїРёС‡РµСЃРєРёР№", colorHex: "#9B7EDE"),
        Gift(id: "gift.unicorn", name: "Р•РґРёРЅРѕСЂРѕРі", emoji: "рџ¦„", price: 2_500, rarity: "Р›РµРіРµРЅРґР°СЂРЅС‹Р№", colorHex: "#FF8FD0"),
        Gift(id: "gift.ufo", name: "РќР›Рћ", emoji: "рџ›ё", price: 5_000, rarity: "Р›РµРіРµРЅРґР°СЂРЅС‹Р№", colorHex: "#6EE7B7"),
    ]

    static let nftCatalog: [NFTItem] = [
        NFTItem(id: "nft.alpha", name: "Alpha Ape", collection: "Endo Apes", emoji: "рџђµ", price: 1_200, rarity: "РћР±С‹С‡РЅС‹Р№", colorHex: "#C08457", serial: 1042, totalSupply: 10_000, description: "РџРµСЂРІС‹Р№ РІС‹РїСѓСЃРє Р»РѕРєР°Р»СЊРЅРѕР№ РєРѕР»Р»РµРєС†РёРё Endo Apes."),
        NFTItem(id: "nft.punk", name: "Endo Punk", collection: "Endo Punks", emoji: "рџ‘ѕ", price: 2_400, rarity: "Р РµРґРєРёР№", colorHex: "#7C5CFF", serial: 218, totalSupply: 5_000, description: "РџРёРєСЃРµР»СЊРЅС‹Р№ Р°РІР°С‚Р°СЂ СЃ СѓРЅРёРєР°Р»СЊРЅС‹Рј РЅРѕРјРµСЂРѕРј."),
        NFTItem(id: "nft.cat", name: "Cosmic Cat", collection: "Cosmic Cats", emoji: "рџђ±", price: 3_600, rarity: "Р РµРґРєРёР№", colorHex: "#FFB86B", serial: 77, totalSupply: 2_500, description: "РљРѕС‚, РєРѕС‚РѕСЂС‹Р№ РІРёРґРµР» РІРµСЃСЊ Р±Р»РѕРєС‡РµР№РЅ."),
        NFTItem(id: "nft.whale", name: "Golden Whale", collection: "Deep Sea", emoji: "рџђі", price: 8_000, rarity: "Р­РїРёС‡РµСЃРєРёР№", colorHex: "#3FA9F5", serial: 12, totalSupply: 500, description: "Р РµРґРєРёР№ РєРёС‚ РёР· РіР»СѓР±РёРЅРЅРѕР№ РєРѕР»Р»РµРєС†РёРё."),
        NFTItem(id: "nft.dragon", name: "Neon Dragon", collection: "Neon Beasts", emoji: "рџђІ", price: 15_000, rarity: "Р›РµРіРµРЅРґР°СЂРЅС‹Р№", colorHex: "#4ADE80", serial: 3, totalSupply: 100, description: "Р›РµРіРµРЅРґР°СЂРЅС‹Р№ РґСЂР°РєРѕРЅ, РІСЃРµРіРѕ 100 СЌРєР·РµРјРїР»СЏСЂРѕРІ."),
        NFTItem(id: "nft.star", name: "Endo Star", collection: "Endo Stars", emoji: "в­ђпёЏ", price: 25_000, rarity: "РњРёС„РёС‡РµСЃРєРёР№", colorHex: "#FACC15", serial: 1, totalSupply: 10, description: "РњРёС„РёС‡РµСЃРєР°СЏ Р·РІРµР·РґР° вЂ” СЂРµРґРєРѕСЃС‚СЊ РєРѕР»Р»РµРєС†РёРё."),
    ]

    static let wallpaperNames = ["telegram", "РіСЂР°РґРёРµРЅС‚", "РЅРѕС‡РЅРѕР№", "РѕРєРµР°РЅ"]
}

