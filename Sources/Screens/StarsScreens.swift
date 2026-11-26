import SwiftUI

/// РњР°РіР°Р·РёРЅ РїРѕРґР°СЂРєРѕРІ.
struct GiftShopView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selected: Gift?
    @State private var error: String?
    @State private var toast: String?

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("в­ђпёЏ \(Format.number(env.stars))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("РџРѕРґР°СЂРєРё")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(env.giftCatalog) { gift in
                            Button {
                                selected = gift
                            } label: {
                                giftCard(gift)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
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
        .navigationTitle("РџРѕРґР°СЂРєРё")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selected) { gift in
            GiftPurchaseView(gift: gift, onResult: { message in
                toast = message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { toast = nil }
            })
            .environmentObject(env)
        }
    }

    private func giftCard(_ gift: Gift) -> some View {
        VStack(spacing: 6) {
            Text(gift.emoji)
                .font(.system(size: 46))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: gift.colorHex).opacity(0.14))
                )
            Text(gift.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
            HStack(spacing: 3) {
                Text("в­ђпёЏ").font(.system(size: 11))
                Text(Format.number(gift.price))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.panel))
    }
}

/// РџРѕРєСѓРїРєР° РїРѕРґР°СЂРєР°: СЃРµР±Рµ РІ РёРЅРІРµРЅС‚Р°СЂСЊ РёР»Рё РІ С‡Р°С‚.
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
                VStack(spacing: 18) {
                    Text(gift.emoji)
                        .font(.system(size: 88))
                        .padding(.top, 20)

                    VStack(spacing: 4) {
                        Text(gift.name)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text(gift.rarity)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                        HStack(spacing: 4) {
                            Text("в­ђпёЏ")
                            Text(Format.number(gift.price))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.star)
                        }
                        .padding(.top, 2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("РљСѓРґР° РѕС‚РїСЂР°РІРёС‚СЊ")
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
                                    Text("РћСЃС‚Р°РІРёС‚СЊ СЃРµР±Рµ РІ РёРЅРІРµРЅС‚Р°СЂСЊ")
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
                            onResult("РџРѕРґР°СЂРѕРє В«\(gift.name)В» РїРѕР»СѓС‡РµРЅ")
                            dismiss()
                        }
                    } label: {
                        Text("РљСѓРїРёС‚СЊ Р·Р° \(Format.stars(gift.price))")
                    }
                    .buttonStyle(StarButtonStyle())
                    .padding(.horizontal, 16)

                    Text("Р‘Р°Р»Р°РЅСЃ: \(Format.stars(env.stars))")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()
                }
            }
            .navigationTitle("РџРѕРґР°СЂРѕРє")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("РћС‚РјРµРЅР°") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// Р С‹РЅРѕРє NFT.
struct NFTMarketView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selected: NFTItem?
    @State private var toast: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("РљРѕР»Р»РµРєС†РёРё")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("в­ђпёЏ \(Format.number(env.stars))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.star)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    ForEach(env.nftCatalog) { item in
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
        .toolbarBackground(Theme.background, for: .navigationBar)
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
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 40))
                .frame(width: 74, height: 74)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: item.colorHex).opacity(0.16)))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.collection)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.accentBright)
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("#\(item.serial) РёР· \(item.totalSupply)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                HStack(spacing: 4) {
                    Text("в­ђпёЏ").font(.system(size: 11))
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
                .background(Capsule().fill(Color(hex: item.colorHex).opacity(0.25)))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.panel))
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
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text(item.emoji)
                        .font(.system(size: 92))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 26)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: item.colorHex).opacity(0.35), Color(hex: item.colorHex).opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                    VStack(spacing: 5) {
                        Text(item.collection)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.accentBright)
                        Text(item.name)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("#\(item.serial) РёР· \(item.totalSupply) В· \(item.rarity)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                    }

                    Text(item.description)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 5) {
                        Text("в­ђпёЏ")
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
                            onResult("NFT В«\(item.name)В» РґРѕР±Р°РІР»РµРЅ РІ РєРѕР»Р»РµРєС†РёСЋ")
                            dismiss()
                        }
                    } label: {
                        Text("РљСѓРїРёС‚СЊ Р·Р° \(Format.stars(item.price))")
                    }
                    .buttonStyle(StarButtonStyle())
                    .padding(.horizontal, 16)

                    Text("Р‘Р°Р»Р°РЅСЃ: \(Format.stars(env.stars))")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("NFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Р—Р°РєСЂС‹С‚СЊ") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// РРЅРІРµРЅС‚Р°СЂСЊ: РєСѓРїР»РµРЅРЅС‹Рµ РїРѕРґР°СЂРєРё Рё NFT.
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
                            title: "РРЅРІРµРЅС‚Р°СЂСЊ РїСѓСЃС‚",
                            subtitle: "РљСѓРїРёС‚Рµ РїРѕРґР°СЂРѕРє РёР»Рё NFT РІ СЂР°Р·РґРµР»Рµ В«Р—РІС‘Р·РґС‹В» вЂ” РѕРЅРё РїРѕСЏРІСЏС‚СЃСЏ Р·РґРµСЃСЊ."
                        )
                        .frame(height: 360)
                    }

                    if !env.snapshot.ownedGifts.isEmpty {
                        SectionCard(title: "РџРѕРґР°СЂРєРё (\(env.snapshot.ownedGifts.count))") {
                            ForEach(env.snapshot.ownedGifts.reversed()) { gift in
                                HStack(spacing: 12) {
                                    Text(gift.emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 46, height: 46)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: gift.colorHex).opacity(0.16)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(gift.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("\(gift.rarity) В· \(Format.number(gift.pricePaid)) в­ђпёЏ")
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
                                    Text(nft.emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 46, height: 46)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: nft.colorHex).opacity(0.16)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(nft.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("\(nft.collection) В· #\(nft.serial)/\(nft.totalSupply)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textSecondary)
                                        Text("РљСѓРїР»РµРЅРѕ Р·Р° \(Format.number(nft.pricePaid)) в­ђпёЏ")
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
        .navigationTitle("РРЅРІРµРЅС‚Р°СЂСЊ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

/// Р­РєСЂР°РЅ Premium.
struct PremiumView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var message: String?

    private let features: [(String, String, String)] = [
        ("bolt.fill", "Р‘С‹СЃС‚СЂРµРµ Рё Р±РµР· СЂРµРєР»Р°РјС‹", "Р›РѕРєР°Р»СЊРЅС‹Р№ СЂРµР¶РёРј СѓР¶Рµ Р±РµР· СЂРµРєР»Р°РјС‹ вЂ” Premium РґРѕР±Р°РІР»СЏРµС‚ СЃС‚Р°С‚СѓСЃ Рё РєРѕР»Р»РµРєС†РёРё."),
        ("star.circle.fill", "Р—РІС‘Р·РґС‹ РІ РїРѕРґР°СЂРѕРє", "РљР°Р¶РґС‹Р№ РјРµСЃСЏС† вЂ” Р±РѕРЅСѓСЃРЅС‹Рµ Р·РІС‘Р·РґС‹ РІ Р»РѕРєР°Р»СЊРЅРѕРј РєРѕС€РµР»СЊРєРµ."),
        ("gift.fill", "Р­РєСЃРєР»СЋР·РёРІРЅС‹Рµ РїРѕРґР°СЂРєРё", "Р”РѕСЃС‚СѓРї Рє РїСЂРµРјРёР°Р»СЊРЅС‹Рј РєРѕР»Р»РµРєС†РёСЏРј РїРѕРґР°СЂРєРѕРІ."),
        ("person.2.fill", "Р‘РѕР»СЊС€Рµ СѓС‡Р°СЃС‚РЅРёРєРѕРІ", "Р›РёРјРёС‚С‹ РіСЂСѓРїРї Рё РєР°РЅР°Р»РѕРІ РІС‹С€Рµ, С‡РµРј Сѓ РѕР±С‹С‡РЅС‹С… Р°РєРєР°СѓРЅС‚РѕРІ."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 46))
                            .foregroundColor(Theme.star)
                        Text("EndoGram Premium")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        if env.profile.premiumActive {
                            Text("РђРєС‚РёРІРµРЅ РґРѕ \(env.profile.premiumUntil.map { Format.fullDate($0) } ?? "вЂ”")")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.online)
                        } else {
                            Text("Р“РѕРґРѕРІР°СЏ РїРѕРґРїРёСЃРєР° Р·Р° \(Format.stars(AppConfig.premiumPrice))")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.top, 20)

                    SectionCard(title: "Р’РѕР·РјРѕР¶РЅРѕСЃС‚Рё") {
                        ForEach(features, id: \.1) { feature in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: feature.0)
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.star)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Theme.star.opacity(0.14)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.1)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(feature.2)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            if feature.1 != features.last?.1 { DividerLine() }
                        }
                    }

                    if let message {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.online)
                    }

                    Button {
                        if env.profile.premiumActive {
                            message = "Premium СѓР¶Рµ Р°РєС‚РёРІРµРЅ"
                        } else if let error = env.activatePremium() {
                            message = error
                        } else {
                            message = "Premium Р°РєС‚РёРІРёСЂРѕРІР°РЅ РґРѕ \(env.profile.premiumUntil.map { Format.fullDate($0) } ?? "")"
                        }
                    } label: {
                        Text(env.profile.premiumActive ? "Premium Р°РєС‚РёРІРµРЅ" : "РђРєС‚РёРІРёСЂРѕРІР°С‚СЊ Р·Р° \(Format.stars(AppConfig.premiumPrice))")
                    }
                    .buttonStyle(StarButtonStyle(filled: !env.profile.premiumActive))
                    .disabled(env.profile.premiumActive)
                    .padding(.horizontal, 16)

                    Text("Р‘Р°Р»Р°РЅСЃ: \(Format.stars(env.stars))")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
