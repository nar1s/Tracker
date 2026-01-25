//
//  AppDelegate.swift
//  Tracker
//
//  Created by Павел Кузнецов on 24.01.2026.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(
              name: "Main",
              sessionRole: connectingSceneSession.role
          )
          sceneConfiguration.delegateClass = SceneDelegate.self
          return sceneConfiguration
    }
    
}

