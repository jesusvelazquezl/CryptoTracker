//
//  Coin.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

struct Coin: Hashable {
    let id: String
    let name: String
    let imageURL: URL?
    let priceEUR: Double
    let priceChangePct24h: Double?
    let symbol: String

    init(from dto: CoinMarketDTO) {
        id = dto.id
        name = dto.name
        imageURL = URL(string: dto.image ?? "")
        priceEUR = dto.currentPrice ?? 0
        priceChangePct24h = dto.priceChangePercentage24H
        symbol = dto.symbol?.uppercased() ?? ""
    }
}
