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
import Combine

class CoachHubState: ObservableObject {
    @Published var selectedMode: ServeMode = .technique
    @Published var detectedAngle: ServeCameraAngle = .side
}


struct CoachHubWrapper: View {
    @ObservedObject var state: CoachHubState
    let recordAction: () -> Void
    let uploadAction: () -> Void
    let lastServeSpeed = FeedItemStorage
        .load()
        .filter { $0.type == .serve }
        .compactMap { $0.fastestSpeedKmh }
        .filter { $0 > 0 }
        .sorted(by: >)
        .first
    
    let lastTechnique = FeedItemStorage
        .load()
        .filter { $0.type == .aiCoach }
        .sorted(by: { $0.date > $1.date })
        .first
    
    
    
    var body: some View {
        CoachHubView(
            selectedMode: $state.selectedMode,
            detectedAngle: $state.detectedAngle,
            angleDetectionSource: .constant(.manual),
            latestTechniqueItem: lastTechnique,
            recordAction: recordAction,
            uploadAction: uploadAction,
            latestFocusTitle: state.selectedMode == .technique ? "Refine Toss Consistency" : nil,
            latestFocusStrength: state.selectedMode == .technique ? "Stable leg drive detected" : nil,
            latestFocusCorrection: state.selectedMode == .technique ? "Toss drifting too far left" : nil,
            lastServeSpeed: state.selectedMode == .speed ? lastServeSpeed : nil
        )
    }
}



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
    private var pendingCoachVideoURL: URL?
    private var iCloudDownloadOverlay: UIView?
    private var lastPickedAssetIdentifier: String?
    private var coachHubSelectedMode: ServeMode = .technique
    private var coachHubHostingController: UIHostingController<AnyView>?
    private let coachHubState = CoachHubState()
    
    
    
    
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
    
    private func showICloudDownloadOverlay() {
        guard iCloudDownloadOverlay == nil else { return }
        
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        
        let label = UILabel()
        label.text = "Downloading from iCloud…"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        
        overlay.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        
        view.addSubview(overlay)
        iCloudDownloadOverlay = overlay
        
        print("☁️ [iCLOUD] Download overlay shown")
    }
    
    private func hideICloudDownloadOverlay() {
        iCloudDownloadOverlay?.removeFromSuperview()
        iCloudDownloadOverlay = nil
        print("✅ [iCLOUD] Download overlay hidden")
    }
    
    private func showChatView() {
        
        let chatView = ChatView(
            actions: CoachActions(
                openTheory: { [weak self] in
                    guard let self = self else { return }
                    self.activeTab = .theory
                    self.showTheoryView()
                },
                openRealCoach: { [weak self] in
                            guard let self = self else { return }

                            let hosting = UIHostingController(
                                rootView: AnyView(
                                    NavigationStack {
                                        FindCoach()
                                    }
                                )
                            )

                            self.replaceRoot(with: hosting, title: "Real Coach")
                            self.navigationItem.leftBarButtonItem = nil
                            self.disableLessonSwipeBack()
                            self.navigationController?.setNavigationBarHidden(false, animated: false)
                        }
            )
        )
        
        let hosting = UIHostingController(
            rootView: AnyView(
                NavigationStack {
                    chatView
                }
            )
        )
        
        replaceRoot(with: hosting, title: "Coach")
        navigationItem.leftBarButtonItem = nil
        disableLessonSwipeBack()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    
    
    
    
    private enum ActiveTab {
        case home
        case speedUpload
        case chat
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowAICoachDetail(_:)),
            name: .showAICoachDetail,
            object: nil
        )
    }
    
    @objc private func handleShowAICoachDetail(_ notification: Notification) {
        guard let feedItem = notification.object as? FeedItem else {
            print("❌ [DETAIL] No feed item in notification")
            return
        }
        
        print("✅ [DETAIL] Showing AI Coach detail for item:", feedItem.id)
        
        // Ensure we're on the home/feed tab
        if activeTab != .home {
            activeTab = .home
            showFeedView()
        }
        
        // ✅ FIRST: Pop the AICoachScreen off the stack
        navigationController?.popViewController(animated: false)
        
        // ✅ THEN: Push the detail view (small delay to ensure pop completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showAICoachDetailView(feedItem)
        }
    }
    
    private func showAICoachDetailView(_ item: FeedItem) {
        let detailView = AICoachDetailView(
            item: item,
            onReplayAICoach: { [weak self] _ in
                guard
                    let url = item.thumbnailURL,
                    let angle = ServeCameraAngle(storedValue: item.side)
                else {
                    assertionFailure("❌ [AI REPLAY] Missing or invalid camera angle")
                    return
                }
                
                self?.openAICoachSafe(
                    for: url,
                    selectedAngle: angle
                )
            }
        )
        
        let hosting = UIHostingController(rootView: AnyView(detailView))
        navigationController?.pushViewController(hosting, animated: true)
    }
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    private func showFeedView() {
        let feedView = FeedView(
            onAddTapped: { },
            onTheorySelected: { [weak self] in
                self?.activeTab = .theory
                self?.showTheoryView()
            },
            onVideoSelected: { [weak self] videoURL in
                self?.openContentAnalysis(for: videoURL)
            },
            onAICoachSelected: { [weak self] item in
                guard let url = item.thumbnailURL,
                      let angle = ServeCameraAngle(rawValue: item.side ?? "") else {
                    assertionFailure("❌ [FEED] Missing AI Coach angle or URL")
                    return
                }
                
                self?.openAICoachSafe(
                    for: url,
                    selectedAngle: angle
                )
            },
            
            onQuizSelected: { [weak self] topic, difficulty in
                print("🏁 [HOME] Launching quiz from Feed:", topic, difficulty)
                self?.showQuiz(topic: topic, difficulty: difficulty)
            },
            onCoachHubSelected: { [weak self] in
                self?.activeTab = .speedUpload
                self?.showCoachHubView()
            }
        )
        
        let hosting = UIHostingController(
            rootView: AnyView(
                NavigationStack {
                    feedView
                }
            )
        )
        
        
        replaceRoot(with: hosting, title: "")
        navigationItem.leftBarButtonItem = nil
        disableLessonSwipeBack()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    
    private func openAICoachSafe(for videoURL: URL, selectedAngle: ServeCameraAngle) {
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            assertionFailure("❌ [AI OPEN] Video file does not exist")
            return
        }
        
        let fileSize = (try? FileManager.default
            .attributesOfItem(atPath: videoURL.path)[.size] as? NSNumber)?
            .intValue ?? 0
        
        guard fileSize > 0 else {
            assertionFailure("❌ [AI OPEN] Video file is empty")
            return
        }
        
        let screen = AICoachScreen(
            assetLocalIdentifier: lastPickedAssetIdentifier,
            initialVideoURL: videoURL,
            selectedAngle: selectedAngle
        )
        
        navigationController?.pushViewController(
            UIHostingController(rootView: screen),
            animated: true
        )
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
    
    
    
    
    private func showTheoryView(setActiveTab: Bool = false) {
        
        if setActiveTab {
            activeTab = .theory
        }
        
        let theoryView = TheoryView(navigationDelegate: self)
        let hosting = UIHostingController(rootView: AnyView(theoryView))
        
        self.theoryHostingController = hosting
        
        replaceRoot(
            with: hosting,
            title: NSLocalizedString("technique_coach_title", tableName: "general", comment: "")
        )
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
    
    private func showCoachHubView() {
        let wrapper = CoachHubWrapper(
            state: coachHubState,
            recordAction: { [weak self] in
                guard let self = self else { return }
                
                print("🎬 [CoachHub] Record tapped with mode:", self.coachHubState.selectedMode)
                
                switch self.coachHubState.selectedMode {
                case .speed:
                    print("🚀 [CoachHub] Opening Serve Speed flow")
                    self.pendingUploadMode = .speed
                    self.presentVideoPicker()
                    
                case .technique:
                    print("🧠 [CoachHub] Opening Technique / AI Coach flow")
                    self.activeTab = .coachUpload
                    self.pendingUploadMode = .coach
                    self.presentVideoPicker()
                }
            },
            uploadAction: { [weak self] in
                guard let self = self else { return }
                
                print("📤 [CoachHub] Upload tapped with mode:", self.coachHubState.selectedMode)
                
                switch self.coachHubState.selectedMode {
                case .speed:
                    print("🚀 [CoachHub] Uploading to Serve Speed")
                    self.pendingUploadMode = .speed
                    self.presentVideoPicker()
                    
                case .technique:
                    print("🧠 [CoachHub] Uploading to Technique / AI Coach")
                    self.activeTab = .coachUpload
                    self.pendingUploadMode = .coach
                    self.presentVideoPicker()
                }
            }
        )
        
        let hosting = UIHostingController(
            rootView: AnyView(
                NavigationStack {
                    wrapper
                }
            )
        )
        
        coachHubHostingController = hosting
        replaceRoot(with: hosting, title: "Training Hub")
        navigationItem.leftBarButtonItem = nil
        disableLessonSwipeBack()
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        
        // coach hub
        let coachButton = createButton(
            systemName: "figure.tennis",
            isActive: activeTab == .speedUpload
        ) { [weak self] in
            self?.activeTab = .speedUpload
            self?.showCoachHubView()
        }
        
        // CHAT
        let chatButton = createButton(
            systemName: "sparkles",
            isActive: activeTab == .chat
        ) { [weak self] in
            self?.activeTab = .chat
            self?.showChatView()
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
        bar.addArrangedSubview(coachButton)
        bar.addArrangedSubview(chatButton)
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
    
    private func ensureFullPhotoAccessOrPresentExplanation() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized:
            return true
            
        case .limited, .denied, .restricted, .notDetermined:
            let view = FullAccessRequiredView()
            let hosting = UIHostingController(rootView: view)
            hosting.modalPresentationStyle = .formSheet
            present(hosting, animated: true)
            return false
            
        @unknown default:
            return false
        }
    }
    
    
    
    func showQuiz(topic: QuizIdentifier, difficulty: QuizDifficulty) {
        
        activeTab = .theory   // ← NEW: update tab before building UI
        
        let quizView = QuizView(
            vm: QuizViewModel(questions: topic.questions(for: difficulty)),
            quizID: topic,
            onQuizFinished: { _, score, total in
                let id = LessonQuizID(topic: topic, difficulty: difficulty)
                let total = topic.totalQuestions(for: difficulty)
                
                let ratio = Double(score) / Double(max(total, 1))
                
                let previous = UserDefaults.standard.integer(forKey: id.userDefaultsKey)
                if score > previous {
                    UserDefaults.standard.set(score, forKey: id.userDefaultsKey)
                }
                
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
                    .id("quiz_\(topic.rawValue)_\(difficulty.rawValue)")
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
        
        print("🎬 [OPEN] Requested playback:", videoURL.lastPathComponent)
        print("📁 [OPEN] Exists:", FileManager.default.fileExists(atPath: videoURL.path))
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? NSNumber)?.intValue ?? 0
        print("📦 [OPEN] File size:", fileSize, "bytes")
        
        guard fileSize > 0 else {
            print("❌ [OPEN] ABORT — File is empty or missing")
            return
        }
        
        recordedVideoURL = videoURL
        
        let controller = ContentAnalysisViewController()
        controller.recordedVideoSource = AVAsset(url: videoURL)
        controller.delegate = self
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    
    
    
    
    
    func contentAnalysisViewControllerDidFinish(_ controller: ContentAnalysisViewController) {
        
    }
    
    
    // MARK: - Video Handling
    
    func openGallery() {
        presentVideoPicker()
    }
    
    
    private func presentVideoPicker() {
        
        // ⛔ Block if not full access
        guard ensureFullPhotoAccessOrPresentExplanation() else {
            return
        }
        
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
                assetLocalIdentifier: self.lastPickedAssetIdentifier,
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
        
        // 🔒 Permission re-check — user may have changed it in Settings
        guard ensureFullPhotoAccessOrPresentExplanation() else {
            return
        }
        
        guard let result = results.first,
              let assetId = result.assetIdentifier else {
            print("❌ [PICKER] No asset identifier")
            return
        }
        
        self.lastPickedAssetIdentifier = assetId
        
        print("✅ [PICKER] Selected asset ID:", assetId)
        showICloudDownloadOverlay()
        
        // 🔥 Works only with FULL ACCESS — now guaranteed because of the check
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            print("❌ [PICKER] PHAsset fetch failed")
            hideICloudDownloadOverlay()
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        print("☁️ [iCLOUD] Network access allowed:", options.isNetworkAccessAllowed)
        
        manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
            
            DispatchQueue.main.async {
                
                self.hideICloudDownloadOverlay()
                
                guard let avURLAsset = avAsset as? AVURLAsset else {
                    print("❌ [iCLOUD] AVURLAsset conversion failed")
                    return
                }
                
                let originalURL = avURLAsset.url
                
                print("✅ [iCLOUD] AVAsset delivered")
                print("📍 [iCLOUD] Original URL:", originalURL)
                print("📍 [iCLOUD] File exists:", FileManager.default.fileExists(atPath: originalURL.path))
                
                let fileSize = (try? FileManager.default
                    .attributesOfItem(atPath: originalURL.path)[.size] as? NSNumber)?.intValue ?? 0
                
                guard fileSize > 0 else {
                    print("❌ [iCLOUD] Downloaded file is EMPTY — aborting")
                    return
                }
                
                switch self.pendingUploadMode {
                    
                case .speed:
                    
                    if let safeURL = self.prepareServeVideoForAnalysis(originalURL: originalURL) {
                        self.pendingServeVideoURL = safeURL
                        self.openContentAnalysis(for: safeURL)
                    } else {
                        print("❌ [SERVE] Copy to app storage FAILED")
                    }
                    
                case .coach:
                    if let safeURL = self.prepareServeVideoForAnalysis(originalURL: originalURL) {
                        self.pendingCoachVideoURL = safeURL
                        self.openAICoachSafe(for: safeURL, selectedAngle: self.coachHubState.detectedAngle)
                    }
                    
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
