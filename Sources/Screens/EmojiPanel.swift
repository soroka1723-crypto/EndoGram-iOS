import SwiftUI

/// Панель эмодзи в стиле Telegram: дорожка категорий и сетка символов.
/// Эмодзи — обычный текст, поэтому вставляются в черновик по-настоящему.
struct EmojiPanel: View {
    let onPick: (String) -> Void

    @AppStorage("endogram.recentEmoji") private var recentRaw = ""
    @State private var categoryIndex = 0

    private struct Category: Identifiable {
        let id: Int
        let title: String
        let icon: String
        let emoji: [String]
    }

    private static let categories: [Category] = [
        Category(id: 0, title: "Часто используемые", icon: "clock", emoji: []),
        Category(id: 1, title: "Смайлы и эмоции", icon: "face.smiling", emoji: [
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🥲", "😊", "😇", "🙂",
            "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝",
            "🤪", "🤨", "🧐", "🤓", "😎", "🥳", "😏", "😒", "😞", "😔", "😟", "😕",
            "🙁", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬",
            "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗", "🤔", "🤭",
            "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😴", "🤤", "😪", "😵",
            "🤐", "🥴", "🤢", "🤮", "🤧", "😷", "🤒", "🤕", "🤑", "🤠", "😈", "👿"
        ]),
        Category(id: 2, title: "Жесты и люди", icon: "hand.raised.fill", emoji: [
            "👋", "🤚", "🖐", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘",
            "🤙", "👈", "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛",
            "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️", "💅", "🤳", "💪", "🦾",
            "🦵", "🦶", "👂", "🦻", "👃", "🧠", "🫀", "🫁", "🦷", "🦴", "👀", "👁"
        ]),
        Category(id: 3, title: "Животные и природа", icon: "leaf.fill", emoji: [
            "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮",
            "🐷", "🐸", "🐵", "🙈", "🙉", "🙊", "🐒", "🐔", "🐧", "🐦", "🐤", "🦆",
            "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞",
            "🌸", "🌹", "🌺", "🌻", "🌼", "🌷", "🌱", "🌲", "🌳", "🌴", "🌵", "🍀"
        ]),
        Category(id: 4, title: "Еда и напитки", icon: "fork.knife", emoji: [
            "🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒",
            "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶",
            "🌽", "🥕", "🧄", "🧅", "🥔", "🍠", "🥐", "🍞", "🥖", "🧀", "🥚", "🍳",
            "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🌯", "🍜", "🍝", "🍣", "🍱", "🍰"
        ]),
        Category(id: 5, title: "Активности", icon: "figure.walk", emoji: [
            "⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🏓", "🏸",
            "🥊", "🥋", "⛳️", "🏹", "🎣", "🤿", "🎽", "🛹", "🛼", "🚴", "🏆", "🥇",
            "🥈", "🥉", "🎖", "🏅", "🎗", "🎫", "🎟", "🎪", "🤹", "🎭", "🎨", "🎬"
        ]),
        Category(id: 6, title: "Путешествия", icon: "airplane", emoji: [
            "🚗", "🚕", "🚙", "🚌", "🚎", "🏎", "🚓", "🚑", "🚒", "🚐", "🚚", "🚛",
            "🚜", "🛵", "🏍", "🚲", "✈️", "🛫", "🛬", "🚀", "🛰", "🚁", "⛵️", "🚤",
            "🏔", "🌋", "🏕", "🏖", "🏝", "🏟", "🏛", "🏰", "🗼", "🗽", "🎡", "🌉"
        ]),
        Category(id: 7, title: "Объекты", icon: "lightbulb.fill", emoji: [
            "⌚️", "📱", "💻", "⌨️", "🖥", "🖨", "🖱", "💽", "💾", "💿", "📀", "📷",
            "📸", "📹", "🎥", "📞", "☎️", "📟", "📠", "📺", "📻", "🎙", "⏰", "⌛️",
            "🔋", "🔌", "💡", "🔦", "🕯", "🧯", "💰", "💳", "💎", "⚖️", "🔧", "🔨"
        ]),
        Category(id: 8, title: "Символы", icon: "heart.fill", emoji: [
            "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕",
            "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️", "✝️", "☪️", "🕉", "✡️",
            "⚠️", "🚫", "✅", "❌", "❗️", "❓", "💯", "🔥", "✨", "🎉", "🎊", "⭐️"
        ]),
        Category(id: 9, title: "Флаги", icon: "flag.fill", emoji: [
            "🏁", "🚩", "🎌", "🏴", "🏳️", "🏳️‍🌈", "🇷🇺", "🇺🇸", "🇬🇧", "🇩🇪", "🇫🇷", "🇮🇹",
            "🇪🇸", "🇵🇹", "🇳🇱", "🇸🇪", "🇳🇴", "🇫🇮", "🇵🇱", "🇺🇦", "🇹🇷", "🇯🇵", "🇨🇳", "🇰🇷"
        ])
    ]

    private var recent: [String] {
        recentRaw.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }

    private var current: [String] {
        categoryIndex == 0 ? recent : Self.categories[categoryIndex].emoji
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    var body: some View {
        VStack(spacing: 0) {
            categoryStrip
            DividerLine(inset: 0)
            ScrollView {
                if current.isEmpty {
                    Text(categoryIndex == 0
                         ? "Здесь появятся эмодзи, которые вы выберете."
                         : "Нет символов.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(current, id: \.self) { emoji in
                            Button {
                                pick(emoji)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 27))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Theme.panelElevated)
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Self.categories) { category in
                    Button {
                        categoryIndex = category.id
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 16))
                            Text(category.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        .foregroundColor(categoryIndex == category.id ? Theme.accent : Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(categoryIndex == category.id ? Theme.accent.opacity(0.14) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func pick(_ emoji: String) {
        onPick(emoji)
        var list = recent.filter { $0 != emoji }
        list.insert(emoji, at: 0)
        recentRaw = list.prefix(24).joined(separator: "\n")
    }
}
