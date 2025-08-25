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

    // Empty/Error state overlay (reutilizada como vacío o error)
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

        // Empty/Error overlay above the collectionView (same margins)
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

            case .failed(let rawMessage):
                self.refreshControl.endRefreshing()

                // Resolver tipo y mensaje de error para toasts y overlays
                let (kind, userMessage) = self.resolveToast(from: rawMessage)

                // Mostrar toast siempre
                self.toast.show(message: userMessage)

                // Si no hay datos cargados, mostrar overlay acorde a la casuística
                if self.viewModel.coins.isEmpty {
                    switch kind {
                    case .rateLimited:
                        // Casuística 1: límite de solicitudes -> vista de vacío + toast
                        self.showEmptyList()
                    case .offline, .message:
                        // Casuística 2: error API distinto a 429 -> pantalla de error
                        self.showErrorOverlay(userMessage)
                    }
                } else {
                    // Con lista previa, no forzamos overlays; mantenemos la lista y el toast
                    self.hideEmptyList()
                }
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

    /// Deduplica preservando el orden de aparición.
    private func uniqueCoins(_ coins: [Coin]) -> [Coin] {
        var seen = Set<Coin>()
        var result: [Coin] = []
        result.reserveCapacity(coins.count)
        for c in coins {
            if seen.insert(c).inserted {
                result.append(c)
            }
        }
        return result
    }

    private func applySnapshot(_ items: [Coin], showLoading: Bool = false, animating: Bool = true) {
        // 1) Asegurar que no hay duplicados para evitar "Duplicate identifiers"
        let coins = uniqueCoins(items)

        // 2) Construir la lista de identificadores (ListItem) y deduplicarla por si acaso
        var list: [ListItem] = []
        if !coins.isEmpty { list.append(.header) }
        list.append(contentsOf: coins.map { ListItem.coin($0) })
        if showLoading { list.append(.loading) }

        var seen = Set<ListItem>()
        let uniqueList = list.filter { seen.insert($0).inserted }

        // 3) Aplicar snapshot con elementos únicos
        var snapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(uniqueList)
        dataSource.apply(snapshot, animatingDifferences: animating)

        // 4) Reconfigurar SOLO la última celda de coin visible (tras paginación) usando la lista única
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Buscar el último índice de un .coin en uniqueList
            guard let lastCoinPosition = uniqueList.lastIndex(where: {
                if case .coin = $0 { return true } else { return false }
            }) else {
                return
            }

            let lastIndexPath = IndexPath(item: lastCoinPosition, section: 0)
            guard self.collectionView.indexPathsForVisibleItems.contains(lastIndexPath) else { return }
            guard let identifier = self.dataSource.itemIdentifier(for: lastIndexPath) else { return }

            var snap = self.dataSource.snapshot()
            snap.reconfigureItems([identifier])
            self.dataSource.apply(snap, animatingDifferences: false)
        }
    }

    // MARK: - Error Toasts & Resolution

    private enum ToastErrorKind: Error {
        case rateLimited
        case offline
        case message(String)
    }

    /// Resuelve el tipo de error y el mensaje de usuario a partir del mensaje crudo.
    private func resolveToast(from raw: String) -> (ToastErrorKind, String) {
        let lowered = raw.lowercased()
        if raw.contains("429") {
            return (.rateLimited, String(localized: "detail.error.rate_limited"))
        } else if lowered.contains("offline")
                    || lowered.contains("conexión")
                    || lowered.contains("conexion")
                    || lowered.contains("network")
                    || lowered.contains("connection") {
            return (.offline, String(localized: "detail.error.offline"))
        } else {
            return (.message(String(localized: "error.generic.data")),
                    String(localized: "error.generic.data"))
        }
    }

    /// Mantiene compatibilidad con usos existentes (muestra toast únicamente).
    private func showError(_ message: String) {
        let (_, userMessage) = resolveToast(from: message)
        toast.show(message: userMessage)
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

    // MARK: - Empty/Error State

    private func showEmptyList() {
        emptyView.configure(
            title: String(localized: "empty.no_results.title"),
            subtitle: String(localized: "empty.no_results.subtitle")
        )
        emptyView.isHidden = false
    }

    /// Muestra overlay de error reutilizando EmptyStateView con un mensaje de error.
    /// El título usa el mensaje de usuario resuelto (p.ej. rate limit, offline, genérico).
    private func showErrorOverlay(_ message: String) {
        emptyView.configure(
            title: message,
            // Reutilizamos el subtítulo genérico de “no resultados” si no hay uno específico.
            // Si dispones de claves de localización específicas de error, cámbialas aquí.
            subtitle: String(localized: "empty.no_results.subtitle")
        )
        emptyView.isHidden = false
    }

    private func hideEmptyList() {
        emptyView.isHidden = true
    }
}
