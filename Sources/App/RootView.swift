import SwiftUI
import UIKit

/// Корневая навигация: вкладки как в Telegram.
struct RootView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var tab: Tab = .chats

    enum Tab: Hashable {
        case contacts, calls, chats, stars, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { ContactsView() }
                .tabItem { Label("Контакты", systemImage: "person.2.fill") }
                .tag(Tab.contacts)

            NavigationStack { CallsView() }
                .tabItem { Label("Звонки", systemImage: "phone.fill") }
                .tag(Tab.calls)

            NavigationStack { ChatsListView() }
                .tabItem { Label("Чаты", systemImage: "message.fill") }
                .badge(env.totalUnread > 0 ? env.totalUnread : 0)
                .tag(Tab.chats)

            NavigationStack { StarsView() }
                .tabItem { Label("Звёзды", systemImage: "star.fill") }
                .tag(Tab.stars)

            NavigationStack { SettingsView() }
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accentBright)
        .onAppear(perform: styleTabBar)
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.panel
        appearance.shadowColor = Theme.divider
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
