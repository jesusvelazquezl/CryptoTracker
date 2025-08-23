//
//  SettingsSheetViewModel.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

// Define un enum para los diferentes temas de la aplicación.
// 'system' es el valor por defecto.
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }
    
    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// Define un protocolo para que el ViewModel se comunique con el ViewController.
protocol SettingsSheetViewModelDelegate: AnyObject {
    func didUpdateTheme(_ theme: AppTheme)
}

// El ViewModel gestiona la lógica de negocio y el estado de la vista.
class SettingsSheetViewModel {
    
    // Delega las actualizaciones al ViewController.
    weak var delegate: SettingsSheetViewModelDelegate?
    
    // Almacena el tema actualmente seleccionado.
    var selectedTheme: AppTheme {
        // Lee el valor del tema desde UserDefaults.
        get {
            if let rawValue = UserDefaults.standard.string(forKey: "appTheme"),
               let theme = AppTheme(rawValue: rawValue) {
                return theme
            }
            return .system // Valor por defecto si no hay nada guardado.
        }
        // Guarda el nuevo tema en UserDefaults y notifica al delegado.
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appTheme")
            delegate?.didUpdateTheme(newValue)
        }
    }
    
    // Proporciona una lista de todos los temas disponibles.
    var availableThemes: [AppTheme] {
        return AppTheme.allCases
    }
}
