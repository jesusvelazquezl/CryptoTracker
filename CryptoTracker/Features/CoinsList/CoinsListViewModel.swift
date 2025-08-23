//
//  CoinsListViewModel.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

final class CoinsListViewModel {
    enum State: Equatable {
        case idle
        case loading                 // loading first page
        case loaded([Coin])          // full list so far (all pages fetched)
        case failed(String)
    }

    private let repository: CoinRepository
    private(set) var state: State = .idle { didSet { onStateChange?(state) } }

    // Pagination state
    private(set) var coins: [Coin] = []
    private var currentPage: Int = 1
    private let perPage: Int = 100
    private var isLoadingNextPage: Bool = false
    private var reachedEnd: Bool = false

    // Callbacks
    var onStateChange: ((State) -> Void)?
    /// Toggle for the loader footer cell (true = show, false = hide)
    var onPagingChange: ((Bool) -> Void)?

    init(repository: CoinRepository) { self.repository = repository }

    // MARK: - Public API

    /// Loads the first page (used on first launch and on pull-to-refresh)
    @MainActor
    func load() async {
        state = .loading
        currentPage = 1
        reachedEnd = false
        do {
            let pageCoins = try await repository.fetchMarketsEUR(page: currentPage, perPage: perPage)
            coins = pageCoins
            state = .loaded(coins)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Convenience for pull-to-refresh
    @MainActor
    func refresh() async { await load() }

    /// Call from VC when a given index is about to display (e.g., willDisplay at indexPath.item)
    /// Triggers next page when user reaches the last 5 items (i.e., at item 95 of a 100-item page)
    @MainActor
    func loadNextPageIfNeeded(currentIndex: Int) async {
        guard !isLoadingNextPage, !reachedEnd else { return }
        let thresholdIndex = max(0, coins.count - 5)
        guard currentIndex >= thresholdIndex else { return }

        isLoadingNextPage = true
        onPagingChange?(true) // show loading footer cell

        do {
            let nextPage = currentPage + 1
            let pageCoins = try await repository.fetchMarketsEUR(page: nextPage, perPage: perPage)
            if pageCoins.isEmpty {
                reachedEnd = true
            } else {
                currentPage = nextPage
                coins.append(contentsOf: pageCoins)
                state = .loaded(coins) // emit combined list to update UI
            }
        } catch {
            // Keep currentPage as is; surface error
            state = .failed(error.localizedDescription)
        }

        isLoadingNextPage = false
        onPagingChange?(false) // hide loading footer cell
    }
}
