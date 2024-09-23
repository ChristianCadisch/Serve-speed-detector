//
//  FeedView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 25.07.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AVFoundation
import FirebaseFirestore

struct FeedView: View {
    @State private var analyzedVideos: [URL] = []
    @State private var selectedVideo: URL?
    var onAddTapped: () -> Void
    let db = Firestore.firestore()
    
    @AppStorage("HighestScore") private var highestScore: Int = 0
    @State private var fastestSpeeds: [URL: Double] = [:]
    
    var body: some View {
        VStack(spacing: 0) {
            // Highest Score Display
            VStack {
                Text("Highest Score")
                    .font(.headline)
                Text("\(highestScore) km/h")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.2))
            
            // Video Feed
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(analyzedVideos, id: \.self) { videoURL in
                        let speed = fastestSpeeds[videoURL] ?? 0
                        ThumbnailView(
                            videoURL: videoURL,
                            fastestSpeed: speed,
                            username: "User \(analyzedVideos.firstIndex(of: videoURL)! + 1)",
                            rank: Int.random(in: 1...1000),
                            onDelete: {
                                deleteVideo(videoURL)
                            },
                            onThumbnailTap: {
                                selectedVideo = videoURL
                            }
                        )
                        Divider()
                    }
                }
                .padding(.bottom, 60) // Add padding to account for the navbar
            }
        }
        .overlay(navbar, alignment: .bottom)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear(perform: loadAnalyzedVideos)
        .onReceive(NotificationCenter.default.publisher(for: .highestScoreUpdated)) { _ in
            highestScore = UserDefaults.standard.integer(forKey: "HighestScore")
            loadAnalyzedVideos()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newVideoAdded)) { _ in
            loadAnalyzedVideos()
        }
        .sheet(item: $selectedVideo) { videoURL in
            ContentAnalysisViewControllerWrapper(videoURL: videoURL)
        }
    }
    
    private var navbar: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                NavigationBarItem(imageName: "house.fill", isActive: true)
                Spacer()
                Button(action: onAddTapped) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.white)
            .frame(height: 60)
            
            // Add bottom padding
            Color.white.frame(height: 20) // Adjust this value as needed
        }
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    private func deleteVideo(_ videoURL: URL) {
        // Remove the video from the analyzedVideos array
        analyzedVideos.removeAll { $0 == videoURL }
        
        // Remove the speed from fastestSpeeds dictionary
        fastestSpeeds.removeValue(forKey: videoURL)
        
        // Update UserDefaults
        UserDefaults.standard.set(analyzedVideos.map { $0.absoluteString }, forKey: "AnalyzedVideos")
        
        // Remove the speed from UserDefaults
        UserDefaults.standard.removeObject(forKey: "FastestSpeed_\(videoURL.lastPathComponent)")
        
        // If this was the highest score, recalculate the highest score
        if fastestSpeeds[videoURL] == Double(highestScore) {
            highestScore = Int(fastestSpeeds.values.max() ?? 0)
            UserDefaults.standard.set(highestScore, forKey: "HighestScore")
        }
    }
    
    private func loadAnalyzedVideos() {
        // Fetch the last 10 video documents from the "posts" collection, ordered by timestamp
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching videos: \(error)")
                    return
                }

                // Clear the current list
                self.analyzedVideos.removeAll()

                // Extract video URLs from the documents
                for document in snapshot!.documents {
                    if let videoURLString = document.data()["video"] as? String,
                       let videoURL = URL(string: videoURLString) {
                        self.analyzedVideos.append(videoURL)
                    }
                }

                // Reload the fastest speeds
                self.loadFastestSpeeds()

                print("Loaded \(self.analyzedVideos.count) video URLs from Firebase")
            }
    }

    
    private func loadFastestSpeeds() {
        print("Loading fastest speeds")
        for url in analyzedVideos {
            let filename = url.lastPathComponent
            let key = "FastestSpeed_\(filename)"
            let speed = UserDefaults.standard.double(forKey: key)
            fastestSpeeds[url] = speed
            print("Loaded speed for \(filename): \(speed)")
        }
    }
}

struct ThumbnailView: View {
    let videoURL: URL
    let fastestSpeed: Double
    @State private var thumbnail: UIImage?
    @State private var profileImage: UIImage?
    let username: String
    let rank: Int
    @State private var showingOptions = false
    var onDelete: () -> Void
    var onThumbnailTap: () -> Void
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var comments: [String] = []
    @State private var newComment: String = ""
    @State private var isCommentingEnabled = false
    @State private var isSharePresented = false
    
    let shareLink = "https://github.com/ChristianCadisch"
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(uiImage: profileImage ?? UIImage(systemName: "person.circle.fill")!)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(username)
                            .font(.headline)
                        Text("EVGR Tennis Courts")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        print("Ellipsis button tapped")
                        showingOptions = true
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
                
                
                // Speed and Rank
                HStack {
                    Text("Speed")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(Int(fastestSpeed)) km/h")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Rank")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(rank)th")
                        .font(.headline)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Video Thumbnail
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .onTapGesture(count: 2) {
                                            likePost()
                                        }
                    .onTapGesture {
                        onThumbnailTap()
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .onTapGesture(count: 2) {
                                            likePost()
                                        }
                    .onTapGesture {
                        onThumbnailTap()
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Action Buttons
                HStack {
                    Button(action: {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                    }
                    Button(action: {
                        isCommentingEnabled.toggle()
                    }) {
                        Image(systemName: "message")
                            .foregroundColor(.primary)
                    }
                    Button(action: {
                        isSharePresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                
                if likeCount > 0 {
                                    Text("\(likeCount) like\(likeCount == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                
                Text("19 hours ago")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Comments Section
                if !comments.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(comments, id: \.self) { comment in
                            Text(comment)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if isCommentingEnabled {
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addComment) {
                            Text("Post")
                                .foregroundColor(.blue)
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .onAppear(perform: loadThumbnail)

        .confirmationDialog("Options", isPresented: $showingOptions) {
            Button("Delete", role: .destructive, action: onDelete)
        }
        .actionSheet(isPresented: $isSharePresented) {
                    ActionSheet(
                        title: Text("Share"),
                        message: Text("Share this post: \(shareLink)"),
                        buttons: [
                            .default(Text("Copy Link")) {
                                UIPasteboard.general.string = shareLink
                            },
                            .cancel()
                        ]
                    )
                }
    }
    
    private func likePost() {
            if !isLiked {
                isLiked = true
                likeCount += 1
            }
        }
    
    private func addComment() {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            comments.append(trimmedComment)
            newComment = ""
        }
    }
    
    private func loadThumbnail() {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        profileImage = UIImage(systemName: "person.circle.fill")
    }
}


struct NavigationBarItem: View {
    let imageName: String
    let isActive: Bool
    
    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .foregroundColor(isActive ? .black : .gray)
    }
}

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

extension Notification.Name {
    static let fastestSpeedUpdated = Notification.Name("fastestSpeedUpdated")
}

extension Notification.Name {
    static let highestScoreUpdated = Notification.Name("highestScoreUpdated")
    static let newVideoAdded = Notification.Name("newVideoAdded")
}


struct ContentAnalysisViewControllerWrapper: UIViewControllerRepresentable {
    let videoURL: URL
    
    func makeUIViewController(context: Context) -> ContentAnalysisViewController {
        let controller = ContentAnalysisViewController()
        controller.recordedVideoSource = AVAsset(url: videoURL)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ContentAnalysisViewController, context: Context) {}
}
