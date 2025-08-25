//
//  HeaderCollectionCell.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class HeaderCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "HeaderCollectionCell"

    // MARK: - UI
    private let headerImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "coingecko_header"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return iv
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "powered by CoinGecko"
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        return l
    }()

    private let stack = UIStackView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        contentView.backgroundColor = .clear

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        stack.addArrangedSubview(headerImageView)
        stack.addArrangedSubview(subtitleLabel)

        // Layout
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            headerImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 190),
            headerImageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
        ])

        // Accessibility
        isAccessibilityElement = false
        headerImageView.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = true
        subtitleLabel.accessibilityLabel = "Powered by CoinGecko"
    }

    // MARK: - API
    func configure(imageName: String = "coingecko_header", subtitle: String = "powered by CoinGecko") {
        headerImageView.image = UIImage(named: imageName)
        subtitleLabel.text = subtitle
        subtitleLabel.accessibilityLabel = subtitle
    }
}
