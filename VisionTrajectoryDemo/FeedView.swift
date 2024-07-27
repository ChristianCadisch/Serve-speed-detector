//
//  FeedView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 25.07.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import AVFoundation

import SwiftUI

struct FeedView: View {
    @State private var analyzedVideos: [URL] = []
    @State private var selectedVideo: URL?
    var onAddTapped: () -> Void
    
    @AppStorage("HighestScore") private var highestScore: Int = 0
    @State private var fastestSpeeds: [URL: Double] = [:]
    
    
    var body: some View {
            NavigationView {
                VStack {
                    // Highest Score Display
                    VStack {
                        Text("Highest Score")
                            .font(.headline)
                        Text("\(highestScore) km/h")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.top)
                    
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
                                            }
                                        }
                                        .padding()
                                    }
                                }
                                .navigationTitle("Analyzed Videos")
                                .navigationBarItems(trailing: addButton)
                            }
                            .onAppear(perform: loadAnalyzedVideos)
                            .onReceive(NotificationCenter.default.publisher(for: .highestScoreUpdated)) { _ in
                                highestScore = UserDefaults.standard.integer(forKey: "HighestScore")
                                loadAnalyzedVideos()
                            }
                            .sheet(item: $selectedVideo) { videoURL in
                                ContentAnalysisViewControllerWrapper(videoURL: videoURL)
                            }
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
    
    
    private var addButton: some View {
        Button(action: onAddTapped) {
            Image(systemName: "plus")
        }
    }
    
    private func loadAnalyzedVideos() {
        if let savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") {
            analyzedVideos = savedURLs.compactMap { URL(string: $0) }
            loadFastestSpeeds()
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

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

extension Notification.Name {
    static let fastestSpeedUpdated = Notification.Name("fastestSpeedUpdated")
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
    
    var body: some View {
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
                    showingOptions = true
                }) {
                    Image(systemName: "ellipsis")
                }
                .actionSheet(isPresented: $showingOptions) {
                    ActionSheet(
                        title: Text("Options"),
                        buttons: [
                            .destructive(Text("Delete")) {
                                onDelete()
                            },
                            .cancel()
                        ]
                    )
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
            
            // Video Thumbnail
            if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .onTapGesture {  // Add this gesture
                                    onThumbnailTap()
                                }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .onTapGesture {  // Add this gesture
                                    onThumbnailTap()
                                }
                        }
            
            // Action Buttons
            HStack {
                Button(action: {}) {
                    Image(systemName: "heart")
                }
                Button(action: {}) {
                    Image(systemName: "message")
                }
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
                Spacer()
            }
            .padding(.top, 8)
            
            Text("19 hours ago")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onAppear(perform: loadThumbnail)
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

struct ContentAnalysisViewControllerWrapper: UIViewControllerRepresentable {
    let videoURL: URL
    
    func makeUIViewController(context: Context) -> ContentAnalysisViewController {
        let controller = ContentAnalysisViewController()
        controller.recordedVideoSource = AVAsset(url: videoURL)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ContentAnalysisViewController, context: Context) {}
}
