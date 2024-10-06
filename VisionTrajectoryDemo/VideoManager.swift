//
//  VideoManager.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 06.10.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class VideoManager {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

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

    func deleteVideo(_ videoURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let videoName = videoURL.lastPathComponent
        let storageRef = storage.reference().child("videos/\(videoName)")

        storageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func createPost(videoURL: String, speeds: [Int], completion: @escaping (Result<Void, Error>) -> Void) {
        let post = [
            "video": videoURL,
            "user_id": Auth.auth().currentUser?.uid ?? "",
            "speeds": speeds,
            "likes": [],
            "comments": [],
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]

        db.collection("posts").addDocument(data: post) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
