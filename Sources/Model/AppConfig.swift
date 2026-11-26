import Foundation

/// Этап 1: всё хранится локально. Никаких сетевых запросов приложение не делает.
enum AppConfig {
    static let appName = "EndoGram"
    static let appVersion = "1.0.0"
    static let storageFile = "endogram-store.json"
    static let schemaVersion = 1

    /// Стартовый баланс тестовых звёзд.
    static let startingStars = 1_000_000

    /// Цена тестового Premium.
    static let premiumPrice = 2_500

    static let premiumDays = 365
}
