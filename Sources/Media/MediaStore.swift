import Foundation
import UIKit
import AVFoundation

/// Общее локальное хранилище медиафайлов приложения.
///
/// Один и тот же код обслуживает истории (`ChatMedia`/`StoryMedia`) и вложения
/// в чатах: файл всегда лежит в песочнице, в сеть ничего не уходит.
struct MediaStore {
    /// Имя папки внутри `Application Support/EndoGram`.
    let folder: String

    var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base.appendingPathComponent("EndoGram", isDirectory: true)
            .appendingPathComponent(folder, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    // MARK: - Запись

    /// Сохраняет фото как JPEG. Возвращает имя файла или nil при ошибке.
    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        return writeJPEG(data)
    }

    private func writeJPEG(_ data: Data) -> String? {
        let fileName = Self.makeName(extension: "jpg")
        do {
            try data.write(to: url(for: fileName), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    /// Копирует видео из временного файла камеры/галереи в песочницу.
    func saveVideo(from source: URL) -> String? {
        let fileName = Self.makeName(extension: "mov")
        let destination = url(for: fileName)
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return fileName
        } catch {
            return nil
        }
    }

    func saveVideoData(_ data: Data) -> String? {
        let fileName = Self.makeName(extension: "mov")
        do {
            try data.write(to: url(for: fileName), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    private static func makeName(extension ext: String) -> String {
        let token = IDs.next("media").replacingOccurrences(of: "/", with: "-")
        return "\(token).\(ext)"
    }

    // MARK: - Чтение

    func image(for fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    /// Кадр-обложка для видео: генерируется один раз и кэшируется рядом.
    func thumbnail(forVideo fileName: String) -> UIImage? {
        let cached = url(for: fileName).deletingPathExtension().appendingPathExtension("thumb.jpg")
        if let data = try? Data(contentsOf: cached), let image = UIImage(data: data) {
            return image
        }
        let asset = AVURLAsset(url: url(for: fileName))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)
        let time = CMTime(seconds: 0.2, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        let image = UIImage(cgImage: cgImage)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: cached, options: .atomic)
        }
        return image
    }

    func duration(ofVideo fileName: String) -> Double {
        let asset = AVURLAsset(url: url(for: fileName))
        let seconds = CMTimeGetSeconds(asset.duration)
        return seconds.isFinite && seconds > 0 ? seconds : 0
    }

    func fileSize(_ fileName: String) -> Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url(for: fileName).path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
    }

    // MARK: - Удаление

    func delete(fileName: String) {
        let base = url(for: fileName)
        try? FileManager.default.removeItem(at: base)
        let thumb = base.deletingPathExtension().appendingPathExtension("thumb.jpg")
        try? FileManager.default.removeItem(at: thumb)
    }

    // MARK: - Размер

    func totalBytes() -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        return files.reduce(0) { partial, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return partial + size
        }
    }
}

/// Медиа вложений в чатах и каналах.
enum ChatMedia {
    static let store = MediaStore(folder: "ChatMedia")

    /// Человекочитаемый размер вложения для строки сообщения.
    static func formattedSize(_ fileName: String) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(store.fileSize(fileName)))
    }
}