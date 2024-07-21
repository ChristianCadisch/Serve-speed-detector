/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's home view controller that displays instructions and camera options.
*/
import Photos
import UIKit
import AVFoundation
import UniformTypeIdentifiers

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var recordedVideoURL: URL?
    
    @IBAction func uploadVideoForAnalysis(_ sender: Any) {
        
        let alert = UIAlertController(title: "Choose Video", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera Roll", style: .default, handler: { _ in
            self.openGallery()
        }))
        alert.addAction(UIAlertAction(title: "Files", style: .default, handler: { _ in
            self.openDocumentPicker()
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func startCameraForAnalysis(_ sender: Any) {
        performSegue(withIdentifier: ContentAnalysisViewController.segueDestinationId,
                     sender: self)
    }
    
    func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        present(imagePicker, animated: true, completion: nil)
    }

    func openDocumentPicker() {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.movie, UTType.video], asCopy: true)
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = false
        present(docPicker, animated: true, completion: nil)
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

    
    
}

extension HomeViewController: UIDocumentPickerDelegate {
    
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
        // Reset the URL after passing it to the next view controller
        recordedVideoURL = nil
    }
    
    func  documentPicker(_ controller: UIDocumentPickerViewController,
                         didPickDocumentsAt urls: [URL]) {
        
        guard let url = urls.first else {
            print("Failed to find a document path at the selected path.")
            return
        }
        recordedVideoURL = url
        performSegue(withIdentifier: ContentAnalysisViewController.segueDestinationId,
                     sender: self)
        recordedVideoURL = nil
        
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
}

