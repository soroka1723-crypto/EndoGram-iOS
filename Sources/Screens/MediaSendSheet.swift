import SwiftUI
import UIKit
import AVKit
import PhotosUI

/// Вложение, которое пользователь выбрал, но ещё не отправил.
struct PendingAttachment: Identifiable {
    let id = UUID()
    let image: UIImage?
    let videoFileName: String?
    let videoDuration: Double

    var isVideo: Bool { videoFileName != nil }
}

/// Экран отправки фото или видео с подписью — как редактор вложения в Telegram.
///
/// Ничего не загружает: файл уже скопирован в `ChatMedia`, при отправке в чат
/// создаётся запись с этим именем файла. Работает и для каналов.
struct MediaSendSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let chatId: String
    let attachment: PendingAttachment

    @State private var caption = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    preview
                        .padding(.horizontal, 12)
                        .padding(.top, 10)

                    HStack(spacing: 10) {
                        TextField("Добавить подпись...", text: $caption, axis: .vertical)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1...4)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Theme.inputField)
                            )
                        Button(action: send) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(Theme.accent))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.inputPanel)

                    Text("Файл останется в песочнице приложения и будет доступен только на этом устройстве.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle(attachment.isVideo ? "Видео" : "Фото")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }.tint(Theme.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.panel)

            if let image = attachment.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if let fileName = attachment.videoFileName,
                      let thumb = ChatMedia.store.thumbnail(forVideo: fileName) {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.92))
                            .shadow(radius: 8)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if attachment.videoDuration > 0 {
                            Text(Format.duration(attachment.videoDuration))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.black.opacity(0.55)))
                                .padding(10)
                        }
                    }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.textSecondary)
                    .frame(height: 220)
            }
        }
        .frame(maxHeight: 360)
    }

    private func send() {
        guard !sent else { return }
        sent = true
        if let image = attachment.image, let fileName = ChatMedia.store.saveImage(image) {
            env.sendMediaMessage(chatId: chatId, fileName: fileName, kind: .photo,
                                 caption: caption, replyToId: nil)
        } else if let fileName = attachment.videoFileName {
            env.sendMediaMessage(chatId: chatId, fileName: fileName, kind: .video,
                                 duration: attachment.videoDuration,
                                 caption: caption, replyToId: nil)
        }
        dismiss()
    }
}

/// Полноэкранный просмотр фото или видео из переписки.
struct MediaViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let message: Message

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if message.kind == .video, let fileName = message.mediaFileName {
                StoryVideoPlayer(fileName: fileName)
                    .ignoresSafeArea()
            } else if let fileName = message.mediaFileName,
                      let image = ChatMedia.store.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(4, max(1, lastScale * value))
                            }
                            .onEnded { _ in lastScale = scale }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = scale > 1 ? 1 : 2
                            lastScale = scale
                        }
                    }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 34))
                        .foregroundColor(Theme.textSecondary)
                    Text("Файл не найден на устройстве")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textPrimary)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                Spacer()
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding(.bottom, 26)
                }
            }
        }
        .statusBarHidden()
    }
}

/// Выбор фото или видео из галереи — общая логика для историй и чатов.
struct MediaLibraryPicker: View {
    @Environment(\.dismiss) private var dismiss
    /// `stories` кладёт файлы в папку историй, `chat` — в папку вложений.
    let store: MediaStore
    let onPicked: (PendingAttachment) -> Void

    @State private var item: PhotosPickerItem?
    @State private var loading = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    PhotosPicker(selection: $item, matching: .any(of: [.images, .videos])) {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 44))
                                .foregroundColor(Theme.accent)
                            Text("Выбрать из галереи")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 34)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.panel)
                        )
                    }
                    .padding(.horizontal, 16)

                    if loading {
                        ProgressView().tint(Theme.accent)
                    }

                    Text("Файл копируется в песочницу приложения. В сеть ничего не отправляется.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("Галерея")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }.tint(Theme.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            loading = true
            Task {
                let isVideo = picked.supportedContentTypes.contains { $0.conforms(to: .movie) }
                if isVideo {
                    if let data = try? await picked.loadTransferable(type: Data.self),
                       let fileName = store.saveVideoData(data) {
                        let duration = store.duration(ofVideo: fileName)
                        await MainActor.run {
                            loading = false
                            onPicked(PendingAttachment(image: nil, videoFileName: fileName,
                                                       videoDuration: duration))
                            dismiss()
                        }
                        return
                    }
                } else if let data = try? await picked.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) {
                    await MainActor.run {
                        loading = false
                        onPicked(PendingAttachment(image: image, videoFileName: nil, videoDuration: 0))
                        dismiss()
                    }
                    return
                }
                await MainActor.run {
                    loading = false
                    errorText = "Не удалось прочитать файл из галереи."
                }
            }
        }
        .alert("Не получилось", isPresented: Binding(
            get: { errorText != nil },
            set: { if !$0 { errorText = nil } }
        )) {
            Button("Понятно", role: .cancel) { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }
}