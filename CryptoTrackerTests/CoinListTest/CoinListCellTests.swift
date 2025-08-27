//
//  CoinListCellTests.swift.swift
//  CryptoTracker
//
//  Created by Jesus on 27/8/25.
//

import XCTest
@testable import CryptoTracker

final class CoinListCellTests: XCTestCase {
    func test_configure_setsArrowAndAccessibility() {
        let cell = CoinListCell(frame: .init(x: 0, y: 0, width: 320, height: 44))

        // Up
        cell.configure(coin: MockFactory.coin(id: "up", priceChange: 3.5))
        XCTAssertTrue(cell.accessibilityLabel?.contains("▲") == true)

        // Down
        cell.configure(coin: MockFactory.coin(id: "down", priceChange: -1.2))
        XCTAssertTrue(cell.accessibilityLabel?.contains("▼") == true)

        // Flat
        cell.configure(coin: MockFactory.coin(id: "flat", priceChange: 0))
        XCTAssertTrue(cell.accessibilityLabel?.contains("◆") == true)
    }
}
