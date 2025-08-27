//
//  CoinDetailUIModelTests.swift
//  CryptoTracker
//
//  Created by Jesus on 27/8/25.
//

import XCTest
@testable import CryptoTracker

final class CoinDetailUIModelTests: XCTestCase {

    func test_hasDescription_true_whenNonEmpty() {
        let detail = MockFactory.coinDetail(descriptionEN: " Hello world ")
        let vm = CoinDetailViewModel(
            repository: DummyRepo(),
            coinID: "id",
            initialCoin: MockFactory.coin(id: "id")
        )

        let ui = vm.buildUIModel(from: detail)
        XCTAssertTrue(ui.hasDescription)
        XCTAssertEqual(ui.description, "Hello world")
    }

    func test_hasDescription_false_whenNilOrWhitespace() {
        let vm = CoinDetailViewModel(
            repository: DummyRepo(),
            coinID: "id",
            initialCoin: MockFactory.coin(id: "id")
        )

        let nilDesc = MockFactory.coinDetail(descriptionEN: nil)
        XCTAssertFalse(vm.buildUIModel(from: nilDesc).hasDescription)

        let wsDesc = MockFactory.coinDetail(descriptionEN: "   ")
        XCTAssertFalse(vm.buildUIModel(from: wsDesc).hasDescription)
    }

    func test_changeSign_mapping() {
        let vm = CoinDetailViewModel(
            repository: DummyRepo(),
            coinID: "id",
            initialCoin: MockFactory.coin(id: "id")
        )

        let up = MockFactory.coinDetail(change24h: 2.0)
        XCTAssertEqual(vm.buildUIModel(from: up).stats[1].changeSign, 1)

        let down = MockFactory.coinDetail(change24h: -0.1)
        XCTAssertEqual(vm.buildUIModel(from: down).stats[1].changeSign, -1)

        let flat = MockFactory.coinDetail(change24h: 0.0)
        XCTAssertEqual(vm.buildUIModel(from: flat).stats[1].changeSign, 0)

        let missing = MockFactory.coinDetail(change24h: nil)
        XCTAssertEqual(vm.buildUIModel(from: missing).stats[1].changeSign, 0)
    }
}

// MARK: - Lightweight Dummy Repo

private final class DummyRepo: CoinRepository {
    func fetchMarketsEUR(page: Int, perPage: Int) async throws -> [Coin] { return [] }
    func fetchDetail(id: String) async throws -> CoinDetail { throw NSError(domain: "dummy", code: -1) }
}
