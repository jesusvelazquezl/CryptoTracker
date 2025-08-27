//
//  CoinsListViewModelTests.swift.swift
//  CryptoTracker
//
//  Created by Jesus on 27/8/25.
//

import XCTest
@testable import CryptoTracker

final class CoinsListViewModelTests: XCTestCase {
    private final class MockRepo: CoinRepository {
        var pages: [[Coin]] = []
        var error: Error?
        func fetchMarketsEUR(page: Int, perPage: Int) async throws -> [Coin] {
            if let error { throw error }
            let idx = max(0, page - 1)
            return idx < pages.count ? pages[idx] : []
        }
        func fetchDetail(id: String) async throws -> CoinDetail {
            throw NSError(domain: "MockRepo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in tests"])
        }
    }

    func test_load_success_emitsLoaded() async {
        let repo = MockRepo()
        repo.pages = [[MockFactory.coin(id: "btc"), MockFactory.coin(id: "eth")]]
        let vm = CoinsListViewModel(repository: repo)

        var last: CoinsListViewModel.State?
        vm.onStateChange = { last = $0 }

        await vm.load()
        guard case let .loaded(list)? = last else { return XCTFail("Expected loaded") }
        XCTAssertEqual(list.map(\.id), ["btc","eth"])
    }

    func test_load_failure_emitsFailed() async {
        enum E: Error { case boom }
        let repo = MockRepo(); repo.error = E.boom
        let vm = CoinsListViewModel(repository: repo)

        var last: CoinsListViewModel.State?
        vm.onStateChange = { last = $0 }

        await vm.load()
        guard case let .failed(msg)? = last else { return XCTFail("Expected failed") }
        XCTAssertTrue(msg.contains("boom"))
    }

    func test_pagination_appends_and_stops() async {
        let repo = MockRepo()
        repo.pages = [[MockFactory.coin(id:"1"), MockFactory.coin(id:"2")], [MockFactory.coin(id:"3")], []]
        let vm = CoinsListViewModel(repository: repo)

        var paging: [Bool] = []
        vm.onPagingChange = { paging.append($0) }

        await vm.load()
        XCTAssertEqual(vm.coins.map(\.id), ["1","2"])

        await vm.loadNextPageIfNeeded(currentIndex: 1)
        XCTAssertEqual(vm.coins.map(\.id), ["1","2","3"])

        await vm.loadNextPageIfNeeded(currentIndex: 2) // end reached
        XCTAssertEqual(vm.coins.map(\.id), ["1","2","3"])

        XCTAssertEqual(paging, [true,false])
    }
}
