//
//  CoinListCell.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import UIKit
import Kingfisher

final class CoinListCell: UICollectionViewCell {
    static let reuseID = "CoinListCell"

    // MARK: - UI
    private let iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 18
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .tertiarySystemFill
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline) // larger
        l.adjustsFontForContentSizeCategory = true
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let symbolLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .subheadline) // smaller
        l.textColor = .secondaryLabel
        l.adjustsFontForContentSizeCategory = true
        return l
    }()

    private let percentLabel: UILabel = {
        let l = UILabel()
        // Emphasized percentage (semibold)
        let base = UIFont.preferredFont(forTextStyle: .subheadline)
        l.font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
        l.textAlignment = .right
        l.adjustsFontForContentSizeCategory = true
        return l
    }()

    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .footnote) // smaller than %
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.adjustsFontForContentSizeCategory = true
        return l
    }()

    private let leftVStack = UIStackView()
    private let rightVStack = UIStackView()
    private let hStack = UIStackView()

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 14
        v.layer.cornerCurve = .continuous
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1.0
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor
        return v
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Setup
    private func setupViews() {
        // Use contentView; compatible with UICollectionLayoutListConfiguration
        contentView.preservesSuperviewLayoutMargins = true
        preservesSuperviewLayoutMargins = true

        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        leftVStack.axis = .vertical
        leftVStack.spacing = 4
        leftVStack.alignment = .leading
        leftVStack.addArrangedSubview(nameLabel)
        leftVStack.addArrangedSubview(symbolLabel)

        rightVStack.axis = .vertical
        rightVStack.spacing = 4
        rightVStack.alignment = .trailing
        rightVStack.addArrangedSubview(percentLabel)
        rightVStack.addArrangedSubview(priceLabel)

        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hStack)
        hStack.addArrangedSubview(iconView)
        hStack.addArrangedSubview(leftVStack)
        hStack.addArrangedSubview(UIView()) // spacer
        hStack.addArrangedSubview(rightVStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            hStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 4),
            hStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -4),
        ])
    }

    // MARK: - Configure
    struct ViewData {
        let iconURL: URL?
        let name: String
        let symbol: String
        let priceEUR: Double?
        let changePct24h: Double?
    }

    func configure(coin: Coin) {
        let url = coin.imageURL
        let name = coin.name
        let symbol = coin.symbol.uppercased()
        let price = coin.priceEUR
        let pct = coin.priceChangePct24h

        // Icon
        if let u = url {
            iconView.kf.setImage(with: u, placeholder: UIImage(systemName: "bitcoinsign.circle"))
        } else {
            iconView.image = UIImage(systemName: "bitcoinsign.circle")
        }

        nameLabel.text = name
        symbolLabel.text = symbol

        // ▲/▼/◆ + color (no +/-)
        if let p = pct {
            // p is already in percent units (e.g., 3.45 => 3.45%)
            let absPct = abs(p)
            let arrow: String
            let color: UIColor
            if p > 0 {
                arrow = "▲"; color = .systemGreen
            } else if p < 0 {
                arrow = "▼"; color = .systemRed
            } else {
                arrow = "◆"; color = .secondaryLabel // neutral
            }
            let pctStr = Self.percentFormatter.string(from: absPct as NSNumber) ?? String(format: "%.2f", absPct)
            percentLabel.text = "\(arrow) \(pctStr)%"
            percentLabel.textColor = color
        } else {
            percentLabel.text = "—"
            percentLabel.textColor = .secondaryLabel
        }

        // Price (nil-safe)
        if let price {
            let formatted = Self.currencyFormatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f", price)
            priceLabel.text = "€\(formatted)"
        } else {
            priceLabel.text = "—"
        }

        // Accessibility
        isAccessibilityElement = true
        let pctText = percentLabel.text ?? ""
        let priceText = priceLabel.text ?? ""
        accessibilityLabel = "\(name) \(symbol), 24h change \(pctText), price \(priceText)"
    }

    // MARK: - Formatters
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    private static let percentFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()

    // MARK: - Corner Masking by Position
    private func updateCornerMaskForPosition() {
        guard let collectionView = findCollectionView(),
              let indexPath = collectionView.indexPath(for: self) else {
            cardView.layer.maskedCorners = []
            return
        }

        let itemsCount = collectionView.numberOfItems(inSection: indexPath.section)

        // First coin is at index 1 because index 0 is the header cell
        let isFirstCoin = indexPath.item == 1

        // Determine last coin index. If the very last item is a loading cell, the last coin is at (itemsCount - 2),
        // otherwise it's at (itemsCount - 1).
        var lastCoinIndex = max(1, itemsCount - 1)
        if itemsCount >= 2 {
            let lastIndexPath = IndexPath(item: itemsCount - 1, section: indexPath.section)
            if let lastCell = collectionView.cellForItem(at: lastIndexPath),
               type(of: lastCell) != CoinListCell.self {
                lastCoinIndex = itemsCount - 2
            }
        }
        let isLastCoin = indexPath.item == lastCoinIndex

        if isFirstCoin && isLastCoin {
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirstCoin {
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLastCoin {
            cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cardView.layer.maskedCorners = []
        }
    }

    private func findCollectionView() -> UICollectionView? {
        var v: UIView? = superview
        while let current = v, !(current is UICollectionView) { v = current.superview }
        return v as? UICollectionView
    }

    // MARK: - Press (tap) animation
    private func setPressed(_ pressed: Bool, animated: Bool = true) {
        let animations = {
            let scale: CGFloat = pressed ? 0.97 : 1.0
            let alpha: CGFloat = pressed ? 0.90 : 1.0
            self.cardView.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.cardView.alpha = alpha
        }
        if animated {
            UIView.animate(withDuration: 0.15,
                           delay: 0,
                           options: [.beginFromCurrentState, .allowUserInteraction],
                           animations: animations,
                           completion: nil)
        } else {
            animations()
        }
    }

    override var isHighlighted: Bool {
        didSet { setPressed(isHighlighted) }
    }

    override var isSelected: Bool {
        didSet { setPressed(isSelected) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerMaskForPosition()
        cardView.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor
        cardView.backgroundColor = .secondarySystemBackground
        contentView.clipsToBounds = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.layer.maskedCorners = []  // recalculated on next layout pass
        cardView.transform = .identity
        cardView.alpha = 1.0
        iconView.image = nil
        nameLabel.text = nil
        symbolLabel.text = nil
        percentLabel.text = nil
        priceLabel.text = nil
    }
}
