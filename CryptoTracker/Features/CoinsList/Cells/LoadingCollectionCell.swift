//
//  LoadingCollectionCell.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class LoadingCollectionCell: UICollectionViewCell {
    static let reuseID = "LoadingCollectionCell"
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        var bg = UIBackgroundConfiguration.listPlainCell()
        bg.backgroundColor = .clear
        backgroundConfiguration = bg

        contentView.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func startAnimating() { spinner.startAnimating() }
}
