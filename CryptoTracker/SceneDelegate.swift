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

        // Theme (single line using AppTheme.uiStyle)
        let saved = UserDefaults.standard.string(forKey: "appTheme")
        let theme = saved.flatMap(AppTheme.init(rawValue:)) ?? .system
        window.overrideUserInterfaceStyle = theme.uiStyle

        // Root navigation
        let nav = UINavigationController()
        nav.navigationBar.prefersLargeTitles = false
        nav.navigationBar.tintColor = .label

        // Dependencies
        let api = APIClient()
        let repo = CoinGeckoRepository(apiClient: api)

        // Root list
        let listVM = CoinsListViewModel(repository: repo)
        let listVC = CoinsListViewController(viewModel: listVM) { [weak nav] coin in
            let detailVM = CoinDetailViewModel(repository: repo, coinID: coin.id, initialCoin: coin)
            let detailVC = CoinDetailViewController(viewModel: detailVM)
            nav?.pushViewController(detailVC, animated: true)
        }

        nav.viewControllers = [listVC]
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}

