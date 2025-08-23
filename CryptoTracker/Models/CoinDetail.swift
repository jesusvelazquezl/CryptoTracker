//
//  CoinDetail.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

struct CoinDetail {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let description: String?
    let priceEUR: Double?
    let priceChangePct24h: Double?
    let marketCapEUR: Double?
    let high24hEUR: Double?
    let low24hEUR: Double?
    let homepage: URL?
}

extension CoinDetail {
    init(from dto: CoinDetailDTO) {
        id = dto.id
        name = dto.name
        symbol = dto.symbol?.uppercased() ?? ""
        imageURL = URL(string: dto.image?.large ?? dto.image?.small ?? "")
        description = dto.description?.en
        priceEUR = dto.marketData?.currentPrice?["eur"] ?? dto.marketData?.currentPrice?["EUR"]
        priceChangePct24h = dto.marketData?.priceChangePercentage24H
        marketCapEUR = dto.marketData?.marketCap?["eur"] ?? dto.marketData?.marketCap?["EUR"]
        high24hEUR = dto.marketData?.high24H?["eur"] ?? dto.marketData?.high24H?["EUR"]
        low24hEUR = dto.marketData?.low24H?["eur"] ?? dto.marketData?.low24H?["EUR"]
        if let first = dto.links?.homepage?.first, let url = URL(string: first) {
            homepage = url
        } else { homepage = nil }
    }
}
