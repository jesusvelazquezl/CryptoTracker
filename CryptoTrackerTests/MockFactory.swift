//
//  Untitled.swift
//  CryptoTracker
//
//  Created by Jesus on 27/8/25.
//

import Foundation
@testable import CryptoTracker

enum MockFactory {
    // MARK: - Coin (desde CoinMarketDTO)

    /// Construye un Coin usando su DTO real. Acepta tanto `priceChange` como `change24h`.
    static func coin(
        id: String = "btc",
        symbol: String? = "btc",
        name: String = "Bitcoin",
        image: String? = "https://example.com/btc.png",
        price: Double? = 12_345.67,
        priceChange: Double? = nil,      // ← alias más natural para tests
        change24h: Double? = nil         // ← compatibilidad con otros tests
    ) -> Coin {
        // Resolver el cambio 24h a partir del alias que venga
        let resolvedChange = priceChange ?? change24h

        let dto = CoinMarketDTO(
            id: id,
            symbol: symbol,
            name: name,
            image: image,
            currentPrice: price,
            priceChangePercentage24H: resolvedChange
        )
        return Coin(from: dto)
    }

    // MARK: - CoinDetail (desde CoinDetailDTO)

    static func coinDetail(
        id: String = "btc",
        symbol: String? = "btc",
        name: String = "Bitcoin",
        imageSmall: String? = "https://example.com/btc-small.png",
        imageLarge: String? = "https://example.com/btc-large.png",
        descriptionEN: String? = "The first cryptocurrency.",
        priceEUR: Double? = 12_345.67,
        change24h: Double? = 2.5,
        marketCapEUR: Double? = 1_000_000_000,
        high24hEUR: Double? = 13_000.0,
        low24hEUR: Double? = 12_000.0,
        homepage: String? = "https://bitcoin.org"
    ) -> CoinDetail {
        var currentPrice: [String: Double]? = nil
        var marketCap: [String: Double]? = nil
        var high24H: [String: Double]? = nil
        var low24H: [String: Double]? = nil

        if let priceEUR { currentPrice = ["eur": priceEUR] }
        if let marketCapEUR { marketCap = ["eur": marketCapEUR] }
        if let high24hEUR { high24H = ["eur": high24hEUR] }
        if let low24hEUR { low24H = ["eur": low24hEUR] }

        let md = CoinDetailDTO.MarketData(
            currentPrice: currentPrice,
            marketCap: marketCap,
            high24H: high24H,
            low24H: low24H,
            priceChangePercentage24H: change24h
        )
        let images = CoinDetailDTO.Images(small: imageSmall, large: imageLarge)
        let links = CoinDetailDTO.Links(homepage: homepage != nil ? [homepage!] : nil)
        let desc = CoinDetailDTO.Description(en: descriptionEN)

        let dto = CoinDetailDTO(
            id: id,
            symbol: symbol,
            name: name,
            image: images,
            description: desc,
            marketData: md,
            links: links
        )
        return CoinDetail(from: dto)
    }
}
