//
//  TabBarViewController.swift
//  Tracker
//
//  Created by Павел Кузнецов on 25.01.2026.
//

import UIKit

final class TabBarViewController: UITabBarController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupViewControllers()
    }

    // MARK: - Setup

    private func setupViewControllers() {
        let trackersListViewController = TrackersListViewController()
        let trackersNavigationController = UINavigationController(rootViewController: trackersListViewController)
        
        trackersNavigationController.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tabBar.trackers", comment: ""),
            image: UIImage(resource: .tabTrackers),
            selectedImage: nil
        )

        let statisticsViewController = StatisticsViewController()

        statisticsViewController.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tabBar.statistics", comment: ""),
            image: UIImage(resource: .tabStatistics),
            selectedImage: nil
        )

        viewControllers = [trackersNavigationController, statisticsViewController]
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .ypWhite)

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(resource: .ypBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(resource: .ypBlue)]

        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}

