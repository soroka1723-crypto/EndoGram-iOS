import SwiftUI

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
                if story.caption.isEmpty {
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

    private let duration: Double = 5

    private var current: Story? {
        stories.indices.contains(index) ? stories[index] : nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let story = current {
                LinearGradient(
                    colors: [Color(hex: story.colorHex),
                             Color(hex: story.colorHex).opacity(0.45),
                             .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

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
                Text("\(story.views) просмотров · локально")
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
                step(1)
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

/// Публикация локальной истории: подпись и цвет обложки.
struct NewStorySheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var caption = ""

    private let colors = ["#368AD1", "#955CDB", "#CC5049", "#40A920", "#D67722", "#C7508B", "#309EBA"]
    @State private var color = "#368AD1"

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: color), Color(hex: color).opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 210)
                            Text(caption.isEmpty ? "Ваша история" : caption)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(24)
                        }
                        .listRowBackground(Theme.background)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }

                    Section {
                        TextField("Подпись", text: $caption, axis: .vertical)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(3...6)
                    } header: {
                        Text("Текст")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(nil)
                    }
                    .listRowBackground(Theme.panel)

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
                        Text("Картинки не добавляются: истории хранятся на устройстве, а загружать файлы некуда. История живёт 24 часа и потом уходит в архив.")
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
                    Button("Опубликовать") {
                        env.addStory(caption: caption, colorHex: color)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .toolbarBackground(Theme.rootNavigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
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
                                        Text("\(story.views) просмотров · осталось \(story.hoursLeft) ч")
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
                            Text("Архив пуст")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Сюда попадают истории после 24 часов.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
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
                                        Text("\(story.views) просмотров · \(Format.fullDate(story.createdAt))")
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
