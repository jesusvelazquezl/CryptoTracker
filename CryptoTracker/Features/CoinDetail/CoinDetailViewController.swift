//
//  CoinDetailViewController.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import UIKit
import Kingfisher

final class CoinDetailViewController: UIViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var toast: ToastErrorPresenter!

    private let imageView = UIImageView()

    // Name & Symbol
    private let nameTitleLabel = UILabel()
    private let symbolTitleLabel = UILabel()
    private let nameScrollView = UIScrollView()
    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private var nameMarqueeAnimator: UIViewPropertyAnimator?

    // Cards & stacks
    private let statsCard = UIView()
    private let statsStack = UIStackView()

    private let descriptionCard = UIView()
    private let descriptionLabel = UILabel()
    private let toggleDescriptionButton = UIButton(type: .system)
    private var isDescriptionExpanded = false

    // Row title labels
    private let priceTitleLabel = UILabel()
    private let changeTitleLabel = UILabel()
    private let marketCapTitleLabel = UILabel()
    private let rangeTitleLabel = UILabel()

    // Row value labels
    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let marketCapLabel = UILabel()
    private let rangeLabel = UILabel()

    private let linkButton = UIButton(type: .system)

    // MARK: - State

    private let viewModel: CoinDetailViewModel
    private var homepageURL: URL?

    // MARK: - Init

    init(viewModel: CoinDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // Use the card theme so the toast contrasts with the white background.
        toast = ToastErrorPresenter(hostView: view, theme: .card)

        setupViews()
        setupConstraints()
        bindViewModel()

        apply(viewModel.placeholder)

        Task { await viewModel.load() }

        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        // Accessibility: explicit label for website button
        if let barButton = navigationItem.rightBarButtonItem {
            barButton.accessibilityLabel = String(localized: "detail.accessibility.open_website")
            barButton.accessibilityHint = String(localized: "detail.accessibility.opens_external_browser")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Recalculate marquee on rotations/size changes
        updateNameMarqueeIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nameMarqueeAnimator?.stopAnimation(true)
        nameMarqueeAnimator = nil
    }

    // MARK: - Setup

    private func setupViews() {
        contentStack.axis = .vertical
        contentStack.spacing = 12

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        // Accessibility for image
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits.insert(.image)
        imageView.accessibilityLabel = String(localized: "detail.accessibility.logo")

        // Name marquee
        nameScrollView.showsHorizontalScrollIndicator = false
        nameScrollView.showsVerticalScrollIndicator = false
        nameScrollView.isScrollEnabled = false
        nameScrollView.translatesAutoresizingMaskIntoConstraints = false
        // Accessibility: expose only the label, not the scroll container
        nameScrollView.isAccessibilityElement = false
        nameLabel.isAccessibilityElement = true
        nameLabel.accessibilityTraits.insert(.header)

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.lineBreakMode = .byClipping
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textAlignment = .right
        nameScrollView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: nameScrollView.contentLayoutGuide.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: nameScrollView.contentLayoutGuide.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: nameScrollView.contentLayoutGuide.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: nameScrollView.contentLayoutGuide.bottomAnchor),
            nameLabel.heightAnchor.constraint(equalTo: nameScrollView.frameLayoutGuide.heightAnchor),
            nameLabel.widthAnchor.constraint(greaterThanOrEqualTo: nameScrollView.frameLayoutGuide.widthAnchor)
        ])

        // Right bar button (globe) for website
        let globeImage = UIImage(systemName: "globe")
        let barButton = UIBarButtonItem(image: globeImage, style: .plain, target: self, action: #selector(openLink))
        navigationItem.rightBarButtonItem = barButton
        barButton.tintColor = .label
        navigationController?.navigationBar.tintColor = .label
        toggleDescriptionButton.tintColor = .label

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        [imageView, statsCard, descriptionCard].forEach { contentStack.addArrangedSubview($0) }
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        [scrollView, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // Card styling
        func styleCard(_ v: UIView) {
            v.backgroundColor = .secondarySystemBackground
            v.layer.cornerRadius = 12
            v.layer.cornerCurve = .continuous
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        // Stats card
        styleCard(statsCard)
        statsStack.axis = .vertical
        statsStack.spacing = 8
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(statsStack)

        // Row builder (left title, right value)
        func makeRow(titleLabel: UILabel, valueView: UIView) -> UIView {
            titleLabel.font = .preferredFont(forTextStyle: .subheadline)
            titleLabel.textColor = .secondaryLabel

            if let v = valueView as? UILabel {
                v.font = .preferredFont(forTextStyle: .headline)
                v.textAlignment = .right
                v.setContentHuggingPriority(.required, for: .horizontal)
                v.setContentCompressionResistancePriority(.required, for: .horizontal)
            } else if !(valueView is UIScrollView) {
                valueView.setContentHuggingPriority(.required, for: .horizontal)
                valueView.setContentCompressionResistancePriority(.required, for: .horizontal)
            }

            let row = UIStackView(arrangedSubviews: [titleLabel, valueView])
            row.axis = .horizontal
            row.alignment = .firstBaseline
            row.distribution = .fill
            row.spacing = 4 // fixed gap between title and value
            // Accessibility: hide title from VO and assign its meaning to the value
            titleLabel.isAccessibilityElement = false
            if let v = valueView as? UILabel {
                v.isAccessibilityElement = true
                v.accessibilityLabel = titleLabel.text
            } else if let v = valueView as? UIScrollView {
                v.isAccessibilityElement = false
                // the nested label handles accessibility (e.g., nameLabel)
            } else {
                valueView.isAccessibilityElement = true
                valueView.accessibilityLabel = titleLabel.text
            }
            return row
        }

        // Titles
        nameTitleLabel.text = String(localized: "detail.name.title")
        symbolTitleLabel.text = String(localized: "detail.symbol.title")
        priceTitleLabel.text = String(localized: "detail.price.title")
        changeTitleLabel.text = String(localized: "detail.change24h.title")
        marketCapTitleLabel.text = String(localized: "detail.marketcap.title")
        rangeTitleLabel.text = String(localized: "detail.range24h.title")

        // Rows
        let nameRow = makeRow(titleLabel: nameTitleLabel, valueView: nameScrollView)
        let symbolRow = makeRow(titleLabel: symbolTitleLabel, valueView: symbolLabel)
        [
            nameRow,
            symbolRow,
            makeRow(titleLabel: priceTitleLabel, valueView: priceLabel),
            makeRow(titleLabel: changeTitleLabel, valueView: changeLabel),
            makeRow(titleLabel: marketCapTitleLabel, valueView: marketCapLabel),
            makeRow(titleLabel: rangeTitleLabel, valueView: rangeLabel)
        ].forEach { statsStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 12),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 12),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -12),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -12)
        ])

        // Description card
        styleCard(descriptionCard)
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 10
        descriptionLabel.textColor = .label
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        toggleDescriptionButton.setTitle(String(localized: "detail.description.show_more"), for: .normal)
        toggleDescriptionButton.addTarget(self, action: #selector(toggleDescriptionExpansion), for: .touchUpInside)
        toggleDescriptionButton.translatesAutoresizingMaskIntoConstraints = false
        // Accessibility for description toggle
        toggleDescriptionButton.accessibilityHint = String(localized: "detail.accessibility.toggle_description_hint")

        let descriptionStack = UIStackView(arrangedSubviews: [descriptionLabel, toggleDescriptionButton])
        descriptionStack.axis = .vertical
        descriptionStack.spacing = 8
        descriptionStack.translatesAutoresizingMaskIntoConstraints = false
        descriptionCard.addSubview(descriptionStack)
        NSLayoutConstraint.activate([
            descriptionStack.topAnchor.constraint(equalTo: descriptionCard.topAnchor, constant: 12),
            descriptionStack.leadingAnchor.constraint(equalTo: descriptionCard.leadingAnchor, constant: 12),
            descriptionStack.trailingAnchor.constraint(equalTo: descriptionCard.trailingAnchor, constant: -12),
            descriptionStack.bottomAnchor.constraint(equalTo: descriptionCard.bottomAnchor, constant: -12)
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll attaches to the view via frameLayoutGuide
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content inside contentLayoutGuide with padding
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            // Match widths accounting for horizontal padding
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .loading:
                break
            case .loaded(let detail):
                self.apply(detail)
            case .failed(let message):
                self.showError(message)
            }
        }
    }

    // MARK: - Apply UI

    private func apply(_ detail: CoinDetail) {
        let ui = viewModel.buildUIModel(from: detail)

        navigationItem.title = ui.title

        nameLabel.text = ui.title
        symbolLabel.text = ui.symbol
        view.layoutIfNeeded()
        updateNameMarqueeIfNeeded()
        // Accessibility: enrich stats for VoiceOver
        if ui.stats.indices.contains(0) { // price
            priceLabel.accessibilityValue = ui.stats[0].value
        }
        if ui.stats.indices.contains(1) {
            let stat = ui.stats[1]
            changeLabel.accessibilityValue = stat.value
        }
        if ui.stats.indices.contains(2) {
            marketCapLabel.accessibilityValue = ui.stats[2].value
        }
        if ui.stats.indices.contains(3) {
            rangeLabel.accessibilityValue = ui.stats[3].value
        }

        if let url = ui.imageURL {
            imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "bitcoinsign.circle"))
        } else {
            imageView.image = UIImage(systemName: "bitcoinsign.circle")?.withRenderingMode(.alwaysTemplate)
        }

        // Stats mapping in the same order provided by the ViewModel
        if ui.stats.indices.contains(0) { priceLabel.text = ui.stats[0].value }
        if ui.stats.indices.contains(1) {
            let stat = ui.stats[1]
            changeLabel.text = stat.value
            changeLabel.textColor =
                stat.changeSign > 0 ? .systemGreen :
                stat.changeSign < 0 ? .systemRed :
                .secondaryLabel
        }
        if ui.stats.indices.contains(2) { marketCapLabel.text = ui.stats[2].value }
        if ui.stats.indices.contains(3) { rangeLabel.text = ui.stats[3].value }

        // Right bar button visibility
        homepageURL = ui.homepage
        if homepageURL == nil {
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.tintColor = .tertiaryLabel
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.tintColor = nil
        }
        navigationItem.rightBarButtonItem?.accessibilityLabel = String(localized: "detail.accessibility.open_website")

        // Description card
        if ui.hasDescription, let text = ui.description {
            descriptionCard.isHidden = false
            descriptionLabel.text = text
            isDescriptionExpanded = false
            descriptionLabel.numberOfLines = 10
            toggleDescriptionButton.setTitle(String(localized: "detail.description.show_more"), for: .normal)
        } else {
            descriptionCard.isHidden = true
            descriptionLabel.text = nil
        }
        // Accessibility reading order
        self.view.accessibilityElements = [
            imageView,
            nameLabel,
            symbolLabel,
            statsCard,
            descriptionCard
        ]
    }

    // MARK: - Actions

    @objc private func openLink() {
        if let url = homepageURL { UIApplication.shared.open(url) }
    }

    @objc private func toggleDescriptionExpansion() {
        isDescriptionExpanded.toggle()
        descriptionLabel.numberOfLines = isDescriptionExpanded ? 0 : 10
        let title = isDescriptionExpanded
            ? String(localized: "detail.description.show_less")
            : String(localized: "detail.description.show_more")
        toggleDescriptionButton.setTitle(title, for: .normal)
        toggleDescriptionButton.accessibilityLabel = title
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - Marquee

    private func updateNameMarqueeIfNeeded() {
        nameMarqueeAnimator?.stopAnimation(true)
        nameMarqueeAnimator = nil

        // Respect Reduce Motion: disable marquee if user prefers reduced motion
        if UIAccessibility.isReduceMotionEnabled {
            nameScrollView.setContentOffset(.zero, animated: false)
            return
        }

        let labelWidth = nameLabel.intrinsicContentSize.width
        let visibleWidth = nameScrollView.bounds.width
        guard labelWidth > 0, visibleWidth > 0, labelWidth > visibleWidth else {
            nameScrollView.setContentOffset(.zero, animated: false)
            return
        }

        let distance = labelWidth - visibleWidth
        let duration = max(4.0, min(10.0, Double(distance / 30.0)))

        nameScrollView.setContentOffset(.zero, animated: false)

        let forward = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            self.nameScrollView.contentOffset.x = distance
        }
        forward.addCompletion { _ in
            let backward = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                self.nameScrollView.contentOffset.x = 0
            }
            backward.addCompletion { _ in
                // Loop
                self.updateNameMarqueeIfNeeded()
            }
            self.nameMarqueeAnimator = backward
            backward.startAnimation(afterDelay: 0.8)
        }
        nameMarqueeAnimator = forward
        forward.startAnimation(afterDelay: 0.8)
    }

    // MARK: - Error Toasts

    private enum ToastErrorKind: Error {
        case rateLimited
        case offline
        case message(String)
    }

    private func showError(_ error: ToastErrorKind) {
        let message: String
        switch error {
        case .rateLimited:
            message = String(localized: "detail.error.rate_limited")
        case .offline:
            message = String(localized: "detail.error.offline")
        case .message(let msg):
            message = msg.isEmpty ? String(localized: "detail.error.generic") : msg
        }
        toast.show(message: message)
    }

    private func showError(_ rawMessage: String) {
        let lowered = rawMessage.lowercased()
        if rawMessage.contains("429") {
            showError(.rateLimited)
        } else if lowered.contains("offline") || lowered.contains("connection") || lowered.contains("network") || lowered.contains("conexión") {
            showError(.offline)
        } else {
            showError(.message(String(localized: "detail.error.generic")))
        }
    }
}
