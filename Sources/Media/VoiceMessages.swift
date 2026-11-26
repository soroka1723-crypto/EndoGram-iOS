import Foundation
import AVFoundation
import Combine

// MARK: - Хранилище

/// Файлы голосовых сообщений лежат в песочнице приложения, рядом с базой.
/// Никуда не отправляются: сеть приложением не используется.
enum VoiceStorage {

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Voice", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func makeFileName() -> String {
        "voice-" + UUID().uuidString + ".m4a"
    }

    static func remove(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}

// MARK: - Запись

/// Запись голосового сообщения через `AVAudioRecorder` с измерением уровня.
/// Полностью локально: разрешение микрофона и файл в песочнице.
final class VoiceRecorder: NSObject, ObservableObject {

    /// Как в Telegram — голосовое ограничено одной минутой.
    static let maxDuration: TimeInterval = 60

    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var levels: [Double] = []
    @Published var error: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileName: String?

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func start() {
        guard !isRecording else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            self.error = "Не удалось включить микрофон: \(error.localizedDescription)"
            return
        }

        let name = VoiceStorage.makeFileName()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: VoiceStorage.url(for: name), settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            self.recorder = recorder
            self.fileName = name
            self.elapsed = 0
            self.levels = []
            self.isRecording = true
            startTimer()
        } catch {
            self.error = "Не удалось начать запись: \(error.localizedDescription)"
        }
    }

    /// Останавливает запись и удаляет файл.
    func cancel() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        if let fileName { VoiceStorage.remove(fileName) }
        fileName = nil
        isRecording = false
        elapsed = 0
        levels = []
    }

    /// Останавливает запись и возвращает готовое голосовое сообщение.
    func finish() -> (fileName: String, duration: TimeInterval, waveform: [Double])? {
        guard isRecording, let fileName else { return nil }
        timer?.invalidate()
        timer = nil
        let duration = recorder?.currentTime ?? elapsed
        recorder?.stop()
        recorder = nil
        isRecording = false
        guard duration >= 0.7 else {
            VoiceStorage.remove(fileName)
            self.fileName = nil
            error = "Слишком короткая запись"
            return nil
        }
        let waveform = Self.normalized(levels)
        self.fileName = nil
        return (fileName, duration, waveform)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            let power = Double(recorder.averagePower(forChannel: 0))
            // −60 дБ … 0 дБ → 0 … 1, как полоски громкости в Telegram.
            let level = max(0, min(1, (power + 60) / 60))
            self.elapsed = recorder.currentTime
            self.levels.append(level)
            if recorder.currentTime >= Self.maxDuration {
                NotificationCenter.default.post(name: .endoGramVoiceLimitReached, object: nil)
            }
        }
    }

    /// Сжимает измерения в 40 полосок — столько рисует Telegram в пузыре.
    static func normalized(_ levels: [Double], bars: Int = 40) -> [Double] {
        guard !levels.isEmpty else { return Array(repeating: 0.35, count: bars) }
        let chunk = max(1, levels.count / bars)
        var result: [Double] = []
        var index = 0
        while index < levels.count && result.count < bars {
            let slice = levels[index..<min(index + chunk, levels.count)]
            result.append(slice.reduce(0, +) / Double(slice.count))
            index += chunk
        }
        while result.count < bars { result.append(result.last ?? 0.35) }
        return result.map { max(0.12, min(1, $0)) }
    }
}

extension Notification.Name {
    static let endoGramVoiceLimitReached = Notification.Name("endogram.voice.limit")
}

// MARK: - Воспроизведение

/// Воспроизведение голосовых сообщений. Один активный проигрыватель на приложение.
final class VoicePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published private(set) var playingFileName: String?
    @Published private(set) var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func toggle(fileName: String) {
        if playingFileName == fileName {
            stop()
        } else {
            play(fileName)
        }
    }

    func play(_ fileName: String) {
        stop()
        let url = VoiceStorage.url(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.player = player
            playingFileName = fileName
            progress = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self, let player = self.player else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
        } catch {
            stop()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        playingFileName = nil
        progress = 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}

// MARK: - Формат

extension Format {
    /// Длительность голосового в формате Telegram: 0:07.
    static func voiceDuration(_ seconds: Double?) -> String {
        let total = Int((seconds ?? 0).rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
