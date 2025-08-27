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
    @State private var selectedVideo: URL?
    var onAddTapped: () -> Void
    
    @AppStorage("HighestScore") private var highestScore: Int = 0
    @State private var fastestSpeeds: [URL: Double] = [:]
    
    // For showing the big "fastest serve" thumbnail (now the most recent video)
    @State private var featuredThumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Top Bar
            HStack {
                Text("CLAY")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "tennisball")
                    Text("135 Serves")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color.white)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // Big card for the most recently uploaded video
                    if let featuredVideoURL = getFeaturedVideoURL(),
                       let speed = fastestSpeeds[featuredVideoURL] {
                        
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
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding()
                        }
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // "Other Serves" heading
                    if analyzedVideos.count > 1 {
                        Text("Other Serves")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    // Show the remaining serves in simpler cards
                    LazyVStack(spacing: 12) {
                        ForEach(analyzedVideos.filter { $0 != getFeaturedVideoURL() }, id: \.self) { videoURL in
                            let speed = fastestSpeeds[videoURL] ?? 0
                            
                            Button {
                                selectedVideo = videoURL
                            } label: {
                                HStack(spacing: 0) {
                                    if let thumbnail = videoThumbnails[videoURL] {
                                        Image(uiImage: thumbnail)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 100)
                                            .maskedCornerRadius(8, corners: [.topLeft, .bottomLeft])
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 120, height: 100)
                                            .maskedCornerRadius(8, corners: [.topLeft, .bottomLeft])
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
                                //.padding()
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.15)))
                                .padding(.horizontal)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteVideo(videoURL)
                                } label: {
                                    Text("Delete")
                                }
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
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
            .sheet(item: $selectedVideo) { videoURL in
                ContentAnalysisViewControllerWrapper(videoURL: videoURL)
            }
            
            // Bottom Tab Bar
            VStack(spacing: 0) {
                HStack {
                    
                    Spacer()
                    
                    Button {
                        // Serves action
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "figure.tennis")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.black)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        onAddTapped()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    
                    Spacer()
                    Button {
                        onAddTapped()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.app")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    
                    Spacer()
                    
                }
                .padding(.vertical, 30)
                .background(Color.white)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Now returns the most recently uploaded video (the last in the array)
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
        
        if fastestSpeeds[videoURL] == Double(highestScore) {
            highestScore = Int(fastestSpeeds.values.max() ?? 0)
            UserDefaults.standard.set(highestScore, forKey: "HighestScore")
        }
    }
    
    private func loadThumbnails() {
        for url in analyzedVideos {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                videoThumbnails[url] = UIImage(cgImage: cgImage)
            } catch {
                videoThumbnails[url] = nil
                print("Error generating thumbnail for \(url.lastPathComponent): \(error)")
            }
        }
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
            let filename = url.lastPathComponent
            let key = "FastestSpeed_\(filename)"
            let speed = UserDefaults.standard.double(forKey: key)
            fastestSpeeds[url] = speed
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(onAddTapped: {})
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

struct RoundedCorner: InsettableShape {
    var radius: CGFloat
    var corners: UIRectCorner
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let path = UIBezierPath(
            roundedRect: insetRect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

extension View {
    func maskedCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        self.mask(RoundedCorner(radius: radius, corners: corners))
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


