//
//  CoinDetailDTO.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

struct CoinDetailDTO: Decodable {
    struct MarketData: Decodable {
        let currentPrice: [String: Double]?
        let marketCap: [String: Double]?
        let high24H: [String: Double]?
        let low24H: [String: Double]?
        let priceChangePercentage24H: Double?
    }
    struct Images: Decodable { let small: String?; let large: String? }
    struct Links: Decodable { let homepage: [String]? }
    struct Description: Decodable { let en: String? }

    let id: String
    let symbol: String?
    let name: String
    let image: Images?
    let description: Description?
    let marketData: MarketData?
    let links: Links?
}
