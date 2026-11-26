import SwiftUI
import PhotosUI
import UIKit

// MARK: - Полоса историй над списком чатов

/// Строка историй над списком чатов — как `StoriesStrip` в Telegram.
struct StoriesStrip: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showComposer = false
    @State private var viewing: Story?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                myStoryTile

                ForEach(env.activeStories) { story in
                    Button {
                        viewing = story
                        env.markStoryViewed(id: story.id)
                    } label: {
                        StoryCircle(story: story, isOwn: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .overlay(alignment: .bottom) {
            DividerLine(inset: 0)
        }
        .sheet(isPresented: $showComposer) {
            NewStorySheet().environmentObject(env)
        }
        .fullScreenCover(item: $viewing) { story in
            StoryViewer(stories: env.activeStories, startAt: story)
                .environmentObject(env)
        }
    }

    private var myStoryTile: some View {
        Button {
            showComposer = true
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .stroke(Theme.accent, lineWidth: 2)
                        .frame(width: 58, height: 58)
                        .overlay(
                            AvatarView(title: env.profile.displayName,
                                       colorHex: env.profile.avatarColor, size: 50)
                        )
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 19))
                        .foregroundColor(Theme.accent)
                        .background(Circle().fill(Theme.background).padding(1.5))
                }
                Text("Моя история")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 74)
        }
        .buttonStyle(.plain)
    }
}

/// Кружок истории в полосе.
struct StoryCircle: View {
    let story: Story
    var isOwn: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: story.colorHex),
                                     Color(hex: story.colorHex).opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(Circle().stroke(Theme.accent, lineWidth: 2))

                if let fileName = story.mediaFileName, let image = storyMediaImage(fileName: fileName, isVideo: story.isVideo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Theme.accent, lineWidth: 2)
                        )
                        .overlay {
                            if story.isVideo {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(radius: 3)
                            }
                        }
                } else if story.caption.isEmpty {
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text(story.caption.prefix(2))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            Text(story.caption.isEmpty ? "История" : story.caption)
                .font(.system(size: 11))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .frame(width: 74)
        }
    }

    /// Кэш обложек: генерировать кадр видео на каждую перерисовку слишком дорого.
    private func storyMediaImage(fileName: String, isVideo: Bool) -> UIImage? {
        if isVideo { return StoryMediaStorage.thumbnail(forVideo: fileName) }
        return StoryMediaStorage.image(for: fileName)
    }
}

// MARK: - Просмотрщик

/// Полноэкранный просмотр историй: полоски прогресса, тап влево/вправо,
/// подпись, счётчик просмотров — как `StoryContainer` в Telegram.
struct StoryViewer: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let stories: [Story]
    let startAt: Story

    @State private var index = 0
    @State private var progress: Double = 0
    @State private var confirmDelete = false
    @State private var paused = false

    /// Фото показывается 5 секунд, видео — сколько длится сам файл.
    private var duration: Double {
        guard let story = current else { return 5 }
        if story.isVideo {
            let videoDuration = story.mediaDuration ?? 0
            return max(2, videoDuration)
        }
        return 5
    }

    private var current: Story? {
        stories.indices.contains(index) ? stories[index] : nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let story = current {
                if story.isVideo, let fileName = story.mediaFileName {
                    StoryVideoPlayer(fileName: fileName) {
                        step(1)
                    }
                    .ignoresSafeArea()
                } else if let fileName = story.mediaFileName,
                          let image = StoryMediaStorage.image(for: fileName) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(hex: story.colorHex),
                                 Color(hex: story.colorHex).opacity(0.45),
                                 .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }

                VStack {
                    progressBars
                    header(story)
                    Spacer()
                    captionBlock(story)
                }
                .padding(.horizontal, 14)

                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { step(-1) }
                        .onLongPressGesture(minimumDuration: 0.2) { paused = true } onPressingChanged: { pressing in
                            if !pressing { paused = false }
                        }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { step(1) }
                        .onLongPressGesture(minimumDuration: 0.2) { paused = true } onPressingChanged: { pressing in
                            if !pressing { paused = false }
                        }
                }
                .ignoresSafeArea()
            }
        }
        .statusBarHidden()
        .onAppear {
            index = stories.firstIndex(where: { $0.id == startAt.id }) ?? 0
            progress = 0
            startTimer()
        }
        .onDisappear { timer?.invalidate() }
        .alert("Удалить историю?", isPresented: $confirmDelete) {
            Button("Удалить", role: .destructive) {
                if let story = current { env.deleteStory(id: story.id) }
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("История удалится только с этого устройства.")
        }
    }

    @State private var timer: Timer?

    private var progressBars: some View {
        HStack(spacing: 3) {
            ForEach(Array(stories.enumerated()), id: \.element.id) { i, _ in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.28))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * fill(for: i))
                    }
                }
                .frame(height: 2.5)
            }
        }
        .padding(.top, 10)
    }

    private func fill(for i: Int) -> Double {
        if i < index { return 1 }
        if i > index { return 0 }
        return progress
    }

    private func header(_ story: Story) -> some View {
        HStack(spacing: 10) {
            AvatarView(title: env.profile.displayName, colorHex: env.profile.avatarColor, size: 34)
            VStack(alignment: .leading, spacing: 0) {
                Text(story.authorName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(relativeTime(story.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            Menu {
                Button {
                    env.setStoryArchived(id: story.id, archived: true)
                    dismiss()
                } label: { Label("В архив", systemImage: "archivebox") }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: { Label("Удалить", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 12)
    }

    private func captionBlock(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !story.caption.isEmpty {
                Text(story.caption)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 6) {
                Image(systemName: "eye.fill").font(.system(size: 12))
                Text("\(Format.views(story.views)) · \(story.privacyOption.title)")
                    .font(.system(size: 12))
            }
            .foregroundColor(.white.opacity(0.8))

            Text("Осталось \(story.hoursLeft) ч до архива")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.42))
        )
        .padding(.bottom, 28)
    }

    private func step(_ delta: Int) {
        let next = index + delta
        if next < 0 {
            progress = 0
            startTimer()
            return
        }
        if next >= stories.count {
            dismiss()
            return
        }
        index = next
        progress = 0
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        let tick = 0.05
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { _ in
            guard !paused else { return }
            if progress >= 1 {
                // Для видео переход делает сам плеер: иначе шаг сработал бы дважды.
                if current?.isVideo != true { step(1) }
            } else {
                progress = min(1, progress + tick / duration)
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 1 { return "только что" }
        if minutes < 60 { return "\(minutes) мин назад" }
        let hours = minutes / 60
        return "\(hours) ч назад"
    }
}

// MARK: - Создание истории
// MARK: - Создание истории

/// Публикация локальной истории: фото, видео или цветная обложка с подписью.
///
/// Съёмка идёт через системную камеру (`UIImagePickerController`), выбор из
/// галереи — через `PhotosPicker`. Файл копируется в песочницу приложения и
/// никуда не отправляется: истории в EndoGram локальные.
struct NewStorySheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var caption = ""
    @State private var color = "#368AD1"
    @State private var privacy: StoryPrivacy = .everyone

    /// Выбранное или снятое медиа.
    @State private var pickedImage: UIImage?
    @State private var pickedVideoURL: URL?
    @State private var pickedVideoThumb: UIImage?
    @State private var pickedVideoDuration: Double = 0

    @State private var showCameraPhoto = false
    @State private var showCameraVideo = false
    @State private var showLibrary = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var loadingLibrary = false
    @State private var errorText: String?

    private let colors = ["#368AD1", "#955CDB", "#CC5049", "#40A920", "#D67722", "#C7508B", "#309EBA"]

    private var hasMedia: Bool { pickedImage != nil || pickedVideoURL != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        preview
                            .listRowBackground(Theme.background)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }

                    Section {
                        Button {
                            guard StoryCameraPicker.isAvailable else {
                                errorText = "Камера недоступна на этом устройстве. На симуляторе её нет — попробуйте на iPhone."
                                return
                            }
                            showCameraPhoto = true
                        } label: {
                            mediaRow(icon: "camera.fill", title: "Снять фото", tint: Theme.accent)
                        }
                        .buttonStyle(.plain)

                        Button {
                            guard StoryCameraPicker.isAvailable else {
                                errorText = "Камера недоступна на этом устройстве. На симуляторе её нет — попробуйте на iPhone."
                                return
                            }
                            showCameraVideo = true
                        } label: {
                            mediaRow(icon: "video.fill", title: "Снять видео", tint: Theme.danger)
                        }
                        .buttonStyle(.plain)

                        PhotosPicker(selection: $libraryItem, matching: .any(of: [.images, .videos])) {
                            mediaRow(icon: "photo.on.rectangle.angled", title: "Из галереи", tint: Theme.success)
                        }
                        .buttonStyle(.plain)

                        if hasMedia {
                            Button(role: .destructive) {
                                pickedImage = nil
                                pickedVideoURL = nil
                                pickedVideoThumb = nil
                                pickedVideoDuration = 0
                            } label: {
                                mediaRow(icon: "xmark.circle.fill", title: "Убрать медиа", tint: Theme.neutral)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Медиа")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    } footer: {
                        if loadingLibrary {
                            Text("Загружаю файл из галереи...")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                        } else {
                            Text("Фото и видео копируются в песочницу приложения и остаются на устройстве. Никакой загрузки в сеть: истории в EndoGram локальные. Видео — до 60 секунд.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .listRowBackground(Theme.panel)

                    Section {
                        TextField("Добавить подпись...", text: $caption, axis: .vertical)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(3...6)
                    } header: {
                        Text("Текст")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    }
                    .listRowBackground(Theme.panel)

                    if !hasMedia {
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(colors, id: \.self) { hex in
                                        Button {
                                            color = hex
                                        } label: {
                                            ZStack {
                                                Circle().fill(Color(hex: hex)).frame(width: 36, height: 36)
                                                if color == hex {
                                                    Circle().stroke(Theme.textPrimary, lineWidth: 2.5)
                                                        .frame(width: 42, height: 42)
                                                }
                                            }
                                            .frame(width: 44, height: 44)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            Text("Цвет обложки")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                                .textCase(nil)
                        } footer: {
                            Text("Цвет нужен, когда истории нет фото или видео.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .listRowBackground(Theme.panel)
                    }

                    Section {
                        SettingsPickerRow(
                            icon: "eye.fill",
                            title: "Кто видит",
                            options: StoryPrivacy.allCases.map { ($0.rawValue, $0.title) },
                            selection: Binding(
                                get: { privacy.rawValue },
                                set: { privacy = StoryPrivacy(rawValue: $0) ?? .everyone }
                            ),
                            tint: Theme.accent
                        )
                    } header: {
                        Text("Приватность")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    } footer: {
                        Text(privacy.hint + " В офлайн-режиме историю всё равно видите только вы — рядом нет других людей.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Новая история")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }.tint(Theme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Опубликовать") { publish() }
                        .font(.system(size: 16, weight: .semibold))
                        .disabled(loadingLibrary)
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showCameraPhoto) {
            StoryCameraPicker(mode: .photo) { capture in
                showCameraPhoto = false
                apply(capture)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCameraVideo) {
            StoryCameraPicker(mode: .video) { capture in
                showCameraVideo = false
                apply(capture)
            }
            .ignoresSafeArea()
        }
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            loadLibraryItem(item)
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

    // MARK: - Превью

    @ViewBuilder
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: color), Color(hex: color).opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 250)

            if let pickedImage {
                Image(uiImage: pickedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if let pickedVideoThumb {
                Image(uiImage: pickedVideoThumb)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 54))
                            .foregroundColor(.white.opacity(0.92))
                            .shadow(radius: 8)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if pickedVideoDuration > 0 {
                            Text(Format.duration(pickedVideoDuration))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.black.opacity(0.55)))
                                .padding(10)
                        }
                    }
            }

            if !hasMedia {
                Text(caption.isEmpty ? "Ваша история" : caption)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(24)
            }
        }
    }

    private func mediaRow(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint))
            Text(title).foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .contentShape(Rectangle())
    }

    // MARK: - Медиа

    private func apply(_ capture: StoryCapture?) {
        guard let capture else { return }
        switch capture {
        case .photo(let image):
            pickedImage = image
            pickedVideoURL = nil
            pickedVideoThumb = nil
            pickedVideoDuration = 0
        case .video(let url):
            // Файл камеры живёт во временной папке — сразу переносим в историю.
            guard let stored = StoryMediaStorage.saveVideo(from: url) else {
                errorText = "Не удалось сохранить видео на устройство."
                return
            }
            pickedVideoURL = StoryMediaStorage.url(for: stored)
            pickedImage = nil
            pickedVideoThumb = StoryMediaStorage.thumbnail(forVideo: stored)
            pickedVideoDuration = StoryMediaStorage.duration(ofVideo: stored)
        }
    }

    private func loadLibraryItem(_ item: PhotosPickerItem) {
        loadingLibrary = true
        Task {
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            if isVideo {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let stored = StoryMediaStorage.saveVideoData(data) {
                    await MainActor.run {
                        pickedVideoURL = StoryMediaStorage.url(for: stored)
                        pickedVideoThumb = StoryMediaStorage.thumbnail(forVideo: stored)
                        pickedVideoDuration = StoryMediaStorage.duration(ofVideo: stored)
                        pickedImage = nil
                        loadingLibrary = false
                    }
                    return
                }
            } else if let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) {
                await MainActor.run {
                    pickedImage = image
                    pickedVideoURL = nil
                    pickedVideoThumb = nil
                    pickedVideoDuration = 0
                    loadingLibrary = false
                }
                return
            }
            await MainActor.run {
                errorText = "Не удалось прочитать файл из галереи."
                loadingLibrary = false
            }
        }
    }

    private func publish() {
        var fileName: String?
        var kind: String?
        var duration: Double?

        if let pickedImage, let saved = StoryMediaStorage.saveImage(pickedImage) {
            fileName = saved
            kind = "photo"
        } else if let pickedVideoURL {
            // Видео уже лежит в папке историй — передаём его имя как есть.
            fileName = pickedVideoURL.lastPathComponent
            kind = "video"
            duration = pickedVideoDuration
        }

        env.addStory(caption: caption, colorHex: color, privacy: privacy.rawValue,
                     mediaFileName: fileName, mediaKind: kind, mediaDuration: duration)
        dismiss()
    }
}

// MARK: - Мои истории

/// «Мои истории» — раздел оригинала `Settings_MyStories`.
struct MyStoriesView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var showComposer = false
    @State private var viewing: Story?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    Button {
                        showComposer = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Theme.accent)
                            Text("Добавить историю")
                                .foregroundColor(Theme.accent)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.panel)
                }

                if env.activeStories.isEmpty {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "circle.dashed")
                                .font(.system(size: 42))
                                .foregroundColor(Theme.textSecondary)
                            Text("Активных историй нет")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("История живёт 24 часа, потом уходит в архив.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .listRowBackground(Theme.panel)
                } else {
                    Section {
                        ForEach(env.activeStories) { story in
                            Button {
                                viewing = story
                                env.markStoryViewed(id: story.id)
                            } label: {
                                HStack(spacing: 12) {
                                    StoryCircle(story: story)
                                        .scaleEffect(0.72)
                                        .frame(width: 46, height: 46)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(story.caption.isEmpty ? "История без подписи" : story.caption)
                                            .foregroundColor(Theme.textPrimary)
                                            .lineLimit(1)
                                        Text("\(Format.views(story.views)) · осталось \(story.hoursLeft) ч")
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.panel)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    env.deleteStory(id: story.id)
                                } label: { Label("Удалить", systemImage: "trash") }
                                Button {
                                    env.setStoryArchived(id: story.id, archived: true)
                                } label: { Label("В архив", systemImage: "archivebox") }
                                .tint(Theme.neutral)
                            }
                        }
                    } header: {
                        Text("Активные")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    }
                    .listRowBackground(Theme.panel)
                }

                Section {
                    NavigationLink(value: SettingsView.Route.storiesArchive) {
                        SettingsRow(icon: "archivebox.fill", title: "Архив историй",
                                    value: "\(env.archivedStories.count)", tint: Theme.neutral)
                    }
                    .listRowBackground(Theme.panel)
                } footer: {
                    Text("Истории локальные: их никто, кроме вас, не видит — сервера и других людей здесь нет. Счётчик просмотров растёт, когда вы открываете историю сами.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .telegramList()
        }
        .telegramNavTitle("Мои истории")
        .sheet(isPresented: $showComposer) {
            NewStorySheet().environmentObject(env)
        }
        .fullScreenCover(item: $viewing) { story in
            StoryViewer(stories: env.activeStories, startAt: story)
                .environmentObject(env)
        }
    }
}

// MARK: - Архив историй

/// «Архив историй» — раздел оригинала `Settings_StoriesArchive`.
struct StoriesArchiveView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var viewing: Story?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                if env.archivedStories.isEmpty {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.textSecondary)
                            Text("Архивных историй нет")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Опубликуйте новую историю, чтобы она появилась здесь.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .listRowBackground(Theme.panel)

                    Section {
                        Text("Архивные истории видите только вы, пока не решите вернуть их в активные. Так же устроен `StoryList.ArchiveDescription` в Telegram.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                } else {
                    Section {
                        ForEach(env.archivedStories) { story in
                            Button {
                                viewing = story
                            } label: {
                                HStack(spacing: 12) {
                                    StoryCircle(story: story)
                                        .scaleEffect(0.72)
                                        .frame(width: 46, height: 46)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(story.caption.isEmpty ? "История без подписи" : story.caption)
                                            .foregroundColor(Theme.textPrimary)
                                            .lineLimit(1)
                                        Text("\(Format.views(story.views)) · \(Format.fullDate(story.createdAt))")
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.panel)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    env.deleteStory(id: story.id)
                                } label: { Label("Удалить", systemImage: "trash") }
                                Button {
                                    env.setStoryArchived(id: story.id, archived: false)
                                } label: { Label("Вернуть", systemImage: "arrow.uturn.left") }
                                .tint(Theme.accent)
                            }
                        }
                    } footer: {
                        Text("Архив хранится на устройстве. «Вернуть» снова делает историю активной.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.panel)
                }
            }
            .telegramList()
        }
        .telegramNavTitle("Архив историй")
        .fullScreenCover(item: $viewing) { story in
            StoryViewer(stories: env.archivedStories, startAt: story)
                .environmentObject(env)
        }
    }
}