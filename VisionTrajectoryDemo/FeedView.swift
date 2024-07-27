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
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(analyzedVideos, id: \.self) { videoURL in
                            ThumbnailView(videoURL: videoURL)
                                .frame(height: 150)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedVideo = videoURL
                                }
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
    
    
    private var addButton: some View {
        Button(action: onAddTapped) {
            Image(systemName: "plus")
        }
    }
    
    private func loadAnalyzedVideos() {
        if let savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") {
            analyzedVideos = savedURLs.compactMap { URL(string: $0) }
            print("FeedView: Loaded \(analyzedVideos.count) video URLs")
        }
    }
}

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

struct ThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
            } else {
                ProgressView()
                    .frame(height: 100)
            }
            
        }
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
