import Foundation

/// Одна запись каталога коллекционных подарков Telegram.
///
/// Данные лежат в `Resources/Collectibles.json` и взяты из публичного
/// каталога Fragment (`fragment.com/gifts`): 124 коллекции, суммарный тираж
/// совпадает с указанным там же — 1 557 345. В официальном клиенте этот
/// каталог приходит с сервера, поэтому в исходниках форка списка имён нет.
struct CollectibleRecord: Decodable {
    let slug: String
    let name: String
    let supply: Int
}

/// Каталог коллекционных подарков: реальные названия и тиражи, локальные
/// эмодзи, цвета, редкость и цены.
///
/// Эмодзи и цвет выводятся детерминированно из slug и названия, поэтому
/// каталог не нужно править руками при обновлении списка — достаточно
/// заменить `Collectibles.json`.
enum CollectiblesCatalog {

    /// Полный каталог, отсортированный от самого редкого к массовому.
    static let all: [NFTItem] = build()

    private static func build() -> [NFTItem] {
        records
            .map { makeItem($0) }
            .sorted { $0.totalSupply < $1.totalSupply }
    }

    private static let records: [CollectibleRecord] = {
        guard let url = Bundle.main.url(forResource: "Collectibles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CollectibleRecord].self, from: data) else {
            return []
        }
        return decoded
    }()

    private static func makeItem(_ record: CollectibleRecord) -> NFTItem {
        let displayName = singular(record.name)
        return NFTItem(
            id: "nft.\(record.slug)",
            name: displayName,
            collection: "Telegram Gifts",
            emoji: emoji(for: record.slug),
            price: price(for: record.supply),
            rarity: rarity(for: record.supply),
            colorHex: color(for: record.slug),
            serial: serial(for: record.slug, supply: record.supply),
            totalSupply: record.supply,
            description: "Коллекционный подарок Telegram «\(displayName)». Тираж — \(record.supply) шт."
        )
    }

    // MARK: - Название

    /// Fragment отдаёт название коллекции во множественном числе
    /// («Plush Pepes»), а в клиенте предмет называется в единственном.
    static func singular(_ name: String) -> String {
        let irregular: [String: String] = [
            "Durov's Glasses": "Durov's Glasses",
            "Jacks-in-the-Box": "Jacks-in-the-Box",
            "Snow Mittens": "Snow Mittens",
            "Ion Gems": "Ion Gem",
        ]
        if let known = irregular[name] { return known }
        if name.hasSuffix("ies"), name.count > 4 {
            return String(name.dropLast(3)) + "y"
        }
        if name.hasSuffix("ches") || name.hasSuffix("shes") || name.hasSuffix("sses") || name.hasSuffix("xes") {
            return String(name.dropLast(2))
        }
        if name.hasSuffix("s"), !name.hasSuffix("ss"), name.count > 3 {
            return String(name.dropLast())
        }
        return name
    }

    // MARK: - Редкость и цена

    /// Редкость по тиражу: чем меньше предметов, тем выше класс.
    static func rarity(for supply: Int) -> String {
        switch supply {
        case ..<100:      return "Мифический"
        case ..<2_500:    return "Легендарный"
        case ..<6_000:    return "Эпический"
        case ..<15_000:   return "Редкий"
        default:          return "Обычный"
        }
    }

    static func price(for supply: Int) -> Int {
        switch supply {
        case ..<100:      return 25_000
        case ..<2_500:    return 12_000
        case ..<6_000:    return 6_000
        case ..<15_000:   return 2_500
        default:          return 900
        }
    }

    // MARK: - Оформление

    /// Цвет из палитры `PeerNameColors` — стабильный для одного и того же slug.
    static func color(for slug: String) -> String {
        let index = Int(hash(slug) % UInt32(Palette.avatarColors.count))
        return Palette.avatarColors[index]
    }

    /// Номер экземпляра внутри тиража — стабильный, чтобы карточка не «мигала».
    static func serial(for slug: String, supply: Int) -> Int {
        guard supply > 0 else { return 1 }
        return Int(hash(slug + "#serial") % UInt32(supply)) + 1
    }

    /// Эмодзи подбирается по ключевому слову в slug.
    static func emoji(for slug: String) -> String {
        for (needle, symbol) in emojiTable where slug.contains(needle) {
            return symbol
        }
        return "🎁"
    }

    private static func hash(_ string: String) -> UInt32 {
        var value: UInt32 = 2_166_136_261
        for byte in string.utf8 {
            value = (value ^ UInt32(byte)) &* 16_777_619
        }
        return value
    }

    /// Пары «фрагмент slug → эмодзи». Порядок важен: длинные фрагменты выше,
    /// иначе `ring` перехватит `earring`-подобные совпадения.
    private static let emojiTable: [(String, String)] = [
        ("jackinthebox", "🎁"), ("snowglobe", "🌐"), ("snowmittens", "🧤"),
        ("sleighbell", "🔔"), ("jinglebells", "🔔"), ("flyingbroom", "🧹"),
        ("libertyfigure", "🗽"), ("recordplayer", "🎵"), ("tamagadget", "📟"),
        ("swisswatch", "⌚"), ("timelessbook", "📖"), ("starnotepad", "📓"),
        ("deskcalendar", "📅"), ("homemadecake", "🎂"), ("moussecake", "🍮"),
        ("whipcupcake", "🧁"), ("bunnymuffin", "🧁"), ("instantramen", "🍜"),
        ("hypnolollipop", "🍭"), ("preciouspeach", "🍑"), ("kissedfrog", "🐸"),
        ("plushpepe", "🐸"), ("jollychimp", "🐵"), ("jellybunny", "🐰"),
        ("scaredcat", "🐱"), ("resistancedog", "🐶"), ("snoopdogg", "🐶"),
        ("rarebird", "🐦"), ("petsnake", "🐍"), ("lunarsnake", "🐍"),
        ("spyagaric", "🍄"), ("madpumpkin", "🎃"), ("witchhat", "🧙"),
        ("voodoodoll", "🪆"), ("ufcstrike", "🥊"), ("mightyarm", "💪"),
        ("victorymedal", "🏅"), ("minioscar", "🏆"), ("algorithmcup", "🏆"),
        ("intelligencecup", "🏆"), ("crystalball", "🔮"), ("magicpotion", "🧪"),
        ("lovepotion", "🧪"), ("perfumebottle", "🧴"), ("inputkey", "🔑"),
        ("gemsignet", "💠"), ("ionicdryer", "💨"), ("chillflame", "🔥"),
        ("eternalcandle", "🕯️"), ("lovecandle", "🕯️"), ("bdaycandle", "🕯️"),
        ("partysparkler", "✨"), ("hangingstar", "🌟"), ("stellarrocket", "🚀"),
        ("surgeboard", "🛹"), ("lowrider", "🚗"), ("poolfloat", "🛟"),
        ("easteregg", "🥚"), ("electricskull", "🪫"), ("spicedwine", "🍷"),
        ("holidaydrink", "🍹"), ("vicecream", "🍦"), ("icecream", "🍦"),
        ("gingercookie", "🍪"), ("cookieheart", "🍪"), ("candycane", "🍬"),
        ("lolpop", "🍭"), ("hexpot", "🍲"), ("moneypot", "💰"),
        ("lootbag", "💰"), ("swagbag", "👜"), ("joyfulbundle", "🎁"),
        ("valentinebox", "💌"), ("snakebox", "📦"), ("berrybox", "🫐"),
        ("artisanbrick", "🧱"), ("astralshard", "🔷"), ("bowtie", "🎀"),
        ("blingbinky", "🍼"), ("tophat", "🎩"), ("jesterhat", "🃏"),
        ("heroichelmet", "⛑️"), ("nekohelmet", "🐈"), ("durovscap", "🧢"),
        ("durovsglasses", "🕶️"), ("khabibspapakha", "🧢"), ("santahat", "🎅"),
        ("xmasstocking", "🧦"), ("freshsocks", "🧦"), ("winterwreath", "🎄"),
        ("springbasket", "🧺"), ("prettyposy", "🌷"), ("lushbouquet", "💐"),
        ("eternalrose", "🌹"), ("sakuraflower", "🌸"), ("skullflower", "💀"),
        ("skystilettos", "👠"), ("nailbracelet", "📿"), ("bondedring", "💍"),
        ("diamondring", "💍"), ("signetring", "💍"), ("heartlocket", "💝"),
        ("luckylocket", "💝"), ("trappedheart", "💔"), ("cupidcharm", "❤️"),
        ("evileye", "🧿"), ("faithamulet", "🧿"), ("cloverpin", "🍀"),
        ("finepen", "🖊️"), ("genielamp", "🪔"), ("miragelamp", "🪔"),
        ("bigyear", "🎉"), ("moodpack", "🎭"), ("mythmask", "🎭"),
        ("sharptongue", "👅"), ("restlessjar", "🫙"), ("happybrownie", "🍫"),
        ("vintagecigar", "🚬"), ("snoopcigar", "🚬"), ("westsidesign", "🪧"),
        ("moonpendant", "🌙"), ("preciouspeach", "🍑"), ("lightsword", "⚔️"),
        ("toybear", "🧸"), ("chest", "🎁"),
    ]
}