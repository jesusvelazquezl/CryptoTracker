//
//  LoadingCollectionCell.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class LoadingCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "LoadingCollectionCell"

    // MARK: - UI
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        var bg = UIBackgroundConfiguration.listPlainCell()
        bg.backgroundColor = .clear
        backgroundConfiguration = bg

        contentView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits.insert(.updatesFrequently)
        accessibilityLabel = String(localized: "loadingcell.label")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - API
    func startAnimating() {
        activityIndicator.startAnimating()
        accessibilityValue = String(localized: "loadingcell.value.in_progress")
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
        accessibilityValue = String(localized: "loadingcell.value.stopped")
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }
}
