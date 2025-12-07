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

class HomeViewController: UIViewController,
                          UIImagePickerControllerDelegate,
                          UINavigationControllerDelegate,
                          ContentAnalysisViewControllerDelegate,
                          HomeNavigationDelegate {
    
    
    
    
    private var feedView: UIHostingController<AnyView>!
    var recordedVideoURL: URL?
    @State private var analyzedVideos: [URL] = []
    private var activeTab: ActiveTab = .home
    private var currentHostingController: UIHostingController<AnyView>?
    private var theoryHostingController: UIHostingController<AnyView>?
    private var pendingUploadMode: UploadMode = .speed
    private var pendingServeVideoURL: URL?

    private func prepareServeVideoForAnalysis(originalURL: URL) -> URL? {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let filename = "serve_\(UUID().uuidString).mov"
        let destinationURL = docs.appendingPathComponent(filename)

        do {
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            print("✅ [FILE] Serve video staged at:", destinationURL.lastPathComponent)
            return destinationURL
        } catch {
            print("❌ [FILE] Serve staging failed:", error.localizedDescription)
            return nil
        }
    }

    
    private enum ActiveTab {
        case home
        case speedUpload
        case coachUpload
        case theory
        case settings
    }
    
    
    private enum UploadMode {
        case speed
        case coach
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
    
    
    func showLessonDetail(
        topic: QuizIdentifier,
        highScores: Binding<[LessonQuizID: Int]>,
        onHighScoreUpdated: @escaping (LessonQuizID, Int) -> Void
    ){
        let detailView = LessonDetailView(
            topic: topic,
            highScores: highScores,
            onHighScoreUpdated: onHighScoreUpdated,
            navigationDelegate: self
        )
        
        showLessonDetailView(detailView)
    }
    
    
    func popToTheoryView() {
        if let hosting = theoryHostingController {
            replaceRoot(
                with: hosting,
                title: NSLocalizedString("technique_coach_title", tableName: "general", comment: "")
            )
            navigationItem.leftBarButtonItem = nil
            disableLessonSwipeBack()
            navigationController?.setNavigationBarHidden(false, animated: false)
        } else {
            showTheoryView()
        }
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showFeedView()
    }
    
    
    private func showFeedView() {
        let feedView = FeedView(
            onAddTapped: { },
            onSettingsTapped: { [weak self] in
                self?.showSettingsView()
            },
            onVideoSelected: { [weak self] videoURL in
                self?.openContentAnalysis(for: videoURL)
            }
        )
        
        let hosting = UIHostingController(rootView: AnyView(feedView))
        replaceRoot(with: hosting, title: "")
        navigationItem.leftBarButtonItem = nil
        disableLessonSwipeBack()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    
    private func showSettingsView() {
        let settingsView = SettingsView(hasSeenOnboarding: .constant(true))
        let hosting = UIHostingController(rootView: AnyView(settingsView))
        replaceRoot(
            with: hosting,
            title: NSLocalizedString("settings_title", tableName: "general", comment: "")
        )
        navigationItem.leftBarButtonItem = nil
        disableLessonSwipeBack()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func enableLessonSwipeBack() {
        let edgeSwipe = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleSwipeBack(_:))
        )
        
        edgeSwipe.edges = .left
        view.addGestureRecognizer(edgeSwipe)
    }
    
    private func disableLessonSwipeBack() {
        view.gestureRecognizers?
            .filter { $0 is UIScreenEdgePanGestureRecognizer }
            .forEach { view.removeGestureRecognizer($0) }
    }
    
    @objc private func handleSwipeBack(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended {
            popToTheoryView()
        }
    }
    
    
    
    
    private func showTheoryView() {
        let theoryView = TheoryView(navigationDelegate: self)
        let hosting = UIHostingController(
            rootView: AnyView(theoryView)
        )
        
        self.theoryHostingController = hosting
        
        
        replaceRoot(
            with: hosting,
            title: NSLocalizedString("technique_coach_title", tableName: "general", comment: "")
        )
        navigationItem.leftBarButtonItem = nil
        disableLessonSwipeBack()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        tabBar.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
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
    
    private func showLessonDetailView(_ view: LessonDetailView) {
        let hosting = UIHostingController(rootView: AnyView(view))
        replaceRoot(
            with: hosting,
            title: NSLocalizedString("lesson_overview_title", tableName: "general", comment: "")
        )
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackToTheory)
        )
        
        enableLessonSwipeBack()
    }
    
    
    
    @objc private func handleBackToTheory() {
        popToTheoryView()
    }
    
    
    
    
    private func makeBottomTabBar() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let bar = UIStackView()
        bar.axis = .horizontal
        bar.alignment = .center
        bar.distribution = .equalSpacing
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        func createButton(systemName: String, isActive: Bool, action: @escaping () -> Void) -> UIButton {
            let b = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            b.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
            b.tintColor = isActive ? UIColor.label : UIColor.secondaryLabel
            b.addAction(UIAction { _ in action() }, for: .touchUpInside)
            b.translatesAutoresizingMaskIntoConstraints = false
            return b
        }
        
        // HOME
        let homeButton = createButton(
            systemName: "house.fill",
            isActive: activeTab == .home
        ) { [weak self] in
            self?.activeTab = .home
            self?.showFeedView()
        }
        
        // SERVE SPEED
        let speedButton = createButton(
            systemName: "figure.tennis",
            isActive: activeTab == .speedUpload
        ) { [weak self] in
            self?.activeTab = .speedUpload
            self?.pendingUploadMode = .speed
            self?.presentVideoPicker()
        }
        
        // AI COACH
        let coachButton = createButton(
            systemName: "sparkles",
            isActive: activeTab == .coachUpload
        ) { [weak self] in
            self?.activeTab = .coachUpload
            self?.pendingUploadMode = .coach
            self?.presentVideoPicker()
        }
        
        // THEORY
        let theoryButton = createButton(
            systemName: "brain.head.profile",
            isActive: activeTab == .theory
        ) { [weak self] in
            self?.activeTab = .theory
            self?.showTheoryView()
        }
        
        // SETTINGS
        let settingsButton = createButton(
            systemName: "gearshape",
            isActive: activeTab == .settings
        ) { [weak self] in
            self?.activeTab = .settings
            self?.showSettingsView()
        }
        
        bar.addArrangedSubview(homeButton)
        bar.addArrangedSubview(speedButton)
        bar.addArrangedSubview(coachButton)
        bar.addArrangedSubview(theoryButton)
        bar.addArrangedSubview(settingsButton)
        
        container.addSubview(bar)
        
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 40),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -40),
            bar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            bar.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return container
    }
    
    
    
    func popToLessonView(refresh: Bool) {
        
        if refresh,
           let hosting = theoryHostingController,
           var rootView = hosting.rootView as? TheoryView {
            
            rootView.forceRefresh()
            hosting.rootView = AnyView(rootView)
        }
        
        popToTheoryView()
    }
    
    
    func showQuiz(topic: QuizIdentifier, difficulty: QuizDifficulty) {
        
        let quizView = QuizView(
            vm: QuizViewModel(questions: topic.questions(for: difficulty)),
            quizID: topic,
            onQuizFinished: { _, score, total in
                let id = LessonQuizID(topic: topic, difficulty: difficulty)
                let total = topic.totalQuestions(for: difficulty)
                
                let ratio = Double(score) / Double(max(total, 1))
                
                // Save best score
                let previous = UserDefaults.standard.integer(forKey: id.userDefaultsKey)
                if score > previous {
                    UserDefaults.standard.set(score, forKey: id.userDefaultsKey)
                }
                
                // ✅ Unlock next level if ≥ 70%
                if ratio >= 0.7 {
                    if let nextDifficulty = QuizDifficulty(rawValue: difficulty.rawValue + 1) {
                        let nextID = LessonQuizID(topic: topic, difficulty: nextDifficulty)
                        
                        UserDefaults.standard.set(true, forKey: "Unlocked_\(nextID.userDefaultsKey)")
                    }
                }
            },
            onFinish: { [weak self] in
                self?.popToLessonView(refresh: true)
            },
            navigationDelegate: self
        )
        
        let hosting = UIHostingController(
            rootView: AnyView(
                quizView
                    .id("quiz_\(topic.rawValue)_\(difficulty.rawValue)")   // ✅ force new instance
            )
        )
        self.currentHostingController = hosting
        replaceRoot(with: hosting, title: "\(topic.title) Quiz")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackToTheory)
        )
        
        enableLessonSwipeBack()
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
        recordedVideoURL = videoURL     // ← ADD THIS LINE
        let controller = ContentAnalysisViewController()
        controller.recordedVideoSource = AVAsset(url: videoURL)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func openAICoach(for videoURL: URL) {
        let coachView = AICoachScreen(videoURL: videoURL)
        let hosting = UIHostingController(rootView: coachView)
        navigationController?.pushViewController(hosting, animated: true)
    }
    
    
    
    
    func contentAnalysisViewControllerDidFinish(_ controller: ContentAnalysisViewController) {
        
    }
    
    
    // MARK: - Video Handling
    
    func openGallery() {
        presentVideoPicker()
    }
    
    
    private func presentVideoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
    
    func contentAnalysisViewControllerDidFinish(_ controller: ContentAnalysisViewController,
                                                serveCount: Int) {
        
        controller.dismiss(animated: true) {
            
            guard let url = self.pendingServeVideoURL else {
                print("❌ [SERVE] No staged serve video found")
                return
            }

            let speedKey = "FastestSpeed_\(url.absoluteString)"
            let speed = UserDefaults.standard.double(forKey: speedKey)
            
            let feedItem = FeedItem(
                type: .serve,
                date: Date(),
                thumbnailURL: url,
                title: "Serve Speed",
                subtitle: "\(serveCount) serves",
                primaryMetricText: "\(Int(speed)) km/h",
                secondaryMetricText: nil,
                fastestSpeedKmh: speed,
                serveCount: serveCount
            )
            
            print("✅ [SERVE] Creating serve FeedItem")
            print("📍 URL:", url.lastPathComponent)
            print("🏎 Speed:", speed)
            print("🎯 Serve Count:", serveCount)

            FeedItemStorage.append(feedItem)
            
            NotificationCenter.default.post(name: .feedItemCreated, object: feedItem)
            
            if self.activeTab != .home {
                self.activeTab = .home
                self.showFeedView()
            }
        }
        self.pendingServeVideoURL = nil

    }
    
    
    private func copyVideoToAppStorage(originalURL: URL) -> URL? {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let filename = "serve_\(UUID().uuidString).mov"
        let destinationURL = docs.appendingPathComponent(filename)

        do {
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            print("✅ [FILE] Copied serve video to:", destinationURL.lastPathComponent)
            return destinationURL
        } catch {
            print("❌ [FILE] Copy failed:", error.localizedDescription)
            return nil
        }
    }

    
    
    
    private func addAnalyzedVideo(_ url: URL, serveCount: Int) {
        DispatchQueue.main.async {
            var savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") ?? []
            let filename = url.lastPathComponent
            
            if !savedURLs.contains(where: { URL(string: $0)?.lastPathComponent == filename }) {
                savedURLs.append(url.absoluteString)
                UserDefaults.standard.set(savedURLs, forKey: "AnalyzedVideos")
                
                let key = "ServeCount_\(url.absoluteString)"
                UserDefaults.standard.set(serveCount, forKey: key)
                
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
            guard let avURLAsset = avAsset as? AVURLAsset else { return }

            DispatchQueue.main.async {

                let originalURL = avURLAsset.url
                print("📥 [PICKER] Picked video:", originalURL.lastPathComponent)

                switch self.pendingUploadMode {

                case .speed:

                    // ✅ COPY INTO APP STORAGE
                    if let safeURL = self.prepareServeVideoForAnalysis(originalURL: originalURL) {
                            self.pendingServeVideoURL = safeURL
                            self.openContentAnalysis(for: safeURL)
                        }

                case .coach:

                    // ✅ AI Coach keeps using the app-owned pipeline
                    self.openAICoach(for: originalURL)
                }
            }
        }

    }
}

enum FeedItemStorage {

    private static let key = "FeedItems"

    static func load() -> [FeedItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([FeedItem].self, from: data) else {
            return []
        }
        return items
    }

    static func append(_ item: FeedItem) {
        var items = load()
        items.append(item)
        save(items)

        print("💾 [STORAGE] Feed saved. Total items now:", items.count)
    }


    static func save(_ items: [FeedItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

extension Notification.Name {
    static let feedItemCreated = Notification.Name("FeedItemCreated")
}



protocol HomeNavigationDelegate: AnyObject {
    func showLessonDetail(
        topic: QuizIdentifier,
        highScores: Binding<[LessonQuizID: Int]>,
        onHighScoreUpdated: @escaping (LessonQuizID, Int) -> Void
    )
    
    func popToTheoryView()
    func popToLessonView(refresh: Bool)
    func showQuiz(topic: QuizIdentifier, difficulty: QuizDifficulty)
    
}



// PREVIEW STUFF
struct HomeVCPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HomeViewController {
        return HomeViewController()
    }
    
    func updateUIViewController(_ uiViewController: HomeViewController, context: Context) {}
}
#Preview {
    HomeVCPreview()
}
