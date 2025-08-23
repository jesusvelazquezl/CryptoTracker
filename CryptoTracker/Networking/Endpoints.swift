//
//  Endpoints.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

enum Endpoint {
    case marketsEUR(page: Int, perPage: Int = 100)
    case coinDetail(id: String)

    var urlRequest: URLRequest {
        let base = URL(string: "https://api.coingecko.com/api/v3")!
        switch self {
        case .marketsEUR(let page, let perPage):
            var comps = URLComponents(url: base.appendingPathComponent("/coins/markets"), resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                .init(name: "vs_currency", value: "eur"),
                .init(name: "order", value: "market_cap_desc"),
                .init(name: "per_page", value: String(perPage)),
                .init(name: "page", value: String(page)),
                .init(name: "sparkline", value: "false")
            ]
            return URLRequest(url: comps.url!)

        case .coinDetail(let id):
            var comps = URLComponents(url: base.appendingPathComponent("/coins/\(id)"), resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                .init(name: "localization", value: "false"),
                .init(name: "tickers", value: "false"),
                .init(name: "market_data", value: "true"),
                .init(name: "community_data", value: "false"),
                .init(name: "developer_data", value: "false"),
                .init(name: "sparkline", value: "false")
            ]
            return URLRequest(url: comps.url!)
        }
    }
}
