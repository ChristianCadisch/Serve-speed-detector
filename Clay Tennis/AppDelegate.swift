/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's delegate object.
*/

import UIKit
import FirebaseCore
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
        Auth.auth().signInAnonymously { result, error in
            if let error {
                print("❌ AUTH ERROR:", error.localizedDescription)
            } else {
                print("✅ AUTH UID:", result?.user.uid ?? "nil")
            }
        }

        return true
    }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

}

