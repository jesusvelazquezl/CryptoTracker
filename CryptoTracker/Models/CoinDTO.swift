//
//  CoinDTO.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

struct CoinMarketDTO: Decodable {
    let id: String
    let symbol: String?
    let name: String
    let image: String?
    let currentPrice: Double?
    let priceChangePercentage24H: Double?
}
