import SwiftUI

@main
struct EndoGramApp: App {
    @StateObject private var environment = AppEnvironment()
    @State private var isReady = false

    init() {
        // Единый «хром» Telegram: блюр навбаров, разделители, цвета таббара.
        Chrome.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    RootView()
                        .environmentObject(environment)
                        .transition(.opacity)
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                // Аккаунт создаётся автоматически при первом запуске:
                // никаких экранов входа, номеров и кодов подтверждения.
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(.easeOut(duration: 0.35)) { isReady = true }
            }
        }
    }
}

/// Заставка: показывает, что аккаунт уже создан и данные читаются с устройства.
struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 62))
                    .foregroundColor(Theme.accentBright)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                Text(AppConfig.appName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("Локальный аккаунт готовится…")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .onAppear { pulse = true }
    }
}
