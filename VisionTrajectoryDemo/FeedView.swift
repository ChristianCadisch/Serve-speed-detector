//
//  FeedView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 25.07.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import AVFoundation
import Photos

struct FeedView: View {
    @State private var analyzedVideos: [URL] = []
    @State private var videoThumbnails: [URL: UIImage] = [:]
    @State private var featuredThumbnail: UIImage?
    @AppStorage("HighestScore") private var highestScore: Int = 0
    @State private var fastestSpeeds: [URL: Double] = [:]
    @State private var assetURLMap: [String: URL] = [:]
    @State private var serveCounts: [URL: Int] = [:]


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
                    Text("\(serveCounts.values.reduce(0, +)) Serve\(serveCounts.values.reduce(0, +) == 1 ? "" : "s")")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.top, -45)
            .padding(.bottom, 2)
            .background(Color(.systemBackground))
            
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
                        .foregroundStyle(.primary)
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
                                        Text("\(serveCounts[videoURL, default: 1]) serve\(serveCounts[videoURL, default: 1] == 1 ? "" : "s") recorded")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)

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
        guard var savedIds = UserDefaults.standard.stringArray(forKey: "AnalyzedAssetIDs") else { return }

        if let (id, _) = assetURLMap.first(where: { $0.value == videoURL }) {
            savedIds.removeAll { $0 == id }
            UserDefaults.standard.set(savedIds, forKey: "AnalyzedAssetIDs")
            assetURLMap.removeValue(forKey: id)
        }

        analyzedVideos.removeAll { $0 == videoURL }
        fastestSpeeds.removeValue(forKey: videoURL)
        videoThumbnails.removeValue(forKey: videoURL)

        // ✅ Refresh featured thumbnail immediately
        if analyzedVideos.isEmpty {
            featuredThumbnail = nil
        } else {
            loadFeaturedThumbnail()
        }

    }


    
    private func loadAnalyzedVideos() {
        analyzedVideos.removeAll()
        assetURLMap.removeAll()
        guard let savedIds = UserDefaults.standard.stringArray(forKey: "AnalyzedAssetIDs") else { return }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: savedIds, options: nil)
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic

        var newVideos: [URL] = []
        let group = DispatchGroup()

        assets.enumerateObjects { asset, _, _ in
            group.enter()
            manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    DispatchQueue.main.async {
                        newVideos.append(urlAsset.url)
                        assetURLMap[asset.localIdentifier] = urlAsset.url
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Preserve order from savedIds
            self.analyzedVideos = savedIds.compactMap { id in
                self.assetURLMap[id]
            }
            self.loadFastestSpeeds()
            self.loadThumbnails()
            self.loadFeaturedThumbnail()
            self.loadServeCounts()
        }

    }

    private func loadServeCounts() {
        for url in analyzedVideos {
            let key = "ServeCount_\(url.lastPathComponent)"
            serveCounts[url] = UserDefaults.standard.integer(forKey: key)
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


#Preview {
    FeedView(
        onAddTapped: {},
        onSettingsTapped: {},
        onVideoSelected: { _ in }
    )
}
