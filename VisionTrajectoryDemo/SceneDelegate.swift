/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create the window
        let window = UIWindow(windowScene: windowScene)

        // Create your root view controller
        let homeVC = HomeViewController()

        // Embed it in a navigation controller
        let navController = UINavigationController(rootViewController: homeVC)
        navController.navigationBar.prefersLargeTitles = false
        navController.navigationBar.isTranslucent = true

        // Assign root
        window.rootViewController = navController
        self.window = window

        // Show the window
        window.makeKeyAndVisible()
    }
}
