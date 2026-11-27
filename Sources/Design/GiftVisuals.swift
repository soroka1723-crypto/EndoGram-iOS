import SwiftUI
import UIKit

/// Кэш картинок подарков: спрайт-листы и превью грузятся один раз.
///
/// Спрайт-лист — это 4×4 кадров анимации `.tgs`, сконвертированных из
/// настоящего файла Telegram. Кадры лежат в `Resources/Gifts/Anim`.
enum GiftArt {
    static let columns = 4
    static let rows = 4
    static var frames: Int { columns * rows }

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // Спрайт-лист 512×512 в памяти — около мегабайта. Держим не больше
        // сорока: при прокрутке витрины этого хватает, а память не растёт.
        cache.countLimit = 40
        return cache
    }()

    static func preview(_ assetId: String) -> UIImage? {
        image("gift_\(assetId)")
    }

    static func sheet(_ assetId: String) -> UIImage? {
        image("gift_\(assetId)_anim")
    }

    /// XcodeGen кладёт ресурсы из `Resources` в корень бандла, поэтому имя
    /// ищется плоско; путь с подпапкой проверяется вторым — на случай, если
    /// папка добавлена как folder reference.
    private static func image(_ name: String) -> UIImage? {
        let key = name as NSString
        if let hit = cache.object(forKey: key) { return hit }

        let candidates = [
            Bundle.main.url(forResource: name, withExtension: "png"),
            Bundle.main.url(forResource: "Gifts/Preview/\(name)", withExtension: "png"),
            Bundle.main.url(forResource: "Gifts/Anim/\(name)", withExtension: "png"),
        ]
        guard let url = candidates.compactMap({ $0 }).first,
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }
}

/// Статичный подарок: настоящее превью из Telegram.
struct GiftImageView: View {
    let assetId: String
    var size: CGFloat = 56
    /// Запасной эмодзи, если ассета нет в бандле.
    var fallbackEmoji: String = "🎁"

    var body: some View {
        Group {
            if let image = GiftArt.preview(assetId) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Text(fallbackEmoji)
                    .font(.system(size: size * 0.62))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Анимированный подарок.
///
/// Анимация — настоящая: кадры взяты из `.tgs`-файла Telegram и разложены
/// в спрайт-лист 4×4. Кадры считает `TimelineView`, а не `repeatForever`,
/// поэтому вне экрана и при выключенных анимациях в настройках ничего не
/// крутится вхолостую.
struct GiftAnimationView: View {
    let assetId: String
    var size: CGFloat = 96
    var duration: Double = 3
    var animated: Bool = true
    var fallbackEmoji: String = "🎁"

    @State private var startedAt = Date()

    var body: some View {
        Group {
            if let sheet = GiftArt.sheet(assetId) {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                        sprite(sheet, at: context.date)
                    }
                } else {
                    // Один кадр — самый выразительный (середина анимации).
                    sprite(sheet, frame: GiftArt.frames / 2)
                }
            } else if let preview = GiftArt.preview(assetId) {
                Image(uiImage: preview)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Text(fallbackEmoji)
                    .font(.system(size: size * 0.62))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func sprite(_ image: UIImage, at date: Date) -> some View {
        let elapsed = date.timeIntervalSince(startedAt)
        let progress = duration > 0 ? elapsed.truncatingRemainder(dividingBy: duration) / duration : 0
        let frame = min(GiftArt.frames - 1, max(0, Int(progress * Double(GiftArt.frames))))
        return sprite(image, frame: frame)
    }

    private func sprite(_ image: UIImage, frame: Int) -> some View {
        let col = frame % GiftArt.columns
        let row = frame / GiftArt.columns
        return Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: size * CGFloat(GiftArt.columns),
                   height: size * CGFloat(GiftArt.rows))
            .offset(x: -CGFloat(col) * size, y: -CGFloat(row) * size)
            .frame(width: size, height: size, alignment: .topLeading)
            .clipped()
    }
}

/// Карточка подарка в витрине: анимированное изображение на градиенте
/// из цвета подарка, с пометками «распродано» и «осталось N».
struct GiftTile: View {
    let gift: Gift
    var animated: Bool = true
    var size: CGFloat = 92

    private var color: Color { Color(hex: gift.colorHex) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [color.opacity(0.38), color.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GiftAnimationView(
                    assetId: GiftCatalog.assetId(for: gift),
                    size: size,
                    duration: gift.duration,
                    animated: animated,
                    fallbackEmoji: gift.emoji
                )

                if gift.isSoldOut {
                    Text("распродано")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.62)))
                }
            }
            .frame(height: size + 18)

            VStack(spacing: 2) {
                Text(gift.name)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 3) {
                    Text("⭐️").font(.system(size: 10))
                    Text(Format.number(gift.price))
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                    if let total = gift.totalSupply {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary.opacity(0.6))
                        Text(total.compact)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary.opacity(0.85))
                    }
                }
            }
            .padding(.vertical, 7)
        }
        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.panel))
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .stroke(gift.isCollectible ? Theme.star.opacity(0.42) : Color.clear, lineWidth: 1)
        )
    }
}