/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's home view controller that displays instructions and camera options.
*/

import Photos
import UIKit
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

class HomeViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    @State private var isLoggedIn = false
    private let videoManager = VideoManager()
    private var feedView: UIHostingController<FeedView>!
    private var loginView: UIHostingController<LoginView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Only setup the feed view and navbar if the user is logged in
        if isLoggedIn {
            setupFeedView()
            setupNavbar()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLoginStatus()
    }

    private func checkLoginStatus() {
        if Auth.auth().currentUser == nil {
            // Show the login view if not logged in
            showLoginView()
        } else {
            // Set the user as logged in and load the feed
            isLoggedIn = true
            setupFeedView()
            setupNavbar()
        }
    }

    private func showLoginView() {
        let loginView = LoginView(
            isLoggedIn: Binding(
                get: { self.isLoggedIn },
                set: { newValue in
                    self.isLoggedIn = newValue
                    if newValue {
                        self.dismissLoginView()
                        self.setupFeedView()
                        self.setupNavbar()
                    }
                }
            ),
            onLoginSuccess: { [weak self] in
                self?.dismissLoginView()
                self?.setupFeedView()
                self?.setupNavbar()
            }
        )
        
        let loginVC = UIHostingController(rootView: loginView)
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true, completion: nil)
    }

    private func dismissLoginView() {
        self.dismiss(animated: true) { [weak self] in
                self?.setupFeedView()
                self?.setupNavbar()
            }
    }

    private func setupFeedView() {
        guard feedView == nil else { return } // Prevent adding multiple times
        let swiftUIView = FeedView(
            onAddTapped: { [weak self] in
                self?.openGallery()
            },
            videoManager: videoManager
        )
        
        feedView = UIHostingController(rootView: swiftUIView)
        addChild(feedView)
        view.addSubview(feedView.view)
        feedView.view.frame = view.bounds
        feedView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        feedView.didMove(toParent: self)
    }


    private func setupNavbar() {
        guard view.subviews.first(where: { $0 is UIButton }) == nil else { return } // Check if navbar is already added
            let navbar = UIView()
            navbar.backgroundColor = .white
            navbar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(navbar)
            
            NSLayoutConstraint.activate([
                navbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                navbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navbar.heightAnchor.constraint(equalToConstant: 60)
            ])
        
        // Add home button
        let homeButton = UIButton(type: .system)
        homeButton.setImage(UIImage(systemName: "house.fill"), for: .normal)
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        navbar.addSubview(homeButton)
        
        // Add add/upload button
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        navbar.addSubview(addButton)
        
        // Add profile button
        let profileButton = UIButton(type: .system)
        profileButton.setImage(UIImage(systemName: "person.circle"), for: .normal)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
        navbar.addSubview(profileButton)
        
        // Set up button constraints
        NSLayoutConstraint.activate([
            homeButton.centerYAnchor.constraint(equalTo: navbar.centerYAnchor),
            homeButton.leadingAnchor.constraint(equalTo: navbar.leadingAnchor, constant: 30),
            
            addButton.centerYAnchor.constraint(equalTo: navbar.centerYAnchor),
            addButton.centerXAnchor.constraint(equalTo: navbar.centerXAnchor),
            
            profileButton.centerYAnchor.constraint(equalTo: navbar.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: navbar.trailingAnchor, constant: -30)
        ])
    }

    @objc private func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        present(imagePicker, animated: true, completion: nil)
    }
    @objc private func openProfile() {
        let profileView = ProfileViewControllerWrapper(onLoginSuccess: { [weak self] in
            // Handle what happens after a successful login
            self?.dismissLoginView()
            self?.setupFeedView()
            self?.setupNavbar()
        })
        
        let hostingController = UIHostingController(rootView: profileView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true, completion: nil)
    }

}





struct ProfileViewControllerWrapper: UIViewControllerRepresentable {
    var onLoginSuccess: () -> Void // Pass in the closure for handling login success
    
    func makeUIViewController(context: Context) -> UIHostingController<ProfileView> {
        // Pass the onLoginSuccess closure to ProfileView
        return UIHostingController(rootView: ProfileView(onLoginSuccess: onLoginSuccess))
    }

    func updateUIViewController(_ uiViewController: UIHostingController<ProfileView>, context: Context) {
        // Update the view controller if needed
    }
}
