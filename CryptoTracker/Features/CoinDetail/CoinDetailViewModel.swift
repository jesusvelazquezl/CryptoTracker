//
//  CoinDetailViewModel.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

// MARK: - UI Model

struct CoinDetailUIModel {
    struct Stat {
        let title: String
        let value: String
        let changeSign: Int
    }

    let title: String
    let symbol: String
    let imageURL: URL?
    let homepage: URL?
    let stats: [Stat]
    let description: String?

    var hasDescription: Bool {
        description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

// MARK: - ViewModel

final class CoinDetailViewModel {
    enum State { case loading, loaded(CoinDetail), failed(String) }

    private let repository: CoinRepository
    private let coinID: String
    private let initialCoin: Coin

    private(set) var state: State = .loading { didSet { onStateChange?(state) } }
    var onStateChange: ((State) -> Void)?

    init(repository: CoinRepository, coinID: String, initialCoin: Coin) {
        self.repository = repository
        self.coinID = coinID
        self.initialCoin = initialCoin
    }

    // MARK: - Formatting Helpers

    private func abbreviate(_ value: Double) -> (Double, String) {
        let n = abs(value)
        switch n {
        case 1_000_000_000_000...: return (value / 1_000_000_000_000, "T")
        case 1_000_000_000...:     return (value / 1_000_000_000, "B")
        case 1_000_000...:         return (value / 1_000_000, "M")
        case 1_000...:             return (value / 1_000, "K")
        default:                   return (value, "")
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private func formatCurrencyEURAbbrev(_ value: Double) -> String {
        let (v, s) = abbreviate(value)
        let formatted = formatNumber(v)
        return "€" + formatted + s
    }

    // MARK: - UI Model Builder

    func buildUIModel(from detail: CoinDetail) -> CoinDetailUIModel {
        let title = detail.name
        let symbol = detail.symbol.uppercased()

        // Price (never abbreviated)
        let priceText: String = {
            guard let price = detail.priceEUR else { return "—" }
            return Formatters.currencyEUR(price)
        }()

        // 24h change
        let changeText: String
        let changeSign: Int
        if let pct = detail.priceChangePct24h {
            changeText = Formatters.percent(pct)
            changeSign = pct == 0 ? 0 : (pct > 0 ? 1 : -1)
        } else {
            changeText = "—"
            changeSign = 0
        }

        // Market cap (abbreviated)
        let marketCapText: String = {
            guard let mc = detail.marketCapEUR else { return "—" }
            return formatCurrencyEURAbbrev(mc)
        }()

        // 24h range (abbreviate only if >= 1_000)
        let rangeText: String = {
            guard let low = detail.low24hEUR, let high = detail.high24hEUR else { return "—" }
            let lowStr  = abs(low)  >= 1_000 ? formatCurrencyEURAbbrev(low)  : Formatters.currencyEUR(low)
            let highStr = abs(high) >= 1_000 ? formatCurrencyEURAbbrev(high) : Formatters.currencyEUR(high)
            return "\(lowStr) – \(highStr)"
        }()

        let stats: [CoinDetailUIModel.Stat] = [
            .init(title: "Price",        value: priceText,    changeSign: 0),
            .init(title: "24h Change",   value: changeText,   changeSign: changeSign),
            .init(title: "Market Cap",   value: marketCapText, changeSign: 0),
            .init(title: "24h Range",    value: rangeText,    changeSign: 0)
        ]

        let desc = detail.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .init(
            title: title,
            symbol: symbol,
            imageURL: detail.imageURL,
            homepage: detail.homepage,
            stats: stats,
            description: (desc?.isEmpty == true ? nil : desc)
        )
    }

    // MARK: - Loading

    @MainActor
    func load() async {
        do {
            let detail = try await repository.fetchDetail(id: coinID)
            state = .loaded(detail)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Convenience

    var uiData: CoinDetailUIModel? {
        if case let .loaded(detail) = state { return buildUIModel(from: detail) }
        return nil
    }

    var placeholderUIModel: CoinDetailUIModel { buildUIModel(from: placeholder) }

    var placeholder: CoinDetail {
        CoinDetail(
            id: initialCoin.id,
            name: initialCoin.name,
            symbol: initialCoin.symbol,
            imageURL: initialCoin.imageURL,
            description: nil,
            priceEUR: initialCoin.priceEUR,
            priceChangePct24h: initialCoin.priceChangePct24h,
            marketCapEUR: nil,
            high24hEUR: nil,
            low24hEUR: nil,
            homepage: nil
        )
    }
}
