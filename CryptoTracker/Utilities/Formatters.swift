//
//  Formatters.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

enum Formatters {
    static func currencyEUR(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? "€\(value)"
    }
    static func percent(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f.string(from: NSNumber(value: value / 100)) ?? "\(value)%"
    }
}
