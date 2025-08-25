//
//  SettingsSheetViewModel.swift
//  CryptoTracker
//
//  Created by Jesus on 23/8/25.
//

import UIKit

/// App-wide theme options. `system` is the default.
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    /// Display title for UI.
    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// Corresponding UI style for the app window.
    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// Delegate to notify UI about theme updates.
protocol SettingsSheetViewModelDelegate: AnyObject {
    func didUpdateTheme(_ theme: AppTheme)
}

/// Handles settings business logic and state.
final class SettingsSheetViewModel {

    // MARK: - Delegate
    weak var delegate: SettingsSheetViewModelDelegate?

    // MARK: - Theme State
    /// Current selected theme, persisted in UserDefaults.
    var selectedTheme: AppTheme {
        get {
            if let raw = UserDefaults.standard.string(forKey: "appTheme"),
               let theme = AppTheme(rawValue: raw) {
                return theme
            }
            return .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appTheme")
            delegate?.didUpdateTheme(newValue)
        }
    }

    /// All available themes.
    var availableThemes: [AppTheme] { AppTheme.allCases }
}
