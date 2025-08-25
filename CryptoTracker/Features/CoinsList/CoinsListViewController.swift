//
//  CoinsListViewController.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import UIKit

private enum Item: Hashable {
    case header
    case coin(Coin)
    case loading
}

final class CoinsListViewController: UIViewController, UICollectionViewDelegate {
    private var collectionView: UICollectionView!
    private lazy var dataSource = makeDataSource()
    private let refresh = UIRefreshControl()
    private var toast: ToastErrorPresenter!

    private let viewModel: CoinsListViewModel
    private let onSelect: (Coin) -> Void

    // Empty state overlay (only shown when API returns OK but no coins and the list is currently empty)
    private lazy var emptyView: EmptyStateView = {
        let v = EmptyStateView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    enum Section { case main }

    init(viewModel: CoinsListViewModel, onSelect: @escaping (Coin) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        toast = ToastErrorPresenter(hostView: view)
        title = "coingecko"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline).withSize(20)
        ]
        // NAVBAR: completamente transparente (sin blur)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = navigationController?.navigationBar.titleTextAttributes ?? [:]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        // Botón de ajustes (engranaje)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
        setupCollection()
        // Empty overlay above the collectionView (same margins)
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        bind()
        Task { await viewModel.load() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "coingecko"
    }

    private func setupCollection() {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.register(CoinListCell.self, forCellWithReuseIdentifier: CoinListCell.reuseID)
        collectionView.register(LoadingCollectionCell.self, forCellWithReuseIdentifier: LoadingCollectionCell.reuseID)
        collectionView.register(HeaderCollectionCell.self, forCellWithReuseIdentifier: HeaderCollectionCell.reuseID)
        collectionView.refreshControl = refresh
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        // Removed contentInset and insetsLayoutMarginsFromSafeArea for outer spacing
        refresh.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                self.refresh.beginRefreshing()
                self.hideEmptyList()
            case .loaded(let coins):
                self.applySnapshot(coins, showLoading: false)
                self.refresh.endRefreshing()
                if coins.isEmpty {
                    self.showEmptyList()
                } else {
                    self.hideEmptyList()
                }
            case .failed(let message):
                self.refresh.endRefreshing()
                // Do not show empty on failures; empty is only for OK-but-empty responses
                self.showError(message)
            }
        }
        viewModel.onPagingChange = { [weak self] isLoading in
            guard let self = self else { return }
            self.applySnapshot(self.viewModel.coins, showLoading: isLoading, animating: true)
        }
    }

    @objc private func didPullToRefresh() {
        Task { await viewModel.refresh() }
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .header:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeaderCollectionCell.reuseID, for: indexPath) as! HeaderCollectionCell
                cell.configure()
                return cell
            case .coin(let coin):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CoinListCell.reuseID, for: indexPath) as! CoinListCell
                cell.configure(coin: coin)
                return cell
            case .loading:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCollectionCell.reuseID, for: indexPath) as! LoadingCollectionCell
                cell.startAnimating()
                return cell
            }
        }
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

    private func applySnapshot(_ items: [Coin], showLoading: Bool = false, animating: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        if !items.isEmpty {
            snapshot.appendItems([.header])
        }
        snapshot.appendItems(items.map { Item.coin($0) })
        if showLoading {
            snapshot.appendItems([.loading])
        }
        dataSource.apply(snapshot, animatingDifferences: animating)

        // Reconfigura SOLO la última celda si está visible (para actualizar esquinas tras paginación)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let last = items.count - 1
            guard last >= 0 else { return }
            let uiIndexLast = last + 1 // +1 por el header en 0

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
            userMessage = "Has hecho demasiadas peticiones en poco tiempo. Espera unos segundos y vuelve a intentarlo."
        case .offline:
            userMessage = "Parece que no tienes conexión a internet."
        case .message(let msg):
            userMessage = msg.isEmpty ? "Ocurrió un problema al cargar más datos." : msg
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
            showError(.message("Ocurrió un problema al cargar más datos."))
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            if case let .coin(coin) = item {
                onSelect(coin)
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Subtract 1 to convert from displayed index (including header) to coin index
        let coinIndex = max(0, indexPath.item - 1)
        Task { await viewModel.loadNextPageIfNeeded(currentIndex: coinIndex) }
    }

    private func showEmptyList() {
        emptyView.configure(title: "Sin resultados", subtitle: "No hay elementos para mostrar ahora mismo.")
        emptyView.isHidden = false
    }

    private func hideEmptyList() {
        emptyView.isHidden = true
    }
}
