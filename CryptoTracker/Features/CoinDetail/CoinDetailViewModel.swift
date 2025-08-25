//
//  CoinDetailViewModel.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//


import Foundation

// MARK: - UI Adapter
struct CoinDetailUIData {
    struct Stat { let title: String; let value: String; let changeSign: Int }
    let title: String
    let symbol: String
    let imageURL: URL?
    let homepage: URL?
    let stats: [Stat]
    let description: String?
    var hasDescription: Bool { description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
}

final class CoinDetailViewModel {
    enum State { case loading, loaded(CoinDetail), failed(String) }

    private let repository: CoinRepository
    private let coinID: String
    private let initialCoin: Coin

    private(set) var state: State = .loading { didSet { onStateChange?(state) } }
    var onStateChange: ((State) -> Void)?

    init(repository: CoinRepository, coinID: String, initialCoin: Coin) {
        self.repository = repository; self.coinID = coinID; self.initialCoin = initialCoin
    }

    // MARK: - Friendly Number Formatting
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

    func makeUIData(from detail: CoinDetail) -> CoinDetailUIData {
        let title = detail.name
        let symbol = detail.symbol.uppercased()
        let priceStr: String
        if let price = detail.priceEUR {
            priceStr = Formatters.currencyEUR(price)
        } else {
            priceStr = "—"
        }
        let pctStr: String
        let sign: Int
        if let pct = detail.priceChangePct24h {
            pctStr = Formatters.percent(pct)
            sign = pct == 0 ? 0 : (pct > 0 ? 1 : -1)
        } else { pctStr = "—"; sign = 0 }
        let mcapStr: String
        if let mc = detail.marketCapEUR {
            mcapStr = formatCurrencyEURAbbrev(mc)
        } else {
            mcapStr = "—"
        }
        let rangeStr: String = {
            if let low = detail.low24hEUR, let high = detail.high24hEUR {
                let lowStr  = abs(low)  >= 1_000 ? formatCurrencyEURAbbrev(low)  : Formatters.currencyEUR(low)
                let highStr = abs(high) >= 1_000 ? formatCurrencyEURAbbrev(high) : Formatters.currencyEUR(high)
                return "\(lowStr) – \(highStr)"
            } else { return "—" }
        }()
        let stats: [CoinDetailUIData.Stat] = [
            .init(title: "Precio", value: priceStr, changeSign: 0),
            .init(title: "Variación 24h", value: pctStr, changeSign: sign),
            .init(title: "Market Cap", value: mcapStr, changeSign: 0),
            .init(title: "Rango 24h", value: rangeStr, changeSign: 0)
        ]
        let desc = detail.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .init(title: title, symbol: symbol, imageURL: detail.imageURL, homepage: detail.homepage, stats: stats, description: (desc?.isEmpty == true ? nil : desc))
    }

    @MainActor func load() async {
        do { let detail = try await repository.fetchDetail(id: coinID); state = .loaded(detail) }
        catch { state = .failed(error.localizedDescription) }
    }

    var uiData: CoinDetailUIData? {
        if case let .loaded(detail) = state { return makeUIData(from: detail) }
        return nil
    }

    var placeholderUIData: CoinDetailUIData { makeUIData(from: placeholder) }

    var placeholder: CoinDetail {
        CoinDetail(id: initialCoin.id, name: initialCoin.name, symbol: initialCoin.symbol,
                   imageURL: initialCoin.imageURL, description: nil,
                   priceEUR: initialCoin.priceEUR, priceChangePct24h: initialCoin.priceChangePct24h,
                   marketCapEUR: nil, high24hEUR: nil, low24hEUR: nil, homepage: nil)
    }
}
