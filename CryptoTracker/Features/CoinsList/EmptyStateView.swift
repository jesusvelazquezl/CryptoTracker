//
//  EmptyStateView.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class EmptyStateView: UIView {
    private let stack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func setup() {
        backgroundColor = .clear

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

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

        addSubview(stack)
        [imageView, titleLabel, subtitleLabel].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }
}
