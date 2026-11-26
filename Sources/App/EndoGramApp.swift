import SwiftUI

@main
struct EndoGramApp: App {
    @StateObject private var environment = AppEnvironment()
    @State private var isReady = false

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
                // РђРєРєР°СѓРЅС‚ СЃРѕР·РґР°С‘С‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РїСЂРё РїРµСЂРІРѕРј Р·Р°РїСѓСЃРєРµ:
                // РЅРёРєР°РєРёС… СЌРєСЂР°РЅРѕРІ РІС…РѕРґР°, РЅРѕРјРµСЂРѕРІ Рё РєРѕРґРѕРІ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ.
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(.easeOut(duration: 0.35)) { isReady = true }
            }
        }
    }
}

/// Р—Р°СЃС‚Р°РІРєР°: РїРѕРєР°Р·С‹РІР°РµС‚, С‡С‚Рѕ Р°РєРєР°СѓРЅС‚ СѓР¶Рµ СЃРѕР·РґР°РЅ Рё РґР°РЅРЅС‹Рµ С‡РёС‚Р°СЋС‚СЃСЏ СЃ СѓСЃС‚СЂРѕР№СЃС‚РІР°.
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
                Text("Р›РѕРєР°Р»СЊРЅС‹Р№ Р°РєРєР°СѓРЅС‚ РіРѕС‚РѕРІРёС‚СЃСЏвЂ¦")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .onAppear { pulse = true }
    }
}

