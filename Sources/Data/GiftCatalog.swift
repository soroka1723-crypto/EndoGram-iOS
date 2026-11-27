import Foundation

/// Один подарок из каталога Telegram.
///
/// Данные не выдуманы: `Resources/Gifts/GiftCatalog.json` собран из публичного
/// CDN реальных подарков Telegram (`cdn-telegram-gifts`) — там лежат сами
/// анимации `.tgs` и превью, а также метаданные (`stars`, `availability_total`,
/// `limited`, `sold_out`). Анимации сконвертированы в спрайт-листы
/// `Resources/Gifts/Anim/gift_<id>_anim.png` (4×4 кадра), превью —
/// `Resources/Gifts/Preview/gift_<id>.png` (256 pt).
struct GiftRecord: Decodable {
    let id: String
    let name: String
    let stars: Int
    let total: Int?
    let limited: Bool
    let rarity: String
    let colorHex: String
    let duration: Double
    let soldOut: Bool?
}

/// Каталог подарков: 152 реальных подарка Telegram с настоящими названиями,
/// ценами в звёздах и тиражами.
enum GiftCatalog {

    static let records: [GiftRecord] = {
        guard let url = Bundle.main.url(forResource: "GiftCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([GiftRecord].self, from: data) else {
            return []
        }
        return decoded
    }()

    /// Подарки в виде модели приложения.
    ///
    /// `stock` берётся из тиража: локально подарок всегда доступен для покупки
    /// (это тестовый режим), но если тираж в настоящем Telegram распродан,
    /// это честно помечается через `soldOutInTelegram` и подписью в карточке.
    /// Иначе 140 из 152 подарков были бы недоступны и витрина стала бы мёртвой.
    static let all: [Gift] = records.map { record in
        Gift(
            id: "gift." + record.id,
            name: record.name,
            emoji: emoji(for: record.name),
            price: record.stars,
            rarity: record.rarity,
            colorHex: record.colorHex,
            isLimited: record.limited,
            stock: nil,
            isCollectible: record.stars >= 1_000,
            totalSupply: record.total,
            duration: record.duration,
            soldOutInTelegram: record.soldOut ?? false
        )
    }

    /// Идентификатор ассета по id подарка: `gift.<id>` → `<id>`.
    static func assetId(for gift: Gift) -> String {
        gift.id.hasPrefix("gift.") ? String(gift.id.dropFirst(5)) : gift.id
    }

    static func assetId(forGiftId giftId: String) -> String {
        giftId.hasPrefix("gift.") ? String(giftId.dropFirst(5)) : giftId
    }

    /// Эмодзи-подсказка по названию — нужна в списках чатов и истории операций,
    /// где нет места под анимацию.
    static func emoji(for name: String) -> String {
        let lowered = name.lowercased()
        for (needle, symbol) in table where lowered.contains(needle) {
            return symbol
        }
        return "🎁"
    }

    private static let table: [(String, String)] = [
        ("rose", "🌹"), ("tulip", "🌷"), ("peony", "🌸"), ("sakura", "🌸"),
        ("bouquet", "💐"), ("flower", "🌷"), ("wreath", "🎄"),
        ("bear", "🧸"), ("rabbit", "🐰"), ("bunny", "🐰"), ("cat", "🐱"),
        ("puppy", "🐶"), ("dog", "🐶"), ("frog", "🐸"), ("snake", "🐍"),
        ("monkey", "🐵"), ("flamingo", "🦩"), ("dove", "🕊️"), ("horse", "🐴"),
        ("heart", "❤️"), ("locket", "💝"), ("love", "💘"),
        ("cake", "🎂"), ("cupcake", "🧁"), ("gingerbread", "🍪"),
        ("chocolate", "🍫"), ("candy", "🍬"), ("lollipop", "🍭"),
        ("ice cream", "🍦"), ("cocktail", "🍹"), ("champagne", "🍾"),
        ("cocoa", "☕️"), ("noodle", "🍜"), ("plum", "🫐"),
        ("rocket", "🚀"), ("star", "⭐️"), ("moon", "🌙"),
        ("diamond", "💎"), ("crystal", "🔮"), ("gold", "🏆"), ("cup", "🏆"),
        ("medal", "🏅"), ("ring", "💍"), ("bracelet", "📿"), ("watch", "⌚️"),
        ("key", "🔑"), ("lamp", "🪔"), ("candle", "🕯️"), ("book", "📖"),
        ("pen", "🖊️"), ("phone", "📱"), ("record", "🎵"), ("microphone", "🎤"),
        ("guitar", "🎸"), ("surfboard", "🏄"), ("helmet", "⛑️"),
        ("sneakers", "👟"), ("shoes", "👠"), ("socks", "🧦"), ("sweater", "🧥"),
        ("hat", "🎩"), ("cap", "🧢"), ("sunglasses", "🕶️"),
        ("backpack", "🎒"), ("bag", "👜"), ("brick", "🧱"), ("cigar", "🚬"),
        ("potion", "🧪"), ("skull", "💀"), ("ghost", "👻"), ("vampire", "🧛"),
        ("witch", "🧙"), ("pumpkin", "🎃"), ("web", "🕸️"), ("coffin", "⚰️"),
        ("reaper", "☠️"), ("haunted", "🏚️"), ("hockey", "🏒"),
        ("snow", "❄️"), ("christmas", "🎄"), ("santa", "🎅"),
        ("pump", "🎃"), ("frog", "🐸"), ("biceps", "💪"), ("warrior", "⚔️"),
        ("torch", "🔥"), ("sabre", "⚔️"), ("saber", "⚔️"), ("airplane", "✈️"),
        ("statue", "🗽"), ("castle", "🏰"), ("house", "🏚️"),
    ]
}