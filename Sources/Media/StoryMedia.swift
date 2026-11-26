import Foundation
import UIKit
import AVFoundation
import AVKit
import SwiftUI
import UniformTypeIdentifiers

/// Хранилище медиа для историй — тонкая обёртка над `MediaStore`.
///
/// Никакой загрузки в сеть: файл остаётся на устройстве, как и остальные данные
/// EndoGram. Поэтому «опубликовать» историю с фото — значит скопировать файл
/// в `Application Support/EndoGram/StoryMedia`.
enum StoryMediaStorage {

    static let store = MediaStore(folder: "StoryMedia")

    static var directory: URL { store.directory }

    static func url(for fileName: String) -> URL { store.url(for: fileName) }

    static func saveImage(_ image: UIImage) -> String? { store.saveImage(image) }

    static func saveVideo(from source: URL) -> String? { store.saveVideo(from: source) }

    static func saveVideoData(_ data: Data) -> String? { store.saveVideoData(data) }

    static func image(for fileName: String) -> UIImage? { store.image(for: fileName) }

    static func thumbnail(forVideo fileName: String) -> UIImage? { store.thumbnail(forVideo: fileName) }

    static func duration(ofVideo fileName: String) -> Double { store.duration(ofVideo: fileName) }

    static func delete(fileName: String) { store.delete(fileName: fileName) }

    static func totalBytes() -> Int { store.totalBytes() }
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