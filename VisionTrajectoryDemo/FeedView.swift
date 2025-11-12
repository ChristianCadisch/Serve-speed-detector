//
//  FeedView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 25.07.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AVFoundation

struct FeedView: View {
    @State private var analyzedVideos: [URL] = []
    @State private var videoThumbnails: [URL: UIImage] = [:]
    @State private var featuredThumbnail: UIImage?
    @AppStorage("HighestScore") private var highestScore: Int = 0
    @State private var fastestSpeeds: [URL: Double] = [:]

    var onAddTapped: () -> Void
    var onSettingsTapped: () -> Void
    var onVideoSelected: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            
            // Top Bar
            HStack {
                Text("Clay")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "tennisball")
                    Text("\(analyzedVideos.count) Serve\(analyzedVideos.count == 1 ? "" : "s")")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.top, -45)
            .padding(.bottom, 2)
            .background(Color.white)
            
            // Feed List
            List {
                // Featured serve
                if let featuredVideoURL = getFeaturedVideoURL(),
                   let speed = fastestSpeeds[featuredVideoURL] {
                    Section {
                        ZStack(alignment: .bottomLeading) {
                            if let thumbnail = featuredThumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 300)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Most recent Serve")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(Int(speed)) km/h")
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .padding()
                        }
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onVideoSelected(featuredVideoURL)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteVideo(featuredVideoURL)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                
                // Other serves
                if analyzedVideos.count > 1 {
                    Section(header:
                                Text("Other Serves")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textCase(nil)
                    ) {
                        ForEach(analyzedVideos.filter { $0 != getFeaturedVideoURL() }.reversed(), id: \.self) { videoURL in
                            let speed = fastestSpeeds[videoURL] ?? 0
                            
                            HStack(spacing: 0) {
                                if let thumbnail = videoThumbnails[videoURL] {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 100)
                                        .clipped()
                                        .mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 100)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(Int(speed)) km/h")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    HStack(spacing: 6) {
                                        Image(systemName: "tennisball")
                                        Text("1 serve recorded")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.leading, 12)
                                Spacer()
                            }
                            .frame(height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.blue.opacity(0.15))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onVideoSelected(videoURL)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteVideo(videoURL)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.bottom, 4)
            .environment(\.defaultMinListRowHeight, 0)
            .onAppear {
                loadAnalyzedVideos()
                loadFeaturedThumbnail()
            }
            .onReceive(NotificationCenter.default.publisher(for: .highestScoreUpdated)) { _ in
                highestScore = UserDefaults.standard.integer(forKey: "HighestScore")
                loadAnalyzedVideos()
                loadFeaturedThumbnail()
            }
            .onReceive(NotificationCenter.default.publisher(for: .newVideoAdded)) { _ in
                loadAnalyzedVideos()
                loadFeaturedThumbnail()
            }

        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Helper Methods
    
    private func getFeaturedVideoURL() -> URL? {
        return analyzedVideos.last
    }
    
    private func loadFeaturedThumbnail() {
        guard let featuredVideoURL = getFeaturedVideoURL() else {
            featuredThumbnail = nil
            return
        }
        let asset = AVAsset(url: featuredVideoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            featuredThumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            featuredThumbnail = nil
        }
    }
    
    private func deleteVideo(_ videoURL: URL) {
        analyzedVideos.removeAll { $0 == videoURL }
        fastestSpeeds.removeValue(forKey: videoURL)
        UserDefaults.standard.set(analyzedVideos.map { $0.absoluteString }, forKey: "AnalyzedVideos")
        UserDefaults.standard.removeObject(forKey: "FastestSpeed_\(videoURL.lastPathComponent)")
    }
    
    private func loadAnalyzedVideos() {
        if let savedURLs = UserDefaults.standard.stringArray(forKey: "AnalyzedVideos") {
            analyzedVideos = savedURLs.compactMap { URL(string: $0) }
            loadFastestSpeeds()
            loadThumbnails()
        }
    }
    
    private func loadFastestSpeeds() {
        for url in analyzedVideos {
            let key = "FastestSpeed_\(url.lastPathComponent)"
            fastestSpeeds[url] = UserDefaults.standard.double(forKey: key)
        }
    }
    
    private func loadThumbnails() {
        for url in analyzedVideos {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
                videoThumbnails[url] = UIImage(cgImage: cgImage)
            }
        }
    }
}
