import SwiftUI

/// РџРѕРёСЃРє РїРѕ С‡Р°С‚Р°Рј, СЃРѕРѕР±С‰РµРЅРёСЏРј Рё РєРѕРЅС‚Р°РєС‚Р°Рј.
struct SearchView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedChat: Chat?

    private var chatHits: [Chat] {
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        return env.snapshot.chats.filter { $0.title.lowercased().contains(needle) }
    }

    private var messageHits: [Message] {
        guard query.count >= 2 else { return [] }
        let needle = query.lowercased()
        return env.snapshot.messages
            .filter { $0.text.lowercased().contains(needle) }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(40)
            .map { $0 }
    }

    private var contactHits: [UserProfile] {
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        return env.snapshot.contacts.filter {
            $0.displayName.lowercased().contains(needle) || $0.username.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.panel.ignoresSafeArea()
                if query.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: "РџРѕРёСЃРє", subtitle: "Р§Р°С‚С‹, СЃРѕРѕР±С‰РµРЅРёСЏ Рё РєРѕРЅС‚Р°РєС‚С‹ вЂ” РІСЃС‘ РёС‰РµС‚СЃСЏ Р»РѕРєР°Р»СЊРЅРѕ.")
                } else {
                    List {
                        if !chatHits.isEmpty {
                            Section("Р§Р°С‚С‹") {
                                ForEach(chatHits) { chat in
                                    Button { selectedChat = chat } label: {
                                        HStack(spacing: 12) {
                                            AvatarView(title: chat.title, colorHex: chat.avatarColor, size: 40)
                                            Text(chat.title).foregroundColor(Theme.textPrimary)
                                            Spacer()
                                        }
                                    }
                                    .listRowBackground(Theme.panel)
                                }
                            }
                        }
                        if !contactHits.isEmpty {
                            Section("РљРѕРЅС‚Р°РєС‚С‹") {
                                ForEach(contactHits) { contact in
                                    Button {
                                        selectedChat = env.openDirectChat(with: contact)
                                    } label: {
                                        HStack(spacing: 12) {
                                            AvatarView(title: contact.displayName, colorHex: contact.avatarColor, size: 40)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(contact.displayName).foregroundColor(Theme.textPrimary)
                                                Text("@" + contact.username).font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .listRowBackground(Theme.panel)
                                }
                            }
                        }
                        if !messageHits.isEmpty {
                            Section("РЎРѕРѕР±С‰РµРЅРёСЏ") {
                                ForEach(messageHits) { message in
                                    Button {
                                        if let chat = env.chat(message.chatId) { selectedChat = chat }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(env.chat(message.chatId)?.title ?? "Р§Р°С‚")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(Theme.accentBright)
                                            Text(message.text)
                                                .font(.system(size: 15))
                                                .foregroundColor(Theme.textPrimary)
                                                .lineLimit(2)
                                            Text(Format.fullDate(message.createdAt))
                                                .font(.system(size: 11))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        .padding(.vertical, 3)
                                    }
                                    .listRowBackground(Theme.panel)
                                }
                            }
                        }
                        if chatHits.isEmpty && contactHits.isEmpty && messageHits.isEmpty {
                            Text("РќРёС‡РµРіРѕ РЅРµ РЅР°Р№РґРµРЅРѕ")
                                .foregroundColor(Theme.textSecondary)
                                .listRowBackground(Theme.panel)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "РџРѕРёСЃРє")
            .navigationTitle("РџРѕРёСЃРє")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Р—Р°РєСЂС‹С‚СЊ") { dismiss() }
                }
            }
            .toolbarBackground(Theme.panel, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedChat) { chat in
                ChatDetailView(chatId: chat.id).environmentObject(env)
            }
        }
    }
}

