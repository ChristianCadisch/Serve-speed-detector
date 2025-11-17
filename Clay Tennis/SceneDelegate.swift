/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's scene delegate.
*/

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        if !hasSeenOnboarding {
            // Show onboarding once
            let onboardingView = OnboardingView(hasSeenOnboarding: Binding(
                get: { UserDefaults.standard.bool(forKey: "hasSeenOnboarding") },
                set: { value in
                    UserDefaults.standard.set(value, forKey: "hasSeenOnboarding")
                    // When finished, show home screen
                    if value {
                        let homeVC = HomeViewController()
                        let navController = UINavigationController(rootViewController: homeVC)
                        navController.navigationBar.prefersLargeTitles = false
                        navController.navigationBar.isTranslucent = true
                        window.rootViewController = navController
                        self.window = window
                        window.makeKeyAndVisible()
                    }
                }
            ))
            window.rootViewController = UIHostingController(rootView: onboardingView)
            self.window = window
            window.makeKeyAndVisible()
        } else {
            let homeVC = HomeViewController()
            let navController = UINavigationController(rootViewController: homeVC)
            navController.navigationBar.prefersLargeTitles = false
            navController.navigationBar.isTranslucent = true
            window.rootViewController = navController
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
