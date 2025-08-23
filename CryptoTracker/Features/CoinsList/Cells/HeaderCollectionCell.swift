//
//  HeaderCollectionCell.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class HeaderCollectionCell: UICollectionViewCell {
    static let reuseID = "HeaderCollectionCell"
    private let imageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "coingecko_header"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let label: UILabel = {
        let l = UILabel()
        l.text = "powered by CoinGecko"
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 190),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure() {
        // No-op for now; image and text are static
    }
}
