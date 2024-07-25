/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's home view controller that displays instructions and camera options.
*/
import Photos
import UIKit
import AVFoundation
import UniformTypeIdentifiers

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ContentAnalysisViewControllerDelegate {

    var recordedVideoURL: URL?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        
        // Dismiss the picker first, then process the video and present the next view controller
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            do {
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                try FileManager.default.copyItem(at: pickedVideoUrl, to: destinationUrl)
                self.recordedVideoURL = destinationUrl
                
                // Create an AVAsset from the URL
                let videoAsset = AVAsset(url: destinationUrl)
                
                // Perform the segue on the main thread after the picker is dismissed
                DispatchQueue.main.async {
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
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen // Set full screen presentation style
        // Reset the URL after passing it to the next view controller
        recordedVideoURL = nil
    }
    
    func contentAnalysisViewControllerDidFinish(_ controller: ContentAnalysisViewController) {
        controller.dismiss(animated: true) {
            self.openGallery()
        }
    }
}

