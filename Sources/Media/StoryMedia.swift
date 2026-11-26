import Foundation
import UIKit
import AVFoundation
import AVKit
import SwiftUI
import UniformTypeIdentifiers

/// Хранилище медиа для историй: фото и видео лежат в песочнице приложения.
///
/// Никакой загрузки в сеть: файл остаётся на устройстве, как и остальные данные
/// EndoGram. Поэтому «опубликовать» историю с фото — значит скопировать файл
/// в `Application Support/StoryMedia`.
enum StoryMediaStorage {

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base.appendingPathComponent("EndoGram", isDirectory: true)
            .appendingPathComponent("StoryMedia", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    // MARK: - Запись

    /// Сохраняет фото как JPEG. Возвращает имя файла или nil при ошибке.
    static func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let fileName = "\(IDs.next("story"))".replacingOccurrences(of: "/", with: "-") + ".jpg"
        do {
            try data.write(to: url(for: fileName), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    /// Копирует видео из временного файла камеры/галереи в песочницу историй.
    static func saveVideo(from source: URL) -> String? {
        let fileName = "\(IDs.next("story"))".replacingOccurrences(of: "/", with: "-") + ".mov"
        let destination = url(for: fileName)
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return fileName
        } catch {
            return nil
        }
    }

    /// Кладёт произвольные данные (видео из галереи) в файл истории.
    static func saveVideoData(_ data: Data) -> String? {
        let fileName = "\(IDs.next("story"))".replacingOccurrences(of: "/", with: "-") + ".mov"
        do {
            try data.write(to: url(for: fileName), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    // MARK: - Чтение

    static func image(for fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    /// Кадр-обложка для видео: генерируется один раз и кэшируется рядом.
    static func thumbnail(forVideo fileName: String) -> UIImage? {
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

    static func duration(ofVideo fileName: String) -> Double {
        let asset = AVURLAsset(url: url(for: fileName))
        let seconds = CMTimeGetSeconds(asset.duration)
        return seconds.isFinite && seconds > 0 ? seconds : 0
    }

    // MARK: - Удаление

    static func delete(fileName: String) {
        let base = url(for: fileName)
        try? FileManager.default.removeItem(at: base)
        let thumb = base.deletingPathExtension().appendingPathExtension("thumb.jpg")
        try? FileManager.default.removeItem(at: thumb)
    }

    // MARK: - Размер

    static func totalBytes() -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        return files.reduce(0) { partial, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return partial + size
        }
    }
}

/// Что именно сняли в камере.
enum StoryCapture {
    case photo(UIImage)
    case video(URL)
}

/// Камера для историй: фото или видео, как `UIImagePickerController` в Telegram.
///
/// На симуляторе камеры нет — экран честно об этом скажет вместо пустой картинки.
struct StoryCameraPicker: UIViewControllerRepresentable {
    enum Mode {
        case photo
        case video
    }

    let mode: Mode
    let onCapture: (StoryCapture?) -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = StoryCameraPicker.isAvailable ? .camera : .photoLibrary
        controller.delegate = context.coordinator
        switch mode {
        case .photo:
            controller.mediaTypes = [UTType.image.identifier]
            controller.cameraCaptureMode = .photo
        case .video:
            controller.mediaTypes = [UTType.movie.identifier]
            controller.cameraCaptureMode = .video
            controller.videoQuality = .typeHigh
            controller.videoMaximumDuration = 60
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, mode: mode)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (StoryCapture?) -> Void
        private let mode: Mode

        init(onCapture: @escaping (StoryCapture?) -> Void, mode: Mode) {
            self.onCapture = onCapture
            self.mode = mode
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let url = info[.mediaURL] as? URL {
                onCapture(.video(url))
                return
            }
            if let image = info[.originalImage] as? UIImage {
                onCapture(.photo(image))
                return
            }
            onCapture(nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
        }
    }
}

/// Полноэкранное проигрывание видео истории.
struct StoryVideoPlayer: View {
    let fileName: String
    /// Вызывается, когда видео доиграло до конца.
    var onFinished: () -> Void = {}

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                Color.black
            }
        }
        .onAppear {
            let item = AVPlayerItem(url: StoryMediaStorage.url(for: fileName))
            let created = AVPlayer(playerItem: item)
            player = created
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                onFinished()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}