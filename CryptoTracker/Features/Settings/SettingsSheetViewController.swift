//
//  SettingsSheetViewController.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

// El ViewController se encarga de la presentación de la UI.
class SettingsSheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SettingsSheetViewModelDelegate {
    
    // Instancia del ViewModel.
    private let viewModel = SettingsSheetViewModel()
    
    // Crea un UITableView para mostrar las opciones.
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Un botón para cerrar la hoja.
    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        return button
    }()

    // Crea un UILabel para la sección de apariencia.
    private let appearanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Apariencia"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configura la vista y el ViewModel.
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
        // Configura el título y el botón de cerrar.
        title = "Settings"
        navigationItem.rightBarButtonItem = closeButton
        
        // Cambia el color de fondo de la vista principal.
        view.backgroundColor = .systemGroupedBackground
        
        // El color del fondo de la tabla es el mismo que el de la vista principal.
        tableView.backgroundColor = .systemGroupedBackground
        
        // Configura la tabla.
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "themeCell")
        
        // Añade la etiqueta y la tabla a la vista.
        view.addSubview(appearanceLabel)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // Restricciones para la etiqueta
            appearanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            appearanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            appearanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Restricciones para la tabla
            tableView.topAnchor.constraint(equalTo: appearanceLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupViewModel() {
        // Asigna el ViewController como delegado del ViewModel.
        viewModel.delegate = self
    }
    
    // Llama a este método para cambiar el tema de la aplicación.
    // Esto se puede llamar desde cualquier lugar de la app.
    private func applyTheme(_ theme: AppTheme) {
        let window = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow }).first
        
        // Cambia el estilo de la interfaz de usuario de la ventana.
        switch theme {
        case .system:
            window?.overrideUserInterfaceStyle = .unspecified
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.availableThemes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "themeCell", for: indexPath)
        
        let theme = viewModel.availableThemes[indexPath.row]
        cell.textLabel?.text = theme.rawValue
        
        // Configura el accesorio para mostrar si el tema está seleccionado.
        if viewModel.selectedTheme == theme {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Retorna nil para remover el título del encabezado del grupo de la tabla.
        return nil
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Obtiene el tema seleccionado y lo actualiza en el ViewModel.
        let newTheme = viewModel.availableThemes[indexPath.row]
        viewModel.selectedTheme = newTheme
        
        // Recarga la tabla para actualizar la marca de verificación.
        tableView.reloadData()
    }
    
    // MARK: - SettingsSheetViewModelDelegate
    
    func didUpdateTheme(_ theme: AppTheme) {
        // Aplica el nuevo tema a la aplicación.
        applyTheme(theme)
    }
}
