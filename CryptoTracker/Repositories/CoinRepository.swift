//
//  CoinRepository.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

protocol CoinRepository {
    func fetchMarketsEUR(page: Int, perPage: Int) async throws -> [Coin]
    func fetchDetail(id: String) async throws -> CoinDetail
}

final class CoinGeckoRepository: CoinRepository {
    private let api: APIClientProtocol
    init(apiClient: APIClientProtocol) { self.api = apiClient }

    func fetchMarketsEUR(page: Int, perPage: Int = 100) async throws -> [Coin] {
        let dtos = try await api.send([CoinMarketDTO].self, endpoint: .marketsEUR(page: page, perPage: perPage))
        return dtos.map(Coin.init(from:))
    }

    func fetchDetail(id: String) async throws -> CoinDetail {
        let dto = try await api.send(CoinDetailDTO.self, endpoint: .coinDetail(id: id))
        return CoinDetail(from: dto)
    }
}
