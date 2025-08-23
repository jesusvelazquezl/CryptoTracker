//
//  CoinDetailViewController.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import UIKit
 import Kingfisher

final class CoinDetailViewController: UIViewController {
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let imageView = UIImageView()
    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let marketCapLabel = UILabel()
    private let rangeLabel = UILabel()
    private let linkButton = UIButton(type: .system)
    private let descLabel = UILabel()

    private let viewModel: CoinDetailViewModel
    private var homeURL: URL?

    init(viewModel: CoinDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI(); layout(); bind()
        render(viewModel.placeholder)
        Task { await viewModel.load() }

        navigationItem.backButtonDisplayMode = .minimal
    }

    private func setupUI() {
        content.axis = .vertical; content.spacing = 12
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        [priceLabel, changeLabel, marketCapLabel, rangeLabel].forEach { $0.font = .preferredFont(forTextStyle: .headline) }
        descLabel.font = .preferredFont(forTextStyle: .body); descLabel.numberOfLines = 0; descLabel.textColor = .secondaryLabel
        linkButton.setTitle("Abrir sitio", for: .normal); linkButton.addTarget(self, action: #selector(openLink), for: .touchUpInside)

        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        
        [imageView, priceLabel, changeLabel, marketCapLabel, rangeLabel, linkButton, descLabel].forEach { content.addArrangedSubview($0) }
        view.addSubview(scroll); scroll.addSubview(content)
        [scroll, content].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    }

    private func layout() {
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .loading: break
            case .loaded(let detail): self.render(detail)
            case .failed(let msg): self.showError(msg)
            }
        }
    }

    private func render(_ detail: CoinDetail) {
        navigationItem.title = "\(detail.name) (\(detail.symbol))"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        if let url = detail.imageURL {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "bitcoinsign.circle")
            )
        } else {
            imageView.image = UIImage(systemName: "bitcoinsign.circle")
        }

        priceLabel.text = "Precio: " + (detail.priceEUR.map(Formatters.currencyEUR) ?? "—")
        if let pct = detail.priceChangePct24h {
            changeLabel.text = "Variación 24h: " + Formatters.percent(pct)
            changeLabel.textColor = pct >= 0 ? .systemGreen : .systemRed
        } else {
            changeLabel.text = "Variación 24h: —"
            changeLabel.textColor = .secondaryLabel
        }

        marketCapLabel.text = "Market Cap: " + (detail.marketCapEUR.map(Formatters.currencyEUR) ?? "—")
        if let low = detail.low24hEUR, let high = detail.high24hEUR {
            rangeLabel.text = "Rango 24h: \(Formatters.currencyEUR(low)) – \(Formatters.currencyEUR(high))"
        } else {
            rangeLabel.text = "Rango 24h: —"
        }

        descLabel.text = detail.description ?? "Sin descripción."
        homeURL = detail.homepage
        linkButton.isHidden = homeURL == nil
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func openLink() { if let url = homeURL { UIApplication.shared.open(url) } }
}
