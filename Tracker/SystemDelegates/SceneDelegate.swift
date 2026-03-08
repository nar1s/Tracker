//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Павел Кузнецов on 24.01.2026.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: scene)
        
        let hasSeenOnboarding = UserDefaultsService.shared.hasSeenOnboarding
        window?.rootViewController = hasSeenOnboarding ? TabBarViewController() : OnboardingViewController()
        window?.makeKeyAndVisible()
    }
    
}

