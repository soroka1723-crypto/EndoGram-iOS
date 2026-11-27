import SwiftUI
import UIKit

/// Кэш картинок подарков: превью и кадры анимаций грузятся один раз.
///
/// Анимация — настоящая: кадры взяты из `.tgs`-файлов подарков Telegram
/// и разложены в спрайт-листы 4×4 (`Resources/Gifts/Anim`). Кадр выбирается
/// обрезкой `CGImage`, а не смещением через SwiftUI-layout, поэтому картинка
/// гарантированно попадает в кадр на любой версии системы.
enum GiftArt {

    /// Сетка спрайт-листа: 4 столбца × 4 строки = 16 кадров.
    static let columns = 4
    static let rows = 4
    static var frames: Int { columns * rows }

    // MARK: - Загрузка

    /// Превью 256 pt — первый кадр анимации.
    static func preview(_ assetId: String) -> UIImage? {
        load("gift_\(assetId)")
    }

    /// Спрайт-лист анимации.
    static func sheet(_ assetId: String) -> UIImage? {
        load("gift_\(assetId)_anim")
    }

    /// 16 кадров, нарезанных из спрайт-листа. Готовится один раз на подарок.
    static func animationFrames(_ assetId: String) -> [UIImage]? {
        let key = "frames_\(assetId)"
        if let cached = frameCache.object(forKey: key as NSString) as? [UIImage],
           !cached.isEmpty {
            return cached
        }
        guard let sheet = sheet(assetId),
              let frames = slice(sheet), !frames.isEmpty else {
            return nil
        }
        frameCache.setObject(frames as NSArray, forKey: key as NSString)
        return frames
    }

    /// Нарезка листа 4×4 на отдельные кадры.
    ///
    /// Растеризация через `UIGraphicsImageRenderer`, а не `cg.cropping`:
    /// палитровые PNG (mode `P`) иногда отдают чёрный или испорченный
    /// полупрозрачный кадр при прямой обрезке. Отрисовка в контекст всегда
    /// даёт корректный RGBA.
    private static func slice(_ sheet: UIImage) -> [UIImage]? {
        let w = sheet.size.width / CGFloat(columns)
        let h = sheet.size.height / CGFloat(rows)
        guard w > 0, h > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: w, height: h),
            format: {
                let f = UIGraphicsImageRendererFormat.default()
                f.opaque = false
                f.scale = sheet.scale
                return f
            }()
        )

        var result: [UIImage] = []
        for index in 0..<frames {
            let col = CGFloat(index % columns)
            let row = CGFloat(index / columns)
            let crop = CGRect(x: col * w, y: row * h, width: w, height: h)
            let image = renderer.image { context in
                sheet.draw(
                    in: CGRect(x: -crop.origin.x, y: -crop.origin.y,
                               width: sheet.size.width, height: sheet.size.height)
                )
            }
            result.append(image)
        }
        return result
    }

    // MARK: - Поиск в бандле

    /// XcodeGen кладёт ресурсы плоским списком в корень бандла, но на случай
    /// подключения папки folder reference проверяем и путь с подпапками.
    private static func load(_ name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) {
            return hit
        }
        guard let url = url(for: name),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        cache.setObject(image, forKey: name as NSString)
        return image
    }

    private static func url(for name: String) -> URL? {
        let bundle = Bundle.main
        let flat = bundle.url(forResource: name, withExtension: "png")
        if let flat { return flat }

        // Вариант с folder reference: файл лежит внутри Gifts/… в бандле.
        for directory in ["Gifts/Anim", "Gifts/Preview", "Gifts"] {
            if let url = bundle.url(forResource: "\(directory)/\(name)", withExtension: nil) {
                return url
            }
            if let url = bundle.url(forResource: "\(directory)/\(name)", withExtension: "png") {
                return url
            }
        }
        return nil
    }

    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        // Спрайт-лист 512×512 — около мегабайта в памяти; сорока хватает
        // на экран витрины, а память не растёт до размера каталога.
        c.countLimit = 40
        return c
    }()

    private static let frameCache: NSCache<NSString, NSArray> = {
        let c = NSCache<NSString, NSArray>()
        // 16 кадров — заметно меньше листа, но держим меньше элементов.
        c.countLimit = 24
        return c
    }()
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
/// Кадр выбирается по времени: каждый кадр листа — отдельная картинка,
/// полученная обрезкой `CGImage`. `TimelineView` считает кадры только пока
/// экран виден; при выключенных анимациях в настройках картинка замирает на
/// среднем кадре и не крутится вхолостую.
struct GiftAnimationView: View {
    let assetId: String
    var size: CGFloat = 96
    var duration: Double = 3
    var animated: Bool = true
    var fallbackEmoji: String = "🎁"

    @State private var startedAt = Date()

    var body: some View {
        Group {
            if let frames = GiftArt.animationFrames(assetId), frames.count > 0 {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        frame(frames, at: context.date)
                    }
                } else {
                    // Середина анимации — самый выразительный кадр.
                    frame(frames, index: frames.count / 2)
                }
            } else if let preview = GiftArt.preview(assetId) {
                Image(uiImage: preview)
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

    private func frame(_ frames: [UIImage], at date: Date) -> some View {
        let elapsed = date.timeIntervalSince(startedAt)
        let progress = duration > 0 ? elapsed.truncatingRemainder(dividingBy: duration) / duration : 0
        let clamped = min(max(progress, 0), 1)
        let index = min(frames.count - 1, Int(clamped * Double(frames.count)))
        return frame(frames, index: index)
    }

    private func frame(_ frames: [UIImage], index: Int) -> some View {
        Image(uiImage: frames[index])
            .resizable()
            .interpolation(.high)
            .scaledToFit()
    }
}

/// Карточка подарка в витрине: настоящая анимация на градиенте цвета
/// подарка, честная пометка «распродано» из данных Telegram, цена и тираж.
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

                if gift.soldOutInTelegram {
                    Text("распродано")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.62)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
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
                        .font(.system(size: 12, weight: .medium))
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