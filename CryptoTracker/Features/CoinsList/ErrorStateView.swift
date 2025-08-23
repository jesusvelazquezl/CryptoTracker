//
//  ErrorStateView.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class ErrorStateView: UIView {
    var onRetry: (() -> Void)?

    private let stack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        imageView.image = UIImage(systemName: "wifi.exclamationmark")
        imageView.tintColor = .tertiaryLabel
        imageView.preferredSymbolConfiguration = .init(pointSize: 44, weight: .regular)

        titleLabel.text = "No se pudo cargar"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Comprueba tu conexión y vuelve a intentarlo."
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        retryButton.setTitle("Reintentar", for: .normal)
        retryButton.configuration = .filled()
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        activity.hidesWhenStopped = true

        addSubview(stack)
        [imageView, titleLabel, subtitleLabel, retryButton, activity].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    @objc private func retryTapped() {
        retryButton.isEnabled = false
        activity.startAnimating()
        onRetry?()
    }

    func reset() {
        retryButton.isEnabled = true
        activity.stopAnimating()
    }
}
