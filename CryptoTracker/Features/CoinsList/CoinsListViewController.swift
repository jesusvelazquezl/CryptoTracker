//
//  CoinsListViewController.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import UIKit

private enum ListItem: Hashable {
    case header
    case coin(Coin)
    case loading
}

final class CoinsListViewController: UIViewController, UICollectionViewDelegate {

    // MARK: - UI
    private var collectionView: UICollectionView!
    private lazy var dataSource = makeDataSource()
    private let refreshControl = UIRefreshControl()
    private var toast: ToastErrorPresenter!

    // Empty state overlay (shown only when API returns OK but there are no coins)
    private lazy var emptyView: EmptyStateView = {
        let v = EmptyStateView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    // MARK: - State
    private let viewModel: CoinsListViewModel
    private let onSelect: (Coin) -> Void
    enum Section { case main }

    // MARK: - Init
    init(viewModel: CoinsListViewModel, onSelect: @escaping (Coin) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Toast with standard theme on list (detail uses .card)
        toast = ToastErrorPresenter(hostView: view)

        // Title
        title = "CoinGecko"

        // Small titles only (no large titles)
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline).withSize(20)
        ]

        // Transparent navigation bar (no blur)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil

        if let attributes = navigationController?.navigationBar.titleTextAttributes {
            appearance.titleTextAttributes = attributes
        }

        if let navBar = navigationController?.navigationBar {
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance
            navBar.isTranslucent = true
        }

        navigationController?.view.backgroundColor = .systemBackground

        // Right button (gear) with same tint as detail
        let gearItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
        navigationItem.rightBarButtonItem = gearItem
        gearItem.tintColor = .label
        navigationController?.navigationBar.tintColor = .label

        setupCollectionView()

        // Empty overlay above the collectionView (same margins)
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bindViewModel()
        Task { await viewModel.load() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "CoinGecko"
    }

    // MARK: - Setup

    private func setupCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: config)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self

        collectionView.register(CoinListCell.self, forCellWithReuseIdentifier: CoinListCell.reuseID)
        collectionView.register(LoadingCollectionCell.self, forCellWithReuseIdentifier: LoadingCollectionCell.reuseIdentifier)
        collectionView.register(HeaderCollectionCell.self, forCellWithReuseIdentifier: HeaderCollectionCell.reuseIdentifier)

        collectionView.refreshControl = refreshControl
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false

        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                self.refreshControl.beginRefreshing()
                self.hideEmptyList()
            case .loaded(let coins):
                self.applySnapshot(coins, showLoading: false)
                self.refreshControl.endRefreshing()
                if coins.isEmpty {
                    self.showEmptyList()
                } else {
                    self.hideEmptyList()
                }
            case .failed(let message):
                self.refreshControl.endRefreshing()
                // Do not show empty on failures; empty is only for OK-but-empty responses
                self.showError(message)
            }
        }

        viewModel.onPagingChange = { [weak self] isLoading in
            guard let self else { return }
            self.applySnapshot(self.viewModel.coins, showLoading: isLoading, animating: true)
        }
    }

    // MARK: - Actions

    @objc private func didPullToRefresh() {
        Task { await viewModel.refresh() }
    }

    @objc private func didTapSettings() {
        let vc = SettingsSheetViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        present(nav, animated: true)
    }

    // MARK: - Data Source

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, ListItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .header:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: HeaderCollectionCell.reuseIdentifier,
                    for: indexPath
                ) as! HeaderCollectionCell
                cell.configure()
                return cell

            case .coin(let coin):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CoinListCell.reuseID,
                    for: indexPath
                ) as! CoinListCell
                cell.configure(coin: coin)
                return cell

            case .loading:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LoadingCollectionCell.reuseIdentifier,
                    for: indexPath
                ) as! LoadingCollectionCell
                cell.startAnimating()
                return cell
            }
        }
    }

    // MARK: - Snapshot

    private func applySnapshot(_ items: [Coin], showLoading: Bool = false, animating: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()
        snapshot.appendSections([.main])
        if !items.isEmpty { snapshot.appendItems([.header]) }
        snapshot.appendItems(items.map { ListItem.coin($0) })
        if showLoading { snapshot.appendItems([.loading]) }

        dataSource.apply(snapshot, animatingDifferences: animating)

        // Reconfigure ONLY the last visible cell (updates rounded corners after pagination)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let last = items.count - 1
            guard last >= 0 else { return }
            let uiIndexLast = last + 1 // +1 due to header at 0

            let lastIndexPath = IndexPath(item: uiIndexLast, section: 0)
            guard self.collectionView.indexPathsForVisibleItems.contains(lastIndexPath) else { return }
            guard let identifier = self.dataSource.itemIdentifier(for: lastIndexPath) else { return }

            var snap = self.dataSource.snapshot()
            snap.reconfigureItems([identifier])
            self.dataSource.apply(snap, animatingDifferences: false)
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
            userMessage = "You’ve made too many requests. Please wait a few seconds and try again."
        case .offline:
            userMessage = "Looks like you’re offline."
        case .message(let msg):
            userMessage = msg.isEmpty ? "There was a problem loading more data." : msg
        }
        toast.show(message: userMessage)
    }

    private func showError(_ message: String) {
        let lowered = message.lowercased()
        if message.contains("429") {
            showError(.rateLimited)
        } else if lowered.contains("offline") || lowered.contains("conexión") || lowered.contains("network") || lowered.contains("connection") {
            showError(.offline)
        } else {
            showError(.message("There was a problem loading more data."))
        }
    }

    // MARK: - Collection Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath),
           case let .coin(coin) = item {
            onSelect(coin)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Convert displayed index (including header) to coin index
        let coinIndex = max(0, indexPath.item - 1)
        Task { await viewModel.loadNextPageIfNeeded(currentIndex: coinIndex) }
    }

    // MARK: - Empty State

    private func showEmptyList() {
        emptyView.configure(title: "No Results", subtitle: "There’s nothing to show right now.")
        emptyView.isHidden = false
    }

    private func hideEmptyList() {
        emptyView.isHidden = true
    }
}
