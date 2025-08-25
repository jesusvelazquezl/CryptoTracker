//
//  SettingsSheetViewController.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

final class SettingsSheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SettingsSheetViewModelDelegate {

    // MARK: - State
    private let viewModel = SettingsSheetViewModel()

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    /// Small caption above the table (minimal look)
    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "settings.appearance.header")
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .label
        return label
    }()

    /// Close button (top-right)
    private lazy var closeButton: UIBarButtonItem = {
        let action = UIAction { [weak self] _ in self?.dismiss(animated: true) }
        let button = UIBarButtonItem(systemItem: .close, primaryAction: action)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupViews()
        setupConstraints()
        setupViewModel()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = String(localized: "settings.title")

        navigationItem.rightBarButtonItem = closeButton
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .label
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground

        tableView.backgroundColor = .systemGroupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self

        // Minimal cell style
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "themeCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.sectionHeaderTopPadding = 0

        view.addSubview(sectionTitleLabel)
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        // Tight, consistent margins for a minimal look
        NSLayoutConstraint.activate([
            sectionTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupViewModel() {
        viewModel.delegate = self
    }

    // MARK: - Theme
    /// Apply the chosen theme to the whole app window.
    private func applyTheme(_ theme: AppTheme) {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow })

        window?.overrideUserInterfaceStyle = theme.uiStyle
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.availableThemes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "themeCell", for: indexPath)
        let theme = viewModel.availableThemes[indexPath.row]

        // Minimal cell text
        cell.textLabel?.text = theme.title
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.textColor = .label

        // Show checkmark for selected theme
        cell.accessoryType = (viewModel.selectedTheme == theme) ? .checkmark : .none
        cell.selectionStyle = .default

        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        // Update theme in ViewModel (persists + notifies delegate)
        let newTheme = viewModel.availableThemes[indexPath.row]
        guard newTheme != viewModel.selectedTheme else { return }

        viewModel.selectedTheme = newTheme

        // Refresh checkmarks (simple + robust)
        tableView.reloadData()
    }

    // MARK: - SettingsSheetViewModelDelegate
    func didUpdateTheme(_ theme: AppTheme) {
        applyTheme(theme)
    }
}
