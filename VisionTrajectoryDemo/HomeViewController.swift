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

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ContentAnalysisViewControllerDelegate {

    private var feedView: UIHostingController<FeedView>!
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
        } else {
            print("HomeViewController: Video with filename \(filename) already exists, not adding duplicate")
        }
        
        print("HomeViewController: Current saved URLs: \(savedURLs)")
    }
        
    private func setupFeedView() {
            let swiftUIView = FeedView(onAddTapped: { [weak self] in
                self?.openGallery()
            })
            feedView = UIHostingController(rootView: swiftUIView)
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
        print("ContentAnalysisViewController: Attempting to add URL: \(url.absoluteString)")
        DispatchQueue.main.async {
            var savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") ?? []
            let filename = url.lastPathComponent
            
            if !savedURLs.contains(where: { URL(string: $0)?.lastPathComponent == filename }) {
                savedURLs.append(url.absoluteString)
                UserDefaults.standard.set(savedURLs, forKey: "AnalyzedVideos")
                print("ContentAnalysisViewController: Added new video URL, total count: \(savedURLs.count)")
                
                NotificationCenter.default.post(name: .highestScoreUpdated, object: nil)
            } else {
                print("ContentAnalysisViewController: Video with filename \(filename) already exists, not adding duplicate")
            }
            
            print("ContentAnalysisViewController: Current saved URLs: \(savedURLs)")
        }
    }
    
    @objc private func addButtonTapped() {
            openGallery()
        }
    func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        //imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true, completion: nil)
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
                    self.performSegue(withIdentifier: ContentAnalysisViewController.segueDestinationId, sender: self)
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
