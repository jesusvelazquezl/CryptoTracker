//
//  ErrorStateView.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class ErrorStateView: UIView {

    // MARK: - Public
    var onRetry: (() -> Void)?

    // MARK: - UI
    private let contentStack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Private
    private func setupViews() {
        backgroundColor = .clear

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        imageView.image = UIImage(systemName: "wifi.exclamationmark")
        imageView.tintColor = .tertiaryLabel
        imageView.preferredSymbolConfiguration = .init(pointSize: 44, weight: .regular)
        imageView.isAccessibilityElement = false

        titleLabel.text = String(localized: "errorstate.title")
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center

        subtitleLabel.text = String(localized: "errorstate.subtitle")
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        retryButton.setTitle(String(localized: "errorstate.retry"), for: .normal)
        retryButton.configuration = .filled()
        retryButton.addTarget(self, action: #selector(handleRetryTapped), for: .touchUpInside)
        retryButton.accessibilityHint = String(localized: "errorstate.retry.hint")

        activityIndicator.hidesWhenStopped = true

        addSubview(contentStack)
        [imageView, titleLabel, subtitleLabel, retryButton, activityIndicator].forEach { contentStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            contentStack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }

    // MARK: - Public
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    func resetState() {
        retryButton.isEnabled = true
        activityIndicator.stopAnimating()
    }

    // MARK: - Actions
    @objc private func handleRetryTapped() {
        retryButton.isEnabled = false
        activityIndicator.startAnimating()
        onRetry?()
    }
}
