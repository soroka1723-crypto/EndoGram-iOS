import SwiftUI

/// Визуальные эффекты для NFT: анимированный фон, аура редкости, шиммер.
///
/// Всё построено на `TimelineView`, а не на бесконечных `repeatForever`
/// анимациях: так кадры считаются только пока экран на экране, а при
/// выключенных анимациях в настройках (`Appearance_Animations`) отрисовка
/// замирает на одном кадре.
enum NFTVisuals {

    /// Цвет редкости — от обычного к мифическому.
    static func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "обычный":      return Color(hex: "#8E8E93")
        case "редкий":       return Color(hex: "#3E88F7")
        case "эпический":    return Color(hex: "#955CDB")
        case "легендарный":  return Color(hex: "#F5C038")
        case "мифический":   return Color(hex: "#FF4D6D")
        default:             return Color(hex: "#8E8E93")
        }
    }

    /// Насколько «дорого» выглядит редкость — влияет на силу эффектов.
    static func rarityLevel(_ rarity: String) -> Int {
        switch rarity.lowercased() {
        case "обычный":      return 0
        case "редкий":       return 1
        case "эпический":    return 2
        case "легендарный":  return 3
        case "мифический":   return 4
        default:             return 0
        }
    }
}

/// Анимированный фон NFT-экрана: медленно плывущие цветные пятна.
struct AnimatedAurora: View {
    let colorHex: String
    var secondaryHex: String = "#1B2A44"
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    Color(hex: "#04050A")

                    blob(colorHex, opacity: 0.55, size: w * 0.95)
                        .offset(x: cos(t * 0.45) * w * 0.22,
                                y: sin(t * 0.33) * h * 0.10 - h * 0.12)
                    blob(secondaryHex, opacity: 0.48, size: w * 0.85)
                        .offset(x: sin(t * 0.30) * w * 0.28,
                                y: cos(t * 0.42) * h * 0.12 + h * 0.14)
                    blob(colorHex, opacity: 0.30, size: w * 0.62)
                        .offset(x: cos(t * 0.61 + 1.7) * w * 0.30,
                                y: sin(t * 0.55 + 0.6) * h * 0.16)
                }
                .blur(radius: 60)
                .overlay(Color.black.opacity(0.25))
                .ignoresSafeArea()
            }
        }
    }

    private func blob(_ hex: String, opacity: Double, size: CGFloat) -> some View {
        Circle()
            .fill(Color(hex: hex).opacity(opacity))
            .frame(width: size, height: size)
    }
}

/// Дешёвый аналог аурора для карточек в списке: один пульсирующий блик.
struct CardGlow: View {
    let colorHex: String
    var animated: Bool = true
    var intensity: Double = 1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            let pulse = 0.5 + 0.5 * sin(t * 1.1)
            ZStack {
                LinearGradient(
                    colors: [Color(hex: colorHex).opacity(0.28 * intensity),
                             Color(hex: colorHex).opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color(hex: colorHex).opacity(0.35 * intensity * (0.55 + 0.45 * pulse)), .clear],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: 120
                )
            }
        }
    }
}

/// Диагональный блик, проходящий по карточке — как на коллекционных подарках.
struct ShimmerSweep: ViewModifier {
    var animated: Bool = true
    var period: Double = 2.6

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
                let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
                let phase = (t.truncatingRemainder(dividingBy: period)) / period
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [.clear,
                                 Color.white.opacity(0.24),
                                 .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: width * 0.45, height: geo.size.height * 1.6)
                    .rotationEffect(.degrees(18))
                    .offset(x: -width * 0.6 + phase * width * 1.9,
                            y: -geo.size.height * 0.3)
                    .blendMode(.plusLighter)
                }
            }
            .allowsHitTesting(false)
            .mask(content)
        }
    }
}

extension View {
    /// Пробегающий блик поверх содержимого.
    func shimmer(animated: Bool = true, period: Double = 2.6) -> some View {
        modifier(ShimmerSweep(animated: animated, period: period))
    }
}

/// Эмодзи NFT с мягким парением и свечением.
struct FloatingNFTEmoji: View {
    let emoji: String
    let colorHex: String
    var size: CGFloat = 52
    var rarity: String = ""
    var animated: Bool = true

    private var level: Int { NFTVisuals.rarityLevel(rarity) }
    private var aura: Color { NFTVisuals.rarityColor(rarity) }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            let float = sin(t * 1.2) * (2.0 + Double(level) * 0.8)
            let glow = 0.55 + 0.45 * sin(t * 1.6)

            ZStack {
                if level >= 2 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [aura.opacity(0.55 * glow), .clear],
                                center: .center,
                                startRadius: size * 0.2,
                                endRadius: size * 1.15
                            )
                        )
                        .frame(width: size * 1.9, height: size * 1.9)
                }
                Text(emoji)
                    .font(.system(size: size))
                    .shadow(color: aura.opacity(level >= 2 ? 0.7 * glow : 0.25),
                            radius: level >= 2 ? 14 : 6)
                    .offset(y: float)
            }
            .frame(width: size * 1.6, height: size * 1.6)
        }
    }
}

/// Кольцо вокруг аватара/иконки с градиентом редкости.
struct RarityRing: View {
    let rarity: String
    var lineWidth: CGFloat = 2

    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [NFTVisuals.rarityColor(rarity).opacity(0.95),
                             NFTVisuals.rarityColor(rarity).opacity(0.25),
                             NFTVisuals.rarityColor(rarity).opacity(0.95)],
                    center: .center
                ),
                lineWidth: lineWidth
            )
    }
}