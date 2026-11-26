import SwiftUI
import UIKit

/// Корневая навигация — как в Telegram для iOS: четыре вкладки.
///
/// Названия взяты из строк официального клиента:
/// `Contacts.TabTitle`, `Calls.TabTitle`, `DialogList.TabTitle`, `Settings.Title`.
/// Звёзды в Telegram не отдельная вкладка — они открываются из настроек,
/// поэтому здесь их тоже нет.
struct RootView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var tab: Tab = .chats

    enum Tab: Hashable {
        case contacts, calls, chats, settings
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

            NavigationStack { SettingsView() }
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}