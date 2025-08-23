//
//  SceneDelegate.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let nav = UINavigationController()
        nav.navigationBar.prefersLargeTitles = true

        if let savedThemeRawValue = UserDefaults.standard.string(forKey: "appTheme"),
           let savedTheme = AppTheme(rawValue: savedThemeRawValue) {
            
            switch savedTheme {
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            }
        }

        // Inyección de dependencias
        let api = APIClient()
        let repo = CoinGeckoRepository(apiClient: api)
        let listVM = CoinsListViewModel(repository: repo)
        let listVC = CoinsListViewController(viewModel: listVM) { coin in
            let detailVM = CoinDetailViewModel(repository: repo, coinID: coin.id, initialCoin: coin)
            let detailVC = CoinDetailViewController(viewModel: detailVM)
            nav.pushViewController(detailVC, animated: true)
        }

        nav.viewControllers = [listVC]
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}

