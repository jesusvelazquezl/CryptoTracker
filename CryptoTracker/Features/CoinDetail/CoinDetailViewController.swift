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
    private var toast: ToastErrorPresenter!
    private let imageView = UIImageView()
    
    // New: name & ticker UI
    private let nameTitleLabel = UILabel()
    private let tickerTitleLabel = UILabel()
    private let nameScroll = UIScrollView()
    private let nameLabel = UILabel()
    private let tickerLabel = UILabel()
    private var nameMarqueeAnimator: UIViewPropertyAnimator?
    
    // Cards & stacks
    private let statsCard = UIView()
    private let statsStack = UIStackView()
    private let descCard = UIView()
    private let toggleDescButton = UIButton(type: .system)
    private var isDescExpanded = false
    
    // Row title labels
    private let priceTitleLabel = UILabel()
    private let changeTitleLabel = UILabel()
    private let marketCapTitleLabel = UILabel()
    private let rangeTitleLabel = UILabel()
    
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
        toast = ToastErrorPresenter(hostView: view, theme: .card)
        setupUI(); layout(); bind()
        render(viewModel.placeholder)
        Task { await viewModel.load() }

        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupUI() {
        content.axis = .vertical; content.spacing = 12
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        // Name (marquee) and Ticker rows
        nameScroll.showsHorizontalScrollIndicator = false
        nameScroll.showsVerticalScrollIndicator = false
        nameScroll.isScrollEnabled = false
        nameScroll.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.lineBreakMode = .byClipping
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textAlignment = .right
        nameScroll.addSubview(nameLabel)
        // Pin label to scroll's contentLayoutGuide so it can exceed bounds
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: nameScroll.contentLayoutGuide.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: nameScroll.contentLayoutGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: nameScroll.contentLayoutGuide.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: nameScroll.contentLayoutGuide.bottomAnchor),
            nameLabel.heightAnchor.constraint(equalTo: nameScroll.frameLayoutGuide.heightAnchor),
            nameLabel.widthAnchor.constraint(greaterThanOrEqualTo: nameScroll.frameLayoutGuide.widthAnchor)
        ])
        
        // Right bar button (globe) for website
        let globeImage = UIImage(systemName: "globe")
        let barButton = UIBarButtonItem(image: globeImage, style: .plain, target: self, action: #selector(openLink))
        navigationItem.rightBarButtonItem = barButton
        barButton.tintColor = .label
        navigationController?.navigationBar.tintColor = .label
        toggleDescButton.tintColor = .label

        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        
        [imageView, statsCard, descCard].forEach { content.addArrangedSubview($0) }
        view.addSubview(scroll); scroll.addSubview(content)
        [scroll, content].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        // Card common style
        func styleCard(_ v: UIView) {
            v.backgroundColor = .secondarySystemBackground
            v.layer.cornerRadius = 12
            v.layer.cornerCurve = .continuous
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        
        styleCard(statsCard)
        statsStack.axis = .vertical
        statsStack.spacing = 8
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(statsStack)
        
        // Helper to build a row with left title and right value label or view
        func makeRow(titleLabel: UILabel, valueView: UIView) -> UIView {
            titleLabel.font = .preferredFont(forTextStyle: .subheadline)
            titleLabel.textColor = .secondaryLabel
            // Common style for value labels
            if let v = valueView as? UILabel {
                v.font = .preferredFont(forTextStyle: .headline)
                v.textAlignment = .right
                // Do not let value labels stretch; we want them right next to the title with a small gap
                v.setContentHuggingPriority(.required, for: .horizontal)
                v.setContentCompressionResistancePriority(.required, for: .horizontal)
            } else if !(valueView is UIScrollView) {
                // For other value views (except the name marquee scroll), avoid stretching as well
                valueView.setContentHuggingPriority(.required, for: .horizontal)
                valueView.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            let row = UIStackView(arrangedSubviews: [titleLabel, valueView])
            row.axis = .horizontal
            row.alignment = .firstBaseline
            row.distribution = .fill
            row.spacing = 4 // fixed gap between title and value
            return row
        }
        
        priceTitleLabel.text = "Precio"
        changeTitleLabel.text = "Variación 24h"
        marketCapTitleLabel.text = "Market Cap"
        rangeTitleLabel.text = "Rango 24h"
        nameTitleLabel.text = "Nombre"
        tickerTitleLabel.text = "Ticker"
        
        // Build rows (Nombre with marquee scroll on the right)
        let nameRow = makeRow(titleLabel: nameTitleLabel, valueView: nameScroll)
        let tickerRow = makeRow(titleLabel: tickerTitleLabel, valueView: tickerLabel)
        [
            nameRow,
            tickerRow,
            makeRow(titleLabel: priceTitleLabel, valueView: priceLabel),
            makeRow(titleLabel: changeTitleLabel, valueView: changeLabel),
            makeRow(titleLabel: marketCapTitleLabel, valueView: marketCapLabel),
            makeRow(titleLabel: rangeTitleLabel, valueView: rangeLabel)
        ].forEach { statsStack.addArrangedSubview($0) }
        
        // Constraints for statsStack inside statsCard
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 12),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 12),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -12),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -12)
        ])
        
        // Description card
        styleCard(descCard)
        descLabel.font = .preferredFont(forTextStyle: .body)
        descLabel.numberOfLines = 10
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleDescButton.setTitle("Ver más", for: .normal)
        toggleDescButton.addTarget(self, action: #selector(toggleDescription), for: .touchUpInside)
        toggleDescButton.translatesAutoresizingMaskIntoConstraints = false
        
        let descStack = UIStackView(arrangedSubviews: [descLabel, toggleDescButton])
        descStack.axis = .vertical
        descStack.spacing = 8
        descStack.translatesAutoresizingMaskIntoConstraints = false
        descCard.addSubview(descStack)
        NSLayoutConstraint.activate([
            descStack.topAnchor.constraint(equalTo: descCard.topAnchor, constant: 12),
            descStack.leadingAnchor.constraint(equalTo: descCard.leadingAnchor, constant: 12),
            descStack.trailingAnchor.constraint(equalTo: descCard.trailingAnchor, constant: -12),
            descStack.bottomAnchor.constraint(equalTo: descCard.bottomAnchor, constant: -12)
        ])
    }

    private func layout() {
        NSLayoutConstraint.activate([
            // Scroll attaches to the safe area via frameLayoutGuide
            scroll.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content lives in the contentLayoutGuide with padding
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            // Match widths accounting for horizontal padding
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
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
        let ui = viewModel.makeUIData(from: detail)

        navigationItem.title = ui.title

        nameLabel.text = ui.title
        tickerLabel.text = ui.symbol
        // Restart marquee if needed after layout
        view.layoutIfNeeded()
        startNameMarqueeIfNeeded()

        if let url = ui.imageURL {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "bitcoinsign.circle")
            )
        } else {
            imageView.image = UIImage(systemName: "bitcoinsign.circle")?.withRenderingMode(.alwaysTemplate)
        }

        // Stats mapping in the same order used by the ViewModel
        // Precio, Variación 24h, Market Cap, Rango 24h
        if ui.stats.indices.contains(0) { priceLabel.text = ui.stats[0].value }
        if ui.stats.indices.contains(1) {
            changeLabel.text = ui.stats[1].value
            let sign = ui.stats[1].changeSign
            changeLabel.textColor = sign == 0 ? .secondaryLabel : (sign > 0 ? .systemGreen : .systemRed)
        }
        if ui.stats.indices.contains(2) { marketCapLabel.text = ui.stats[2].value }
        if ui.stats.indices.contains(3) { rangeLabel.text = ui.stats[3].value }

        // Right bar button visibility
        homeURL = ui.homepage
        if homeURL == nil {
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.tintColor = .tertiaryLabel
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.tintColor = nil
        }

        // Description card
        if ui.hasDescription, let text = ui.description {
            descCard.isHidden = false
            descLabel.text = text
            isDescExpanded = false
            descLabel.numberOfLines = 10
            toggleDescButton.setTitle("Ver más", for: .normal)
        } else {
            descCard.isHidden = true
            descLabel.text = nil
        }
    }

    // MARK: - Error Toasts
    private enum ToastErrorKind: Error {
        case rateLimited
        case offline
        case message(String)
    }

    private func showError(_ error: ToastErrorKind) {
        let userMessage: String
        switch error {
        case .rateLimited:
            userMessage = "Has hecho demasiadas peticiones en poco tiempo. Espera unos segundos y vuelve a intentarlo."
        case .offline:
            userMessage = "Parece que no tienes conexión a internet."
        case .message(let msg):
            userMessage = msg.isEmpty ? "Ocurrió un problema al cargar los datos." : msg
        }
        toast.show(message: userMessage)
    }

    private func showError(_ message: String) {
        let lowered = message.lowercased()
        if message.contains("429") {
            showError(.rateLimited)
        } else if lowered.contains("offline") || lowered.contains("conexión") || lowered.contains("network") {
            showError(.offline)
        } else {
            showError(.message("Ocurrió un problema al cargar los datos."))
        }
    }

    @objc private func openLink() { if let url = homeURL { UIApplication.shared.open(url) } }
    
    @objc private func toggleDescription() {
        isDescExpanded.toggle()
        descLabel.numberOfLines = isDescExpanded ? 0 : 10
        toggleDescButton.setTitle(isDescExpanded ? "Ver menos" : "Ver más", for: .normal)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure marquee recalculates on rotations/size changes
        startNameMarqueeIfNeeded()
    }

    private func startNameMarqueeIfNeeded() {
        // Stop any existing animation
        nameMarqueeAnimator?.stopAnimation(true)
        nameMarqueeAnimator = nil
        let labelWidth = nameLabel.intrinsicContentSize.width
        let visibleWidth = nameScroll.bounds.width
        guard labelWidth > 0, visibleWidth > 0, labelWidth > visibleWidth else {
            nameScroll.setContentOffset(.zero, animated: false)
            return
        }
        let distance = labelWidth - visibleWidth
        let duration = max(4.0, min(10.0, Double(distance / 30.0)))
        nameScroll.setContentOffset(.zero, animated: false)
        let forward = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            self.nameScroll.contentOffset.x = distance
        }
        forward.addCompletion { _ in
            let backward = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                self.nameScroll.contentOffset.x = 0
            }
            backward.addCompletion { _ in
                // Loop
                self.startNameMarqueeIfNeeded()
            }
            self.nameMarqueeAnimator = backward
            backward.startAnimation(afterDelay: 0.8)
        }
        nameMarqueeAnimator = forward
        forward.startAnimation(afterDelay: 0.8)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nameMarqueeAnimator?.stopAnimation(true)
        nameMarqueeAnimator = nil
    }
}
