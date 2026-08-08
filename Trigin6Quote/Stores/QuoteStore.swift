import Foundation
import SwiftUI
import AppKit

@MainActor
final class QuoteStore: ObservableObject {
    @Published var currentQuote: Quote
    @Published var dailyQuotes: [Quote] = []
    @Published var currentIndex: Int = 0
    @Published var favorites: [Quote] = []
    @Published var viewedDates: [Date: Quote] = [:]
    @Published private(set) var quoteFontSize: CGFloat

    private let allQuotes: [Quote]
    private let favoritesKey = "favoriteQuotes"
    private let currentIndexKey = "currentTrigin6Index"

    init() {
        let allQ = QuoteData.uniqueQuotes
        let favs = Self.loadFavoritesStatic()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "lastTrigin6Date") as? Date
        let savedIndices = UserDefaults.standard.array(forKey: "dailyTrigin6Indices") as? [Int]
        let savedIndex = UserDefaults.standard.integer(forKey: "currentTrigin6Index")

        var daily: [Quote] = []
        var idx: Int = 0

        if let savedDate = savedDate,
           calendar.isDate(savedDate, inSameDayAs: today),
           let savedIndices = savedIndices,
           savedIndices.count == 6,
           savedIndex < 6 {
            // 同一天，恢复状态
            daily = savedIndices.compactMap { i in allQ[safe: i] }
            idx = savedIndex
        } else {
            // 新的一天或数据损坏，生成新的6条
            daily = Self.generateTrigin6Quotes(from: allQ, for: today)
            idx = 0
            // 保存状态
            let indices = daily.compactMap { q in allQ.firstIndex { $0.id == q.id } }
            UserDefaults.standard.set(indices, forKey: "dailyTrigin6Indices")
            UserDefaults.standard.set(today, forKey: "lastTrigin6Date")
            UserDefaults.standard.set(0, forKey: "currentTrigin6Index")
        }

        let quote = (idx < daily.count) ? daily[idx] : (daily.first ?? Quote(text: "今日语录加载中...", author: "", category: ""))

        self.allQuotes = allQ
        self.favorites = favs
        self.dailyQuotes = daily
        self.currentIndex = idx
        self.currentQuote = quote
        // 启动时读一次字号缓存，避免每次渲染都访问 UserDefaults
        self.quoteFontSize = Self.computeFontSize()

        // 监听字号变更通知，刷新缓存（由 SettingsView 发出）
        NotificationCenter.default.addObserver(
            forName: .fontSizeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshFontSize() }
        }
    }

    private static func computeFontSize() -> CGFloat {
        switch UserDefaults.standard.integer(forKey: "quoteFontSize") {
        case 0: return 22  // 小
        case 2: return 34  // 大
        default: return 28 // 中（默认）
        }
    }

    private func refreshFontSize() {
        quoteFontSize = Self.computeFontSize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var totalQuoteCount: Int {
        allQuotes.count
    }

    var currentDisplayIndex: Int {
        currentIndex + 1
    }

    func nextQuote() {
        guard !dailyQuotes.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentIndex = (currentIndex + 1) % dailyQuotes.count
            currentQuote = dailyQuotes[currentIndex]
        }
        UserDefaults.standard.set(currentIndex, forKey: currentIndexKey)
    }

    func previousQuote() {
        guard !dailyQuotes.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentIndex = (currentIndex - 1 + dailyQuotes.count) % dailyQuotes.count
            currentQuote = dailyQuotes[currentIndex]
        }
        UserDefaults.standard.set(currentIndex, forKey: currentIndexKey)
    }

    func isFavorite(_ quote: Quote) -> Bool {
        favorites.contains { $0.id == quote.id }
    }

    func toggleFavorite(_ quote: Quote) {
        if isFavorite(quote) {
            favorites.removeAll { $0.id == quote.id }
        } else {
            favorites.append(quote)
        }
        saveFavorites()
    }

    func copyQuote(_ quote: Quote) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        var text = quote.text
        if let translation = quote.translation, !translation.isEmpty {
            text += "\n\n\(translation)"
        }
        text += "\n\n—— \(quote.author)"
        pasteboard.setString(text, forType: .string)
    }

    func shareText(for quote: Quote) -> String {
        var text = quote.text
        if let translation = quote.translation, !translation.isEmpty {
            text += "\n\n\(translation)"
        }
        text += "\n\n—— \(quote.author)"
        // 根据用户设置决定是否附带应用签名
        if UserDefaults.standard.bool(forKey: "shareWithSignature") {
            text += "\n\n来自 Trigin6Quote"
        }
        return text
    }

    /// 根据用户设置返回语录字号（缓存版，见上方 @Published quoteFontSize）
    /// 字号变更由 .fontSizeDidChange 通知触发 refreshFontSize()

    private static func generateTrigin6Quotes(from quotes: [Quote], for date: Date) -> [Quote] {
        guard quotes.count >= 6 else { return quotes }

        var seededRandom = SeededRandom(seed: date.dayOfYear + date.year * 366)
        var indices = Set<Int>()

        while indices.count < 6 {
            let idx = seededRandom.nextInt(upperBound: quotes.count)
            indices.insert(idx)
        }

        return indices.sorted().compactMap { quotes[safe: $0] }
    }

    private static func loadFavoritesStatic() -> [Quote] {
        guard let data = UserDefaults.standard.data(forKey: "favoriteQuotes") else { return [] }
        do {
            return try JSONDecoder().decode([Quote].self, from: data)
        } catch {
            return []
        }
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("保存收藏失败: \(error)")
        }
    }
}

// MARK: - 种子随机数（保证同一天结果一致）

private struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed))
        if state == 0 { state = 1 }
    }

    mutating func nextInt(upperBound: Int) -> Int {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return Int(z % UInt64(upperBound))
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
