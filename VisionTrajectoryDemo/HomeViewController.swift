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

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ContentAnalysisViewControllerDelegate {
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    private var feedView: UIHostingController<FeedView>!
    var recordedVideoURL: URL?
    @State private var analyzedVideos: [URL] = []
    private var isLoggedIn = false
    
    func uploadVideo(_ videoURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let videoName = UUID().uuidString + ".mp4"
        let storageRef = storage.reference().child("videos/\(videoName)")
        
        // Get the video data
        guard let videoData = try? Data(contentsOf: videoURL) else {
            completion(.failure(NSError(domain: "VideoUploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read video data"])))
            return
        }
        
        // Upload the video data
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        storageRef.putData(videoData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        completion(.success(downloadURL.absoluteString))
                    } else if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func createPost(videoURL: String, speeds: [Int]) {
        let post = [
            "video": videoURL,
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "speeds": speeds,
            "likes": [],
            "comments": [],
            "timestamp": FieldValue.serverTimestamp()  // Add timestamp here
        ] as [String : Any]

        db.collection("posts").addDocument(data: post) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added successfully")
            }
        }
    }

    


    
        
        override func viewDidLoad() {
            super.viewDidLoad()
                checkUserStatus()
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
    
    func checkUserStatus() {
        showLoginView()
        /*
            if Auth.auth().currentUser == nil {
                // User is not logged in, show the LoginView in SwiftUI
                showLoginView()
            } else {
                // User is logged in, proceed to the main content
                isLoggedIn = true
            }
         */
        }
    
    func showLoginView() {
        let loginView = LoginView(isLoggedIn: Binding(
            get: { self.isLoggedIn },
            set: { newValue in
                self.isLoggedIn = newValue
                if newValue {
                    // Dismiss the login view when the user is logged in
                    self.dismiss(animated: true, completion: nil)
                }
            }
        ))
        
        let loginVC = UIHostingController(rootView: loginView)
        loginVC.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.async {
            self.present(loginVC, animated: true, completion: nil)
        }
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
                
                // Upload video to Firebase Storage
                self.uploadVideo(url) { result in
                    switch result {
                    case .success(let downloadURL):
                        // Create post in Firestore
                        self.createPost(videoURL: downloadURL, speeds: [Int(speed)])
                    case .failure(let error):
                        print("Error uploading video: \(error)")
                    }
                }
                
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
                    
                    // Upload the video to Firebase Storage
                    self.uploadVideo(destinationUrl) { result in
                        switch result {
                        case .success(let downloadURL):
                            print("Video uploaded successfully. Download URL: \(downloadURL)")
                            
                            // Create a post in Firestore
                            // Note: You might want to get the actual speed data here
                            self.createPost(videoURL: downloadURL, speeds: [0])
                            
                            // Add the new video URL to the analyzed videos
                            self.addNewVideoURL(destinationUrl)
                            
                            // Perform the segue on the main thread after the upload is complete
                            DispatchQueue.main.async {
                                print("Performing segue to ContentAnalysisViewController")
                                self.performSegue(withIdentifier: ContentAnalysisViewController.segueDestinationId, sender: self)
                            }
                        case .failure(let error):
                            print("Error uploading video: \(error)")
                        }
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


