import SwiftUI

/// Хаб раздела «Звёзды»: баланс, подарки, NFT, Premium, история.
struct StarsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var route: Route?

    enum Route: Hashable {
        case gifts, nft, premium, history, inventory
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    quickActions
                    premiumCard
                    recentHistory
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Звёзды")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .gifts: GiftShopView().environmentObject(env)
            case .nft: NFTMarketView().environmentObject(env)
            case .premium: PremiumView().environmentObject(env)
            case .history: LedgerView().environmentObject(env)
            case .inventory: InventoryView().environmentObject(env)
            }
        }
    }

    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Ваш баланс")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
            HStack(spacing: 8) {
                Text("⭐️").font(.system(size: 26))
                Text(Format.number(env.stars))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text("тестовые звёзды EndoGram")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 8) {
                NavigationLink(value: Route.inventory) {
                    Text("Мои подарки")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }
                NavigationLink(value: Route.history) {
                    Text("История")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2AABEE"), Color(hex: "#1A76C2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            tile(icon: "gift.fill", title: "Подарки", subtitle: "\(env.snapshot.ownedGifts.count) шт.", route: .gifts, tint: Color(hex: "#E4572E"))
            tile(icon: "sparkles", title: "NFT", subtitle: "\(env.snapshot.ownedNFTs.count) шт.", route: .nft, tint: Color(hex: "#7C5CFF"))
        }
        .padding(.horizontal, 12)
    }

    private func tile(icon: String, title: String, subtitle: String, route: Route, tint: Color) -> some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(tint))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.panel))
        }
        .buttonStyle(.plain)
    }

    private var premiumCard: some View {
        NavigationLink(value: Route.premium) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.star)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.star.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(env.profile.premiumActive ? "EndoGram Premium активен" : "EndoGram Premium")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(env.profile.premiumActive
                         ? "Действует до \(env.profile.premiumUntil.map { Format.fullDate($0) } ?? "—")"
                         : "Эксклюзивные функции за \(Format.stars(AppConfig.premiumPrice))")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.panel))
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    private var recentHistory: some View {
        SectionCard(title: "Последние операции") {
            ForEach(env.ledger.prefix(4)) { entry in
                LedgerRow(entry: entry)
                if entry.id != env.ledger.prefix(4).last?.id {
                    DividerLine()
                }
            }
            NavigationLink(value: Route.history) {
                HStack {
                    Text("Вся история")
                        .foregroundColor(Theme.accentBright)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Строка истории операций.
struct LedgerRow: View {
    let entry: LedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tint))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(Format.fullDate(entry.createdAt))
                    .font(.system(size: 11.5))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.amount == 0 ? "—" : Format.signedStars(entry.amount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(entry.amount >= 0 ? Theme.online : Theme.textPrimary)
                Text("баланс: \(Format.number(entry.balanceAfter))")
                    .font(.system(size: 10.5))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var tint: Color {
        switch entry.kind {
        case .grant: return Theme.online
        case .gift: return Color(hex: "#E4572E")
        case .nft: return Color(hex: "#7C5CFF")
        case .premium: return Theme.star
        case .transfer: return Theme.accent
        case .refund: return Theme.accentBright
        }
    }
}

/// Полная история операций.
struct LedgerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var filter: LedgerKind?

    private var entries: [LedgerEntry] {
        guard let filter else { return env.ledger }
        return env.ledger.filter { $0.kind == filter }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip("Все", active: filter == nil) { filter = nil }
                            ForEach([LedgerKind.grant, .gift, .nft, .premium, .transfer], id: \.self) { kind in
                                chip(kind.title, active: filter == kind) { filter = kind }
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    if entries.isEmpty {
                        Text("Операций пока нет")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 40)
                    } else {
                        SectionCard(title: nil) {
                            ForEach(entries) { entry in
                                LedgerRow(entry: entry)
                                if entry.id != entries.last?.id { DividerLine() }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("История операций")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func chip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(active ? .white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(active ? Theme.accent : Theme.panel))
        }
        .buttonStyle(.plain)
    }
}