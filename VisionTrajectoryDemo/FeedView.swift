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
                            VideoURLView(videoURL: videoURL)
                                .frame(height: 100)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
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

struct VideoURLView: View {
    let videoURL: URL
    
    var body: some View {
        VStack {
            Image(systemName: "video")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text(videoURL.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}


struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray
            }
        }
        .onAppear(perform: generateThumbnail)
    }
    
    private func generateThumbnail() {
        print("VideoThumbnailView: Generating thumbnail for \(videoURL)")
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            DispatchQueue.main.async {
                self.thumbnail = UIImage(cgImage: cgImage)
                print("VideoThumbnailView: Thumbnail generated successfully")
            }
        } catch {
            print("VideoThumbnailView: Error generating thumbnail: \(error)")
        }
    }
}
