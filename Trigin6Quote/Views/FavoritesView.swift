import SwiftUI

struct FavoritesView: View {
    @ObservedObject var store: QuoteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isPresented) private var isPresented

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                Group {
                    if store.favorites.isEmpty {
                        ContentUnavailableView(
                            "暂无收藏",
                            systemImage: "bookmark",
                            description: Text("点击语录卡片下方的收藏按钮来保存喜欢的语录")
                        )
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(store.favorites) { quote in
                                    QuoteRowView(quote: quote, store: store, scheme: colorScheme)
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
            .navigationTitle("我的收藏")
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct AllQuotesView: View {
    @ObservedObject var store: QuoteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedCategory: String?

    private var categories: [String] {
        QuoteData.allCategories
    }

    private var filteredQuotes: [Quote] {
        var quotes = QuoteData.quotesInCategory(selectedCategory)

        if !searchText.isEmpty {
            quotes = quotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        return quotes
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                label: "全部",
                                isSelected: selectedCategory == nil,
                                scheme: colorScheme
                            ) { selectedCategory = nil }

                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    label: category,
                                    isSelected: selectedCategory == category,
                                    scheme: colorScheme
                                ) { selectedCategory = category }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }

                    Divider()
                        .overlay(AppTheme.cardBorder(for: colorScheme))

                    if filteredQuotes.isEmpty {
                        ContentUnavailableView("未找到匹配语录", systemImage: "magnifyingglass")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredQuotes) { quote in
                                    QuoteRowView(quote: quote, store: store, scheme: colorScheme)
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
            .navigationTitle("全部语录 (\(QuoteData.uniqueQuotes.count) 条)")
            .searchable(text: $searchText, prompt: "搜索语录或作者")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(width: 640, height: 720)
    }
}

// MARK: - 分类标签

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isSelected
                        ? (scheme == .light ? Color(red: 0.15, green: 0.14, blue: 0.13) : Color.black)
                        : AppTheme.textSecondary(for: scheme)
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? AppTheme.accent
                                : AppTheme.buttonBackground(for: scheme, isHovering: false)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : AppTheme.buttonBorder(for: scheme, isHovering: false),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 语录行

struct QuoteRowView: View {
    let quote: Quote
    @ObservedObject var store: QuoteStore
    let scheme: ColorScheme
    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(quote.text)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                if let translation = quote.translation, !translation.isEmpty {
                    Text(translation)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary(for: scheme).opacity(0.7))
                        .italic()
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Text(quote.author)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.accentText(for: scheme))

                    Spacer()

                    Text(QuoteData.normalizedCategory(for: quote))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary(for: scheme))
                }
            }

            VStack(spacing: 10) {
                Button(action: { store.toggleFavorite(quote) }) {
                    Image(systemName: store.isFavorite(quote) ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(store.isFavorite(quote) ? AppTheme.accent : AppTheme.textTertiary(for: scheme))
                }
                .buttonStyle(.plain)

                Button(action: {
                    store.copyQuote(quote)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showCopied = false
                    }
                }) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundStyle(showCopied ? AppTheme.accent : AppTheme.textTertiary(for: scheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.cardBorder(for: scheme), lineWidth: 1)
        )
    }
}
