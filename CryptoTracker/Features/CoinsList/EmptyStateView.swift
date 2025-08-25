//
//  EmptyStateView.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class EmptyStateView: UIView {

    // MARK: - UI
    private let contentStack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Public
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    // MARK: - Private
    private func setupViews() {
        backgroundColor = .clear

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        imageView.image = UIImage(systemName: "tray")
        imageView.preferredSymbolConfiguration = .init(pointSize: 44, weight: .regular)
        imageView.tintColor = .tertiaryLabel
        imageView.setContentHuggingPriority(.required, for: .vertical)

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        addSubview(contentStack)
        [imageView, titleLabel, subtitleLabel].forEach { contentStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            contentStack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }
}
