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
        
        override func viewDidLoad() {
            super.viewDidLoad()
            loadAnalyzedVideos()
            setupFeedView()
        }
    
    
    
    func addNewVideoURL(_ url: URL) {
            print("HomeViewController: Attempting to add URL: \(url.absoluteString)")
            var savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") ?? []
            let filename = url.lastPathComponent
            
            if !savedURLs.contains(where: { URL(string: $0)?.lastPathComponent == filename }) {
                savedURLs.append(url.absoluteString)
                UserDefaults.standard.set(savedURLs, forKey: "AnalyzedVideos")
                print("HomeViewController: Added new video URL, total count: \(savedURLs.count)")
                
                NotificationCenter.default.post(name: .highestScoreUpdated, object: nil)
                NotificationCenter.default.post(name: .newVideoAdded, object: nil)
            } else {
                print("HomeViewController: Video with filename \(filename) already exists, not adding duplicate")
            }
            
            print("HomeViewController: Current saved URLs: \(savedURLs)")
        }
        
    private func setupFeedView() {
        let swiftUIView = NavigationStack {
            FeedView(onAddTapped: { [weak self] in
                self?.openGallery()
            })
        }

        feedView = UIHostingController(rootView: AnyView(swiftUIView))
        
        addChild(feedView)
        view.addSubview(feedView.view)
        feedView.view.frame = view.bounds
        feedView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        feedView.didMove(toParent: self)
    }

    
    func contentAnalysisViewControllerDidFinish(_ controller: ContentAnalysisViewController) {
            controller.dismiss(animated: true) {
                if let newVideoURL = self.recordedVideoURL {
                    print("New video URL: \(newVideoURL)")
                    self.addAnalyzedVideo(newVideoURL)
                } else {
                    print("recordedVideoURL is nil")
                }
            }
        }
    
    private func loadAnalyzedVideos() {
        if let savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") {
            analyzedVideos = savedURLs.compactMap { URL(string: $0) }
            print("FeedView: Loaded \(analyzedVideos.count) video URLs")
        } else {
            print("FeedView: No saved URLs found")
        }
    }
        
    private func addAnalyzedVideo(_ url: URL) {
        print("Attempting to add URL: \(url.absoluteString)")
        DispatchQueue.main.async {
            var savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") ?? []
            let filename = url.lastPathComponent
            
            if !savedURLs.contains(where: { URL(string: $0)?.lastPathComponent == filename }) {
                savedURLs.append(url.absoluteString)
                UserDefaults.standard.set(savedURLs, forKey: "AnalyzedVideos")
                print("Added new video URL, total count: \(savedURLs.count)")
                
                // Load the fastest speed for this video
                let speedKey = "FastestSpeed_\(filename)"
                let speed = UserDefaults.standard.double(forKey: speedKey)
                print("Loaded speed for new video: \(speed)")
                
                NotificationCenter.default.post(name: .highestScoreUpdated, object: nil)
                NotificationCenter.default.post(name: .fastestSpeedUpdated, object: nil)
                print("Posted highestScoreUpdated and fastestSpeedUpdated notifications")
            } else {
                print("Video with filename \(filename) already exists, not adding duplicate")
            }
            
            print("Current saved URLs: \(savedURLs)")
        }
    }
    
    @objc private func addButtonTapped() {
            openGallery()
        }
    func openGallery() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.preferredAssetRepresentationMode = .current   // ✅ original file only

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedVideoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            print("Failed to get the video URL from the picker")
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectory.appendingPathComponent(pickedVideoUrl.lastPathComponent)
        
        print("Picked video URL: \(pickedVideoUrl)")
        print("Destination URL: \(destinationUrl)")
        
        // Dismiss the picker first, then process the video and present the next view controller
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            do {
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                try FileManager.default.copyItem(at: pickedVideoUrl, to: destinationUrl)
                self.recordedVideoURL = destinationUrl
                
                print("Video copied successfully, recordedVideoURL set to: \(self.recordedVideoURL?.absoluteString ?? "nil")")
                
                // Create an AVAsset from the URL
                let videoAsset = AVAsset(url: destinationUrl)
                addNewVideoURL(destinationUrl)
                
                // Perform the segue on the main thread after the picker is dismissed
                DispatchQueue.main.async {
                    print("Performing segue to ContentAnalysisViewController")
                    let controller = ContentAnalysisViewController()
                    controller.recordedVideoSource = AVAsset(url: destinationUrl)
                    controller.delegate = self
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            } catch {
                print("Error processing video: \(error.localizedDescription)")
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? ContentAnalysisViewController else {
            print("Failed to load the content analysis view controller.")
            return
        }
        
        guard let videoURL = recordedVideoURL else {
            print("Failed to load a video path.")
            return
        }
        
        controller.recordedVideoSource = AVAsset(url: videoURL)
        controller.delegate = self  // Make sure this line is here
        controller.modalPresentationStyle = .fullScreen
        print("Preparing to present ContentAnalysisViewController")
    }
    
    private func handlePickedVideo(url: URL) {
        self.recordedVideoURL = url
        self.addNewVideoURL(url)

        let controller = ContentAnalysisViewController()
        controller.recordedVideoSource = AVAsset(url: url)
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }

    
    
}



extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else {
            return
        }

        // ✅ Gets Photos asset ID (required to fetch original file)
        guard let assetId = result.assetIdentifier else {
            print("No asset identifier – cannot fetch original file.")
            return
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            print("Failed to fetch PHAsset.")
            return
        }

        // ✅ Grab the original video resource
        let resources = PHAssetResource.assetResources(for: asset)
        guard let videoResource = resources.first(where: { $0.type == .video }) else {
            print("No video resource found.")
            return
        }

        let fileName = videoResource.originalFilename
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // ✅ Remove old file if needed
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        // ✅ Read original video bytes into your destination file
        PHAssetResourceManager.default().writeData(for: videoResource, toFile: destinationURL, options: nil) { error in
            if let error = error {
                print("Error writing video file: \(error)")
                return
            }

            print("✅ Video saved at: \(destinationURL)")
            DispatchQueue.main.async {
                self.handlePickedVideo(url: destinationURL)
            }
        }
    }
}




struct FeedViewRepresentable: UIViewControllerRepresentable {
    @Binding var analyzedVideos: [URL]
    var onAddTapped: () -> Void
    
    func makeUIViewController(context: Context) -> UIHostingController<FeedView> {
        return UIHostingController(rootView: FeedView(onAddTapped: onAddTapped))
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<FeedView>, context: Context) {
        uiViewController.rootView = FeedView(onAddTapped: onAddTapped)
    }
}

