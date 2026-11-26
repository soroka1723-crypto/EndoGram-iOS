import Foundation

// Проверка совместимости локального хранилища.
//
// Смысл: приложение хранит весь аккаунт одним JSON-файлом. Если добавить в
// модель новое поле и не позаботиться о декодировании, файл, записанный
// прошлой версией, перестанет читаться — и аккаунт молча сбросится в новый,
// вместе с чатами, подарками и балансом.
//
// Здесь это проверяется по-настоящему: снапшот кодируется, из JSON удаляются
// ключи, которых не было в старых версиях, и файл читается обратно.
//
// Запуск (на macOS в CI):
//   xcrun swiftc -o /tmp/decode-check Sources/Model/*.swift tools/DecodeCompatibilityCheck.swift
//   /tmp/decode-check

@main
enum StorageCompatibilityCheck {

    static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }

    static func main() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let epoch = Date(timeIntervalSince1970: 1_700_000_000)

        let profile = UserProfile(
            id: "user_local_1",
            username: "endogram",
            displayName: "Локальный пользователь",
            bio: "офлайн",
            phone: "",
            avatarColor: "#368AD1",
            createdAt: epoch,
            isPremium: false,
            premiumUntil: nil
        )

        let chat = Chat(
            id: "chat_1",
            kind: .direct,
            title: "Избранное",
            avatarColor: "#368AD1",
            peerId: "user_local_1",
            memberIds: ["user_local_1"],
            createdAt: epoch,
            isArchived: false,
            isPinned: true,
            isMuted: false,
            folderId: nil,
            unreadCount: 0,
            lastReadAt: epoch
        )

        let message = Message(
            id: "msg_1",
            chatId: "chat_1",
            senderId: "user_local_1",
            authorName: "Локальный пользователь",
            text: "привет",
            createdAt: epoch,
            editedAt: nil
        )

        let gift = OwnedGift(
            id: "owned_1",
            giftId: "gift.bear",
            name: "Медведь",
            emoji: "🧸",
            rarity: "Обычный",
            colorHex: "#C08457",
            pricePaid: 100,
            receivedAt: epoch,
            fromName: "Локальный пользователь",
            chatId: nil
        )

        let nft = OwnedNFT(
            id: "nft_1",
            itemId: "nft.alpha",
            name: "Alpha Ape",
            collection: "Endo Apes",
            emoji: "🐵",
            rarity: "Обычный",
            colorHex: "#C08457",
            serial: 1,
            totalSupply: 10_000,
            pricePaid: 1_200,
            acquiredAt: epoch
        )

        let initial = StoreSnapshot(
            schemaVersion: 1,
            createdAt: epoch,
            updatedAt: epoch,
            profile: profile,
            stars: 1_000_000,
            contacts: [profile],
            chats: [chat],
            folders: [ChatFolder(id: "folder.all", title: "Все", icon: "tray.full.fill", chatIds: [], isSystem: true)],
            messages: [message],
            ledger: [LedgerEntry(id: "l1", kind: .grant, title: "Стартовый баланс", amount: 1_000_000, createdAt: epoch, balanceAfter: 1_000_000)],
            ownedGifts: [gift],
            ownedNFTs: [nft],
            calls: [CallRecord(id: "c1", peerName: "Локальный пользователь", isVideo: false, isOutgoing: true, isMissed: false, startedAt: epoch, duration: 12)],
            settings: AppSettings()
        )

        let fullData = try encoder.encode(initial)

        // MARK: 1. Файл старой версии: ключа stories ещё не существовало
        guard var object = try JSONSerialization.jsonObject(with: fullData) as? [String: Any] else {
            fail("снапшот не сериализуется в словарь")
        }
        object.removeValue(forKey: "stories")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let restored: StoreSnapshot
        do {
            restored = try decoder.decode(StoreSnapshot.self, from: legacyData)
        } catch {
            fail("файл старой версии не читается: \(error)")
        }

        guard restored.stars == 1_000_000 else { fail("баланс звёзд потерян: \(restored.stars)") }
        guard restored.profile.username == "endogram" else { fail("профиль потерян") }
        guard restored.chats.count == 1, restored.messages.count == 1 else { fail("чаты или сообщения потеряны") }
        guard restored.ownedGifts.count == 1, restored.ownedNFTs.count == 1 else { fail("подарки или NFT потеряны") }
        guard restored.calls.count == 1, restored.ledger.count == 1 else { fail("история звонков или операций потеряна") }
        guard restored.stories.isEmpty else { fail("историй не должно быть в старом файле") }
        print("OK  старый файл без ключа stories прочитан: звёзды \(restored.stars), чатов \(restored.chats.count)")

        // MARK: 2. Файл без ключа settings — тоже старая версия
        guard var older = try JSONSerialization.jsonObject(with: fullData) as? [String: Any] else {
            fail("снапшот не сериализуется в словарь")
        }
        older.removeValue(forKey: "settings")
        older.removeValue(forKey: "stories")
        let oldestData = try JSONSerialization.data(withJSONObject: older)
        do {
            let fallback = try decoder.decode(StoreSnapshot.self, from: oldestData)
            guard fallback.settings.notificationsEnabled,
                  fallback.settings.wallpaper == "telegram",
                  fallback.settings.profileColor == "blue" else {
                fail("настройки по умолчанию восстановлены неверно")
            }
        } catch {
            fail("файл без ключа settings не читается: \(error)")
        }
        print("OK  файл без ключа settings прочитан")

        // MARK: 3. Полный round-trip с историями
        let story = Story(
            id: "story_1",
            authorName: "Локальный пользователь",
            caption: "первая история",
            colorHex: "#955CDB",
            createdAt: epoch,
            expiresAt: epoch.addingTimeInterval(24 * 3600)
        )
        var withStory = initial
        withStory.stories = [story]

        let decoded = try decoder.decode(StoreSnapshot.self, from: encoder.encode(withStory))
        guard decoded.stories.count == 1 else { fail("история не сохранилась") }
        guard decoded.stories[0].caption == "первая история" else { fail("подпись истории повреждена") }
        guard decoded.stories[0].views == 0 else { fail("счётчик просмотров повреждён") }
        print("OK  round-trip истории: «\(decoded.stories[0].caption)»")

        // MARK: 4. Старые ключи вложенных типов
        guard var chatObject = try JSONSerialization.jsonObject(with: encoder.encode(chat)) as? [String: Any] else {
            fail("чат не сериализуется")
        }
        chatObject.removeValue(forKey: "wallpaperId")
        let legacyChatData = try JSONSerialization.data(withJSONObject: chatObject)
        let legacyChat = try decoder.decode(Chat.self, from: legacyChatData)
        guard legacyChat.title == "Избранное", legacyChat.wallpaperId == nil else {
            fail("чат без wallpaperId читается неверно")
        }
        print("OK  чат без ключа wallpaperId прочитан")

        var messageObject = try JSONSerialization.jsonObject(with: encoder.encode(message)) as? [String: Any] ?? [:]
        for key in ["replyToId", "reaction", "forwardedFrom", "voiceFileName", "voiceDuration", "voiceWaveform"] {
            messageObject.removeValue(forKey: key)
        }
        let legacyMessageData = try JSONSerialization.data(withJSONObject: messageObject)
        let legacyMessage = try decoder.decode(Message.self, from: legacyMessageData)
        guard legacyMessage.text == "привет", legacyMessage.reaction == nil, legacyMessage.voiceFileName == nil else {
            fail("сообщение старого формата читается неверно")
        }
        print("OK  сообщение без новых ключей прочитано")

        print("ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ: локальные данные переживают обновление модели")
    }
}