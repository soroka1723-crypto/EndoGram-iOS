import Foundation

/// Р­С‚Р°Рї 1: РІСЃС‘ С…СЂР°РЅРёС‚СЃСЏ Р»РѕРєР°Р»СЊРЅРѕ. РќРёРєР°РєРёС… СЃРµС‚РµРІС‹С… Р·Р°РїСЂРѕСЃРѕРІ РїСЂРёР»РѕР¶РµРЅРёРµ РЅРµ РґРµР»Р°РµС‚.
enum AppConfig {
    static let appName = "EndoGram"
    static let storageFile = "endogram-store.json"
    static let schemaVersion = 1

    /// РЎС‚Р°СЂС‚РѕРІС‹Р№ Р±Р°Р»Р°РЅСЃ С‚РµСЃС‚РѕРІС‹С… Р·РІС‘Р·Рґ.
    static let startingStars = 1_000_000

    /// Р¦РµРЅР° С‚РµСЃС‚РѕРІРѕРіРѕ Premium.
    static let premiumPrice = 2_500

    static let premiumDays = 365
}

