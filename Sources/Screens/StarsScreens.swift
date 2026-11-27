import SwiftUI

/// Магазин подарков — настоящий каталог Telegram.
///
/// 152 подарка с реальными названиями, ценами в звёздах и тиражами; картинки
/// и анимации взяты из `.tgs`/`.png` официальных подарков (CDN
/// `cdn-telegram-gifts`). Структура экрана — по `Gift.Options.*` оригинала.
///
/// Всё локально: «покупка» списывает тестовые звёзды и кладёт подарок
/// в инвентарь на этом устройстве.
struct GiftShopView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selected: Gift?
    @State private var toast: String?
    @State private var filter: GiftFilter = .all
    @State private var query = ""

    /// `Gift.Options.Gift.Filter.*`
    enum GiftFilter: String, CaseIterable, Identifiable {
        case all, limited, inStock, collectibles, mine

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:          return "Все подарки"
            case .limited:      return "Лимитированные"
            case .inStock:      return "В наличии"
            case .collectibles: return "Коллекционные"
            case .mine:         return "Мои подарки"
            }
        }
    }

    private var gifts: [Gift] {
        let base: [Gift]
        switch filter {
        case .all:
            base = env.giftCatalog
        case .limited:
            base = env.giftCatalog.filter(\.isLimited)
        case .inStock:
            base = env.giftCatalog.filter { !$0.isSoldOut }
        case .collectibles:
            base = env.giftCatalog.filter(\.isCollectible)
        case .mine:
            let owned = Set(env.snapshot.ownedGifts.map(\.giftId))
            base = env.giftCatalog.filter { owned.contains($0.id) }
        }

        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return base }
        return base.filter {
            $0.name.lowercased().contains(needle) || $0.rarity.lowercased().contains(needle)
        }
    }

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    balanceCard
                    SearchField(placeholder: "Поиск подарка", text: $query)
                        .padding(.horizontal, 12)
                    filterChips

                    if gifts.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "gift")
                                .font(.system(size: 34))
                                .foregroundColor(Theme.textSecondary)
                            Text(filter == .mine ? "Подарков пока нет" : "Здесь пусто")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Подарки хранятся на этом устройстве.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(gifts) { gift in
                                Button {
                                    selected = gift
                                } label: {
                                    GiftTile(
                                        gift: gift,
                                        animated: env.snapshot.settings.animationsEnabled,
                                        size: 84
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    Text("Подарки настоящие: названия, цены в звёздах, тиражи и анимации — из Telegram. Звёзды тестовые: покупка списывает локальный баланс и создаёт запись в истории операций.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.82)))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Подарки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selected) { gift in
            GiftPurchaseView(gift: gift, onResult: { message in
                showToast(message)
            })
            .environmentObject(env)
        }
    }

    /// `Gift.Send.PayWithStars.Info` — «Ваш баланс: N ⭐️».
    private var balanceCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(Theme.star)
            VStack(alignment: .leading, spacing: 1) {
                Text("Ваш баланс")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                Text("\(Format.number(env.stars)) ⭐️")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            NavigationLink { MyStarsView().environmentObject(env) } label: {
                Text("Пополнить")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accentBright)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.accent.opacity(0.16)))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.panel))
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GiftFilter.allCases) { item in
                    let isActive = item == filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { filter = item }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? .white : Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(isActive ? Theme.accent : Theme.panel)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { if toast == text { toast = nil } }
        }
    }
}

/// Покупка подарка: себе в инвентарь или в чат.
struct GiftPurchaseView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let gift: Gift
    let onResult: (String) -> Void

    @State private var selectedChatId: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        heroPanel

                        VStack(spacing: 4) {
                            Text(gift.name)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(gift.rarity)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                            HStack(spacing: 4) {
                                Text("⭐️")
                                Text(Format.number(gift.price))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Theme.star)
                            }
                            .padding(.top, 2)
                        }

                        facts

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Куда отправить")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                Button {
                                    selectedChatId = nil
                                } label: {
                                    HStack {
                                        Image(systemName: "tray.and.arrow.down.fill")
                                            .foregroundColor(Theme.accentBright)
                                        Text("Оставить себе в инвентарь")
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        if selectedChatId == nil {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentBright)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)

                                DividerLine()

                                ForEach(env.sorted(env.snapshot.chats)) { chat in
                                    Button {
                                        selectedChatId = chat.id
                                    } label: {
                                        HStack {
                                            AvatarView(title: chat.title, colorHex: chat.avatarColor, size: 30)
                                            Text(chat.title)
                                                .foregroundColor(Theme.textPrimary)
                                                .lineLimit(1)
                                            Spacer()
                                            if selectedChatId == chat.id {
                                                Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentBright)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.panel))
                            .padding(.horizontal, 16)
                        }

                        if let error {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.danger)
                        }

                        Button {
                            if let error = env.buyGift(gift, toChatId: selectedChatId) {
                                self.error = error
                            } else {
                                onResult("Подарок «\(gift.name)» получен")
                                dismiss()
                            }
                        } label: {
                            Text("Купить за \(Format.stars(gift.price))")
                        }
                        .buttonStyle(StarButtonStyle())
                        .padding(.horizontal, 16)

                        Text("Баланс: \(Format.stars(env.stars))")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Подарок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    /// Большая анимация подарка — как в карточке подарка Telegram.
    private var heroPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: gift.colorHex).opacity(0.42),
                                 Color(hex: gift.colorHex).opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            GiftAnimationView(
                assetId: GiftCatalog.assetId(for: gift),
                size: 190,
                duration: gift.duration,
                animated: env.snapshot.settings.animationsEnabled,
                fallbackEmoji: gift.emoji
            )
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: gift.colorHex).opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    /// Характеристики подарка — тираж и состояние продаж из данных Telegram.
    private var facts: some View {
        VStack(spacing: 0) {
            fact("Редкость", gift.rarity)
            if let total = gift.totalSupply {
                DividerLine(inset: 14)
                fact("Тираж", Format.number(total))
            }
            DividerLine(inset: 14)
            fact("Состояние", gift.soldOutInTelegram ? "тираж распродан" : "в продаже")
            if gift.isCollectible {
                DividerLine(inset: 14)
                fact("Коллекционный", "да")
            }
        }
        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.panel))
        .padding(.horizontal, 16)
    }

    private func fact(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textListItemSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

/// Рынок NFT.
struct NFTMarketView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selected: NFTItem?
    @State private var toast: String?
    @State private var query = ""

    private var items: [NFTItem] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return env.nftCatalog }
        return env.nftCatalog.filter {
            $0.name.lowercased().contains(needle) || $0.rarity.lowercased().contains(needle)
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                // LazyVStack важен: в каталоге 124 предмета, и у каждого карточки
                // есть TimelineView-анимация. Ленивый стек не создаёт их для
                // того, что за экраном.
                LazyVStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Коллекции")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("⭐️ \(Format.number(env.stars))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.star)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    SearchField(placeholder: "Поиск подарка", text: $query)
                        .padding(.horizontal, 12)

                    Text("Коллекционных подарков: \(items.count)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 14)

                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 30))
                                .foregroundColor(Theme.textSecondary)
                            Text("Ничего не найдено")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    ForEach(items) { item in
                        Button {
                            selected = item
                        } label: {
                            nftCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
            }
            if let toast {
                Text(toast)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
            }
        }
        .navigationTitle("NFT")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selected) { item in
            NFTDetailView(item: item) { message in
                toast = message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { toast = nil }
            }
            .environmentObject(env)
        }
    }

    private func nftCard(_ item: NFTItem) -> some View {
        let level = NFTVisuals.rarityLevel(item.rarity)
        let animated = env.snapshot.settings.animationsEnabled

        return HStack(spacing: 12) {
            ZStack {
                CardGlow(colorHex: item.colorHex, animated: animated,
                         intensity: level >= 3 ? 1.4 : 1.0)
                FloatingNFTEmoji(emoji: item.emoji, colorHex: item.colorHex,
                                 size: 34, rarity: item.rarity, animated: animated)
            }
            .frame(width: 74, height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(NFTVisuals.rarityColor(item.rarity).opacity(level >= 2 ? 0.55 : 0.2),
                            lineWidth: 1)
            )
            .shimmer(animated: animated && level >= 3, period: 3.2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.collection)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.accentBright)
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("#\(item.serial) из \(item.totalSupply)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                HStack(spacing: 4) {
                    Text("⭐️").font(.system(size: 11))
                    Text(Format.number(item.price))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            Spacer()
            Text(item.rarity)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(NFTVisuals.rarityColor(item.rarity).opacity(0.28)))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .stroke(NFTVisuals.rarityColor(item.rarity).opacity(level >= 3 ? 0.35 : 0), lineWidth: 1)
        )
        .padding(.horizontal, 12)
    }
}

struct NFTDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let item: NFTItem
    let onResult: (String) -> Void

    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Анимированный фон из цвета коллекции.
                AnimatedAurora(colorHex: item.colorHex,
                               secondaryHex: Palette.purple,
                               animated: env.snapshot.settings.animationsEnabled)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        heroPanel

                        VStack(spacing: 5) {
                            Text(item.collection)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.accentBright)
                            Text(item.name)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            HStack(spacing: 6) {
                                Text("#\(item.serial) из \(item.totalSupply)")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                                Text(item.rarity)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(NFTVisuals.rarityColor(item.rarity).opacity(0.85)))
                            }
                        }

                        Text(item.description)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        rarityFacts

                        HStack(spacing: 5) {
                            Text("⭐️")
                            Text(Format.number(item.price))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Theme.star)
                        }

                        if let error {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.danger)
                        }

                        Button {
                            if let error = env.buyNFT(item) {
                                self.error = error
                            } else {
                                onResult("NFT «\(item.name)» добавлен в коллекцию")
                                dismiss()
                            }
                        } label: {
                            Text("Купить за \(Format.stars(item.price))")
                        }
                        .buttonStyle(StarButtonStyle())
                        .padding(.horizontal, 16)

                        Text("Баланс: \(Format.stars(env.stars))")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("NFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    /// Большая карточка NFT: свечение, парящий эмодзи и блик для редких.
    private var heroPanel: some View {
        let level = NFTVisuals.rarityLevel(item.rarity)
        let animated = env.snapshot.settings.animationsEnabled

        return ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: item.colorHex).opacity(0.42),
                                 Color(hex: item.colorHex).opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            FloatingNFTEmoji(emoji: item.emoji, colorHex: item.colorHex,
                             size: 96, rarity: item.rarity, animated: animated)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(NFTVisuals.rarityColor(item.rarity).opacity(level >= 2 ? 0.6 : 0.22),
                        lineWidth: level >= 2 ? 1.6 : 1)
        )
        .shimmer(animated: animated && level >= 2, period: 3.0)
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    /// Характеристики коллекции — как карточка предмета в Telegram.
    private var rarityFacts: some View {
        VStack(spacing: 0) {
            fact("Коллекция", item.collection)
            DividerLine(inset: 14)
            fact("Редкость", item.rarity, valueColor: NFTVisuals.rarityColor(item.rarity))
            DividerLine(inset: 14)
            fact("Номер", "#\(item.serial)")
            DividerLine(inset: 14)
            fact("Тираж", "\(item.totalSupply)")
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.panel.opacity(0.9))
        )
        .padding(.horizontal, 16)
    }

    private func fact(_ title: String, _ value: String, valueColor: Color = Theme.textListItemSecondary) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

/// Инвентарь: купленные подарки и NFT.
struct InventoryView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if env.snapshot.ownedGifts.isEmpty && env.snapshot.ownedNFTs.isEmpty {
                        EmptyStateView(
                            icon: "shippingbox",
                            title: "Подарков пока нет",
                            subtitle: "Купите подарок или NFT в разделе «Звёзды» — они появятся здесь, на этом устройстве."
                        )
                        .frame(height: 360)
                    }

                    if !env.snapshot.ownedGifts.isEmpty {
                        SectionCard(title: "Подарки (\(env.snapshot.ownedGifts.count))") {
                            ForEach(env.snapshot.ownedGifts.reversed()) { gift in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(hex: gift.colorHex).opacity(0.16))
                                        GiftAnimationView(
                                            assetId: GiftCatalog.assetId(forGiftId: gift.giftId),
                                            size: 40,
                                            animated: env.snapshot.settings.animationsEnabled,
                                            fallbackEmoji: gift.emoji
                                        )
                                    }
                                    .frame(width: 46, height: 46)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(gift.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("\(gift.rarity) · \(Format.number(gift.pricePaid)) ⭐️")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textSecondary)
                                        Text(Format.fullDate(gift.receivedAt))
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textSecondary.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                if gift.id != env.snapshot.ownedGifts.first?.id {
                                    DividerLine()
                                }
                            }
                        }
                    }

                    if !env.snapshot.ownedNFTs.isEmpty {
                        SectionCard(title: "NFT (\(env.snapshot.ownedNFTs.count))") {
                            ForEach(env.snapshot.ownedNFTs.reversed()) { nft in
                                HStack(spacing: 12) {
                                    ZStack {
                                        CardGlow(colorHex: nft.colorHex,
                                                 animated: env.snapshot.settings.animationsEnabled,
                                                 intensity: 0.9)
                                        FloatingNFTEmoji(emoji: nft.emoji, colorHex: nft.colorHex,
                                                         size: 24, rarity: nft.rarity,
                                                         animated: env.snapshot.settings.animationsEnabled)
                                    }
                                    .frame(width: 46, height: 46)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(NFTVisuals.rarityColor(nft.rarity).opacity(0.45), lineWidth: 1)
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(nft.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("\(nft.collection) · #\(nft.serial)/\(nft.totalSupply)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textSecondary)
                                        Text("Куплено за \(Format.number(nft.pricePaid)) ⭐️")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textSecondary.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                if nft.id != env.snapshot.ownedNFTs.first?.id {
                                    DividerLine()
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Мои подарки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}


/// Экран Telegram Premium.
struct PremiumView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var message: String?

    /// Состав подписки перенесён из инвентаря настроек Telegram
    /// (`premiumSearchableItems`): ключ оригинала → иконка → название → описание.
    private struct PremiumFeature: Identifiable {
        let id: String
        let icon: String
        let title: String
        let detail: String
    }

    private let features: [PremiumFeature] = [
        PremiumFeature(id: "Premium_DoubledLimits", icon: "infinity", title: "Удвоенные лимиты",
                       detail: "До 1000 каналов, 20 папок, 10 закреплённых чатов, 20 публичных ссылок."),
        PremiumFeature(id: "Premium_UploadSize", icon: "arrow.up.doc.fill", title: "Загрузка до 4 ГБ",
                       detail: "Размер одного документа увеличен с 2 ГБ до 4 ГБ, объём хранилища не ограничен."),
        PremiumFeature(id: "Premium_FasterSpeed", icon: "bolt.fill", title: "Скорость скачивания выше",
                       detail: "Без ограничений скорости при загрузке медиа и документов."),
        PremiumFeature(id: "Premium_VoiceToText", icon: "waveform", title: "Голос в текст",
                       detail: "Расшифровка любого входящего голосового сообщения."),
        PremiumFeature(id: "Premium_NoAds", icon: "hand.raised.fill", title: "Без рекламы",
                       detail: "В публичных каналах больше не показывается реклама."),
        PremiumFeature(id: "Premium_EmojiStatus", icon: "face.smiling.inverse", title: "Эмодзи-статус",
                       detail: "Эмодзи рядом с именем, которое видят другие пользователи."),
        PremiumFeature(id: "Premium_Reactions", icon: "heart.circle.fill", title: "Уникальные реакции",
                       detail: "Дополнительные анимированные реакции на сообщения."),
        PremiumFeature(id: "Premium_Stickers", icon: "square.stack.3d.up.fill", title: "Премиум-стикеры",
                       detail: "Эксклюзивные увеличенные стикеры с дополнительными эффектами."),
        PremiumFeature(id: "Premium_AnimatedEmoji", icon: "sparkles", title: "Анимированные эмодзи",
                       detail: "Анимированные эмодзи в сообщениях и реакциях."),
        PremiumFeature(id: "Premium_ChatManagement", icon: "folder.badge.gearshape", title: "Продвинутое управление чатами",
                       detail: "Папка по умолчанию, автоархив и скрытие новых чатов от незнакомцев."),
        PremiumFeature(id: "Premium_Badge", icon: "checkmark.seal.fill", title: "Значок в профиле",
                       detail: "Отметка подписчика рядом с вашим именем."),
        PremiumFeature(id: "Premium_Avatar", icon: "person.crop.circle.badge.plus", title: "Анимированный аватар",
                       detail: "Аватар с анимацией и дополнительными эффектами."),
        PremiumFeature(id: "Premium_AppIcon", icon: "app.badge.fill", title: "Иконки приложения",
                       detail: "Набор дополнительных иконок EndoGram."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    planCard
                    featureList
                    if let message {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.online)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    activateButton
                    offlineNote
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Telegram Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.star, Color(hex: Palette.orange)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            Text("Telegram Premium")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text("Больше возможностей и поддержка разработки.")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 22)
    }

    private var planCard: some View {
        VStack(spacing: 12) {
            if env.profile.premiumActive {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Theme.online)
                    Text("Premium активен")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                Text("Действует до \(env.profile.premiumUntil.map { Format.fullDate($0) } ?? "—")")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    planTile(title: "Месяц", price: Format.stars(AppConfig.premiumPrice / 12), selected: false)
                    planTile(title: "Год", price: Format.stars(AppConfig.premiumPrice), selected: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner + 2, style: .continuous)
                .fill(Theme.panel)
        )
        .padding(.horizontal, 16)
    }

    private func planTile(title: String, price: String, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(price)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(selected ? Theme.star.opacity(0.16) : Theme.panelElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .stroke(selected ? Theme.star : Color.clear, lineWidth: 1.5)
        )
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(features) { feature in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.star.opacity(0.16))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: feature.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.star)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text(feature.detail)
                            .font(.system(size: 12.5))
                            .foregroundColor(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if feature.id != features.last?.id {
                    DividerLine(inset: 60)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.corner + 2, style: .continuous)
                .fill(Theme.panel)
        )
        .padding(.horizontal, 16)
    }

    private var activateButton: some View {
        Button {
            if env.profile.premiumActive {
                message = "Premium уже активен"
            } else if let error = env.activatePremium() {
                message = error
            } else {
                message = "Premium активирован до \(env.profile.premiumUntil.map { Format.fullDate($0) } ?? "")"
            }
        } label: {
            Text(env.profile.premiumActive
                 ? "Premium активен"
                 : "Активировать за \(Format.stars(AppConfig.premiumPrice))")
        }
        .buttonStyle(StarButtonStyle(filled: !env.profile.premiumActive))
        .disabled(env.profile.premiumActive)
        .padding(.horizontal, 16)
    }

    private var offlineNote: some View {
        VStack(spacing: 6) {
            Text("Баланс: \(Format.stars(env.stars))")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            Text("Названия и состав подписки перенесены из Telegram. В офлайн-режиме серверные возможности (загрузка файлов, голос в текст, анимированные аватары) не работают — здесь Premium включает локальные эффекты: значок в профиле, статус и эксклюзивные подарки.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}