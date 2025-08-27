//
//  CoinDetailViewModelTests.swift
//  CryptoTracker
//
//  Created by Jesus on 27/8/25.
//

import XCTest
@testable import CryptoTracker

final class CoinDetailViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockRepo: CoinRepository {
        var detail: CoinDetail?
        var markets: [[Coin]] = []
        var error: Error?

        func fetchMarketsEUR(page: Int, perPage: Int) async throws -> [Coin] {
            if let error { throw error }
            let idx = max(0, page - 1)
            return idx < markets.count ? markets[idx] : []
        }

        func fetchDetail(id: String) async throws -> CoinDetail {
            if let error { throw error }
            guard let detail else {
                throw NSError(domain: "MockRepo", code: -1, userInfo: [NSLocalizedDescriptionKey: "No detail"])
            }
            return detail
        }
    }

    // MARK: - buildUIModel mapping

    func test_buildUIModel_mapsFields_andFormats() {
        // given
        let initial = MockFactory.coin(
            id: "btc",
            symbol: "btc",
            name: "Bitcoin",
            image: "https://example.com/btc.png",
            price: 12_345.67,
            change24h: 1.23
        )
        let repo = MockRepo()
        repo.detail = MockFactory.coinDetail(
            id: "btc",
            symbol: "btc",
            name: "Bitcoin",
            imageSmall: "https://example.com/btc-small.png",
            imageLarge: "https://example.com/btc-large.png",
            descriptionEN: "The first cryptocurrency.",
            priceEUR: 12345.67,
            change24h: 1.23,
            marketCapEUR: 1_234_567_890, // ~ €1.23B
            high24hEUR: 13000,
            low24hEUR: 12000,
            homepage: "https://bitcoin.org"
        )

        let vm = CoinDetailViewModel(repository: repo, coinID: "btc", initialCoin: initial)

        // when
        let ui = vm.buildUIModel(from: repo.detail!)

        // then
        XCTAssertEqual(ui.title, "Bitcoin")
        XCTAssertEqual(ui.symbol, "BTC")
        XCTAssertNotNil(ui.imageURL)
        XCTAssertEqual(ui.homepage?.absoluteString, "https://bitcoin.org")

        // stats order: price, change24h, marketcap, range24h
        XCTAssertEqual(ui.stats.count, 4)

        // 24h change → should include sign and changeSign computed
        let change = ui.stats[1]
        XCTAssertTrue(change.value.contains("%"))
        XCTAssertEqual(change.changeSign, 1) // positive

        // market cap abbreviated (B/M/K depending on value)
        let marketCap = ui.stats[2].value
        XCTAssertTrue(marketCap.contains("B") || marketCap.contains("M") || marketCap.contains("K"))

        // range text contains separator
        let range = ui.stats[3].value
        XCTAssertTrue(range.contains(String(localized: "detail.range.separator")))
    }

    func test_buildUIModel_withMissingValues_usesMissingString() {
        let initial = MockFactory.coin(id: "eth", symbol: "eth", name: "Ethereum", image: nil, price: nil, change24h: nil)
        let repo = MockRepo()
        repo.detail = MockFactory.coinDetail(
            id: "eth",
            symbol: "eth",
            name: "Ethereum",
            imageSmall: nil,
            imageLarge: nil,
            descriptionEN: nil,
            priceEUR: nil,
            change24h: nil,
            marketCapEUR: nil,
            high24hEUR: nil,
            low24hEUR: nil,
            homepage: nil
        )
        let vm = CoinDetailViewModel(repository: repo, coinID: "eth", initialCoin: initial)

        let ui = vm.buildUIModel(from: repo.detail!)

        XCTAssertNil(ui.homepage)
        XCTAssertNil(ui.description) // trimmed to nil
        // price, change, marketcap, range should show "value.missing"
        XCTAssertEqual(ui.stats[0].value, String(localized: "value.missing"))
        XCTAssertEqual(ui.stats[1].value, String(localized: "value.missing"))
        XCTAssertEqual(ui.stats[2].value, String(localized: "value.missing"))
        XCTAssertEqual(ui.stats[3].value, String(localized: "value.missing"))
    }

    // MARK: - placeholder mapping

    func test_placeholder_usesInitialCoinValues() {
        let initial = MockFactory.coin(
            id: "ada",
            symbol: "ada",
            name: "Cardano",
            image: "https://example.com/ada.png",
            price: 0.25,
            change24h: -2.5
        )
        let vm = CoinDetailViewModel(repository: MockRepo(), coinID: "ada", initialCoin: initial)
        let ui = vm.placeholderUIModel

        XCTAssertEqual(ui.title, "Cardano")
        XCTAssertEqual(ui.symbol, "ADA")
        XCTAssertEqual(ui.imageURL?.absoluteString, "https://example.com/ada.png")
        // Placeholder carries price & change from initial coin
        XCTAssertTrue(ui.stats[0].value.contains("€") || ui.stats[0].value == String(localized: "value.missing"))
    }

    // MARK: - load state

    func test_load_success_setsLoadedState() async {
        let initial = MockFactory.coin(id: "btc")
        let repo = MockRepo()
        repo.detail = MockFactory.coinDetail(id: "btc")
        let vm = CoinDetailViewModel(repository: repo, coinID: "btc", initialCoin: initial)

        var lastState: CoinDetailViewModel.State?
        vm.onStateChange = { lastState = $0 }

        await vm.load()

        guard case .loaded = lastState else { return XCTFail("Expected .loaded") }
    }

    func test_load_failure_setsFailedState() async {
        let initial = MockFactory.coin(id: "btc")
        let repo = MockRepo()
        repo.error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Boom"])
        let vm = CoinDetailViewModel(repository: repo, coinID: "btc", initialCoin: initial)

        var lastState: CoinDetailViewModel.State?
        vm.onStateChange = { lastState = $0 }

        await vm.load()

        guard case let .failed(msg)? = lastState else { return XCTFail("Expected .failed") }
        XCTAssertTrue(msg.lowercased().contains("boom"))
    }
}
