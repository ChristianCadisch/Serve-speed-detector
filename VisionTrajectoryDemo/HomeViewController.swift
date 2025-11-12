/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's home view controller that displays instructions and camera options.
*/

import Photos
import PhotosUI
import UIKit
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ContentAnalysisViewControllerDelegate {

    private var feedView: UIHostingController<AnyView>!
    var recordedVideoURL: URL?
    @State private var analyzedVideos: [URL] = []
    private var activeTab: ActiveTab = .feed
    private var currentHostingController: UIHostingController<AnyView>?


    
    private enum ActiveTab {
        case feed
        case settings
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UserDefaults.standard.bool(forKey: "HasSeenOnboarding") {
            let onboardingView = OnboardingView(hasSeenOnboarding: .constant(false))
            let hosting = UIHostingController(rootView: onboardingView)
            hosting.modalPresentationStyle = .fullScreen
            present(hosting, animated: false)
        }
    }



    override func viewDidLoad() {
        super.viewDidLoad()
        showFeedView()
    }


    private func showFeedView() {
        let feedView = FeedView(
            onAddTapped: { [weak self] in
                self?.openGallery()
            },
            onSettingsTapped: { [weak self] in
                self?.showSettingsView()
            },
            onVideoSelected: { [weak self] videoURL in
                self?.openContentAnalysis(for: videoURL)
            }
        )

        let hosting = UIHostingController(rootView: AnyView(feedView))
        replaceRoot(with: hosting, title: "")
    }

    private func showSettingsView() {
        let settingsView = SettingsView(hasSeenOnboarding: .constant(true))
        let hosting = UIHostingController(rootView: AnyView(settingsView))
        replaceRoot(with: hosting, title: "Settings")
    }

    private func replaceRoot(with controller: UIHostingController<AnyView>, title: String) {
        // Remove old SwiftUI controller
        currentHostingController?.willMove(toParent: nil)
        currentHostingController?.view.removeFromSuperview()
        currentHostingController?.removeFromParent()

        // Container stack
        let container = UIStackView()
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        container.alignment = .fill
        container.distribution = .fill

        // --- Main SwiftUI content ---
        addChild(controller)
        container.addArrangedSubview(controller.view)
        controller.didMove(toParent: self)

        // --- Bottom bar ---
        let tabBar = makeBottomTabBar()
        container.addArrangedSubview(tabBar)
        tabBar.heightAnchor.constraint(equalToConstant: 100).isActive = true

        // Replace everything in view
        view.subviews.forEach { $0.removeFromSuperview() }
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        navigationItem.title = title
        currentHostingController = controller
    }

    
    
    
    private func makeBottomTabBar() -> UIView {
        let bar = UIStackView()
        bar.axis = .horizontal
        bar.alignment = .center
        bar.distribution = .equalSpacing
        bar.backgroundColor = .white
        bar.layoutMargins = UIEdgeInsets(top: 10, left: 50, bottom: -10, right: 50)
        bar.isLayoutMarginsRelativeArrangement = true
        bar.spacing = 0

        func createButton(systemName: String, isActive: Bool, action: @escaping () -> Void) -> UIButton {
            let button = UIButton(type: .system)
            // ✅ Explicitly configure size + scale
            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular, scale: .large)
            let image = UIImage(systemName: systemName, withConfiguration: config)
            button.setImage(image, for: .normal)
            button.tintColor = isActive ? .black : .gray

            // ✅ Fixed frame for consistent large tap target
            button.addAction(UIAction { _ in action() }, for: .touchUpInside)

            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 50).isActive = true
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true

            button.imageView?.contentMode = .scaleAspectFit
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .center
            return button
        }

        let feedButton = createButton(
            systemName: "figure.tennis",
            isActive: activeTab == .feed
        ) { [weak self] in
            self?.activeTab = .feed
            self?.showFeedView()
        }

        let addButton = createButton(
            systemName: "plus.app",
            isActive: false
        ) { [weak self] in
            self?.openGallery()
        }

        let settingsButton = createButton(
            systemName: "gearshape",
            isActive: activeTab == .settings
        ) { [weak self] in
            self?.activeTab = .settings
            self?.showSettingsView()
        }

        bar.addArrangedSubview(feedButton)
        bar.addArrangedSubview(addButton)
        bar.addArrangedSubview(settingsButton)

        // ✅ Taller overall bar for breathing room
        bar.heightAnchor.constraint(equalToConstant: 70).isActive = true

        return bar
    }






    private func replaceSwiftUIView(with newView: AnyView) {
        feedView?.willMove(toParent: nil)
        feedView?.view.removeFromSuperview()
        feedView?.removeFromParent()

        feedView = UIHostingController(rootView: newView)
        addChild(feedView)
        view.addSubview(feedView.view)
        feedView.view.frame = view.bounds
        feedView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        feedView.didMove(toParent: self)
    }



    private func openSettings() {
        let settingsView = SettingsView(hasSeenOnboarding: .constant(true))
        let hostingController = UIHostingController(rootView: settingsView)
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func openContentAnalysis(for videoURL: URL) {
        let controller = ContentAnalysisViewController()
        controller.recordedVideoSource = AVAsset(url: videoURL)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Video Handling

    func openGallery() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func contentAnalysisViewControllerDidFinish(_ controller: ContentAnalysisViewController) {
        controller.dismiss(animated: true) {
            if let newVideoURL = self.recordedVideoURL {
                self.addAnalyzedVideo(newVideoURL)
            }
            // ✅ Only switch if not already on the feed
            if self.activeTab != .feed {
                self.activeTab = .feed
                self.showFeedView()
            }
        }
    }



    private func addAnalyzedVideo(_ url: URL) {
        DispatchQueue.main.async {
            var savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") ?? []
            let filename = url.lastPathComponent
            if !savedURLs.contains(where: { URL(string: $0)?.lastPathComponent == filename }) {
                savedURLs.append(url.absoluteString)
                UserDefaults.standard.set(savedURLs, forKey: "AnalyzedVideos")
                NotificationCenter.default.post(name: .highestScoreUpdated, object: nil)
                NotificationCenter.default.post(name: .fastestSpeedUpdated, object: nil)
            }
        }
    }
}

extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first,
              let assetId = result.assetIdentifier else { return }

        // ✅ Save only the persistent Photos identifier
        var savedIds = UserDefaults.standard.stringArray(forKey: "AnalyzedAssetIDs") ?? []
        if !savedIds.contains(assetId) {
            savedIds.append(assetId)
            UserDefaults.standard.set(savedIds, forKey: "AnalyzedAssetIDs")
        }

        // ✅ Fetch AVAsset temporarily for analysis
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else { return }

        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat

        manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset = avAsset else { return }
            DispatchQueue.main.async {
                self.openContentAnalysis(for: (avAsset as? AVURLAsset)?.url ?? URL(fileURLWithPath: ""))
            }
        }
    }

}


extension Notification.Name {
    static let fastestSpeedUpdated = Notification.Name("fastestSpeedUpdated")
    static let highestScoreUpdated = Notification.Name("highestScoreUpdated")
    static let newVideoAdded = Notification.Name("newVideoAdded")
}
