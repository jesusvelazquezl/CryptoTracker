//
//  CoinDetailViewModel.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

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

    @MainActor func load() async {
        do { let detail = try await repository.fetchDetail(id: coinID); state = .loaded(detail) }
        catch { state = .failed(error.localizedDescription) }
    }

    var placeholder: CoinDetail {
        CoinDetail(id: initialCoin.id, name: initialCoin.name, symbol: initialCoin.symbol,
                   imageURL: initialCoin.imageURL, description: nil,
                   priceEUR: initialCoin.priceEUR, priceChangePct24h: initialCoin.priceChangePct24h,
                   marketCapEUR: nil, high24hEUR: nil, low24hEUR: nil, homepage: nil)
    }
}
