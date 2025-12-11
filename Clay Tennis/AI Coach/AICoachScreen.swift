//
//  AICoachScreen.swift
//  Clay Tennis
//
//  Created by Christian on 01.12.2025.
//  Improved UI Version
//

import SwiftUI
import AVFoundation
import Photos

// MARK: - MAIN COACH SCREEN

struct AICoachScreen: View {
    @ObservedObject var state = GameStateObserver.shared
    @Environment(\.dismiss) private var dismiss
    
    
    var assetLocalIdentifier: String
    var initialVideoURL: URL?
    @State private var resolvedVideoURL: URL? = nil
    
    @State private var controller: AIcameraViewController? = nil
    @State private var showHeroBanner = false
    @State private var animateFeedback = false
    @State private var trophyFrameThumbnail: UIImage? = nil
    @State private var showAnalysisCard = false
    @State private var observation = ""
    
    // Add these new states
    @State private var isExporting = false
    @State private var exportedVideoURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?
    @State private var showOverlay = false

    
    @Environment(\.colorScheme) private var colorScheme
    
    var selectedAngle: ServeCameraAngle
    
    var body: some View {
        VStack(spacing: 0) {
            videoLayer
            analysisSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedVideoURL {
                ShareSheet(items: [url])
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .alert("Export Error", isPresented: .constant(exportError != nil)) {
            Button("OK") { exportError = nil }
        } message: {
            if let error = exportError { Text(error) }
        }
        .onChange(of: state.videoProgress) { progress in
            if progress >= 1.0 {
                exportVideo()
            }
        }
        .onChange(of: state.trophyFramePosition) { newVal in
            handleTrophyEvent()
        }
        .onChange(of: state.serveFramePosition) { newVal in
            handleServeEvent()
        }
    }
    
    private var videoLayer: some View {
        ZStack(alignment: .top) {
            
            AICameraViewRepresentable(
                videoURL: resolvedVideoURL,
                frame: UIScreen.main.bounds,
                controller: $controller,
                angle: selectedAngle
            )
            .frame(height: showHeroBanner
                   ? UIScreen.main.bounds.height * 0.4
                   : UIScreen.main.bounds.height * 0.7)
            .clipped()
            .shadow(color: .black.opacity(0.18), radius: 14, y: 4)
            .onAppear {
                print("📦 [AICoachScreen] Received selectedAngle:", selectedAngle)
                handleVideoAppear()
            }
            
            
            if showHeroBanner {
                floatingBanner
            }
            
            VStack {
                Spacer()
                TrophyTimelineBar(progress: state.videoProgress)
                    .frame(height: 7)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)
            }
        }
        .id("videoLayer")
    }
    
    private var floatingBanner: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "figure.tennis")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.blue)
                
                Text(observation == "Trophy" ? "Trophy Pose Detected" : "Serve Detected")
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .shadow(radius: 10)
            .padding(.leading, 80)
            .padding(.top, -50)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(999)
    }
    
    private var analysisSection: some View {
        Group {
            if showHeroBanner {
                analysisCardContent
            }
        }
    }
    
    private var analysisCardContent: some View {
        ZStack(alignment: .bottom) {
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    
                    if let img = trophyFrameThumbnail {
                        snapshotHeader(image: Image(uiImage: img))
                            .padding(.top, 12)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                            .font(.headline)
                        
                        Text("Clay's insights")
                            .font(.title3.weight(.semibold))
                            .fontDesign(.rounded)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // ---------------------------------------------------------
                        // ✨ NEW LOGIC FOR 1 POSITIVE + 1 NEGATIVE OR 2 NEGATIVES
                        // ---------------------------------------------------------
                        ForEach(displayedFeedback, id: \.text) { item in
                            feedbackBubble(text: item.text, isPositive: item.isPositive)
                                .opacity(animateFeedback ? 1 : 0)
                                .offset(y: animateFeedback ? 0 : 8)
                                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: animateFeedback)
                                .onTapGesture {
                                    let newValue = !showOverlay
                                    showOverlay = newValue
                                    controller?.updateDarkeningVisibility(forceVisible: newValue)
                                }

                        }


                    }
                }
                .padding(30)
                .padding(.bottom, 180)
                .blur(radius: 0.001)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 18, y: -6)
            )
            .onAppear { animateFeedback = true }
            
            VStack(spacing: 12) {
                Spacer()
                continueButton
            }
        }
    }
    
    
    private var displayedFeedback: [(text: String, isPositive: Bool)] {
        // Clean arrays → remove blank or whitespace-only entries
        let positives = state.positiveFeedbackArray.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let negatives = state.feedbackArray.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        // CASE 1 → We have positive feedback
        if let pos = positives.first {
            if let neg = negatives.first {
                return [
                    (text: pos, isPositive: true),
                    (text: neg, isPositive: false)
                ]
            } else {
                return positives
                    .prefix(2)
                    .map { (text: $0, isPositive: true) }
            }
        }

        // CASE 2 → No positives → show two negatives
        return negatives
            .prefix(2)
            .map { (text: $0, isPositive: false) }
    }
    
    func updateDarkeningVisibility(forceVisible: Bool? = nil) {

        if let force = forceVisible {
            controller?.darkeningLayer.isHidden = !force
            return
        }
    }




    
    private var continueButton: some View {
        Button(action: {
            controller?.continuePlayback()
            showOverlay = false
            controller?.updateDarkeningVisibility(forceVisible: false)
            withAnimation(.spring()) { showHeroBanner = false }
        }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.headline.weight(.semibold))
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3.weight(.semibold))
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(22)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
    }
    
    private func handleVideoAppear() {
        if let url = initialVideoURL {
            print("⚡️ [AI] Using pre-downloaded local file:", url.lastPathComponent)
            self.resolvedVideoURL = url
        } else {
            recoverVideoFromAsset()
        }
    }
    
    private func handleTrophyEvent() {
        guard state.trophyFramePosition != nil else { return }
        
        observation = "Trophy"
        controller?.startContinuousLayoutUpdates(duration: 0.6)
        
        withAnimation(.spring()) { showHeroBanner = true }
    }
    
    private func handleServeEvent() {
        guard state.serveFramePosition != nil else { return }
        
        observation = "Serve"
        controller?.startContinuousLayoutUpdates(duration: 0.6)
        
        withAnimation(.spring()) { showHeroBanner = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                showAnalysisCard = true
            }
        }
    }
    
    
    
    private func recoverVideoFromAsset() {
        print("🔁 [AI] Recovering video from asset ID:", assetLocalIdentifier)
        
        let assets = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetLocalIdentifier],
            options: nil
        )
        
        guard let asset = assets.firstObject else {
            print("❌ [AI] PHAsset not found")
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            
            guard let urlAsset = avAsset as? AVURLAsset else {
                print("❌ [AI] Failed to obtain AVURLAsset")
                return
            }
            
            let fm = FileManager.default
            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safeURL = docs.appendingPathComponent("ai_\(UUID().uuidString).mov")
            
            do {
                try fm.copyItem(at: urlAsset.url, to: safeURL)
                
                DispatchQueue.main.async {
                    print("✅ [AI] Video recovered to:", safeURL.lastPathComponent)
                    self.resolvedVideoURL = safeURL
                }
                
            } catch {
                print("❌ [AI] File recovery failed:", error.localizedDescription)
            }
        }
    }
    
    
    
    // MARK: - Export Function
    
    private func exportVideo() {
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finalURL = documentsPath.appendingPathComponent("ClayTennis_Export_\(Date().timeIntervalSince1970).mp4")
        
        
        print("🧪 [AI EXPORT] Export disabled by design")
        print("🧪 [AI EXPORT] Generated placeholder URL:", finalURL)
        print("🧪 [AI EXPORT] File exists at URL:", FileManager.default.fileExists(atPath: finalURL.path))
        
        
        let feedItem = FeedItem(
            type: .aiCoach,
            date: Date(),
            thumbnailURL: resolvedVideoURL,
            assetLocalIdentifier: assetLocalIdentifier,
            title: "AI Coach Analysis",
            subtitle: "Serve technique insights",
            primaryMetricText: "\(state.feedbackArray.count + state.positiveFeedbackArray.count) tips",
            secondaryMetricText: nil,
            fastestSpeedKmh: nil,
            serveCount: nil,

            aiTipCount: state.feedbackArray.count + state.positiveFeedbackArray.count,
            aiTips: state.feedbackArray,
            aiTipsDetailed: state.feedbackArrayDetailed,
            positiveAITips: state.positiveFeedbackArray,
            keyword: state.keywordArray,
            side: selectedAngle.title,

            quizTopicKey: nil,
            quizDifficulty: nil,
            quizCorrectAnswers: nil,
            quizTotalQuestions: nil
        )

        
        
        var items = (try? JSONDecoder().decode(
            [FeedItem].self,
            from: UserDefaults.standard.data(forKey: "FeedItems") ?? Data()
        )) ?? []
        
        items.append(feedItem)
        
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "FeedItems")
        }
        
        NotificationCenter.default.post(
            name: .feedItemCreated,
            object: feedItem
        )
        
        /*
         print("🚀 Export button tapped")
         print("🚀 Controller exists: \(controller != nil)")
         print("🚀 VideoCoachRenderView exists: \(controller?.VideoCoachRenderView != nil)")
         
         isExporting = true
         
         controller?.exportCurrentVideo { [self] url in
         print("🚀 Export callback received")
         print("🚀 URL: \(String(describing: url))")
         
         DispatchQueue.main.async {
         self.isExporting = false
         
         if let tempURL = url {
         // Copy to a more accessible location
         let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
         let finalURL = documentsPath.appendingPathComponent("ClayTennis_Export_\(Date().timeIntervalSince1970).mp4")
         
         do {
         // Remove existing file if it exists
         if FileManager.default.fileExists(atPath: finalURL.path) {
         try FileManager.default.removeItem(at: finalURL)
         }
         
         // Copy temp file to documents
         try FileManager.default.copyItem(at: tempURL, to: finalURL)
         
         print("✅ File copied to: \(finalURL)")
         
         self.exportedVideoURL = finalURL
         self.showShareSheet = true
         } catch {
         print("❌ Failed to copy file: \(error)")
         self.exportError = "Failed to prepare video for sharing: \(error.localizedDescription)"
         }
         } else {
         print("❌ Export failed - showing error")
         self.exportError = "Failed to export video. Please try again."
         }
         }
         }
         */
    }
    
    // MARK: - SNAPSHOT HEADER
    
    private func snapshotHeader(image: Image) -> some View {
        HStack(spacing: 14) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipped()
                .cornerRadius(14)
                .shadow(radius: 6)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Trophy Pose Identified")
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                
                Text("Racket up, elbow high, knees engaged")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
    }
    
    // MARK: - FEEDBACK BUBBLE
    
    private func feedbackBubble(text: String, isPositive: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            
            Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isPositive ? .green : .orange)
                .font(.subheadline)
            
            Text(text)
                .font(.callout)
                .fontDesign(.rounded)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(
            (colorScheme == .dark
             ? Color.white.opacity(0.08)
             : Color.white.opacity(0.14))
        )
        .overlay(
            Rectangle()
                .frame(width: 3)
                .foregroundColor(isPositive ? .green.opacity(0.55) : .orange.opacity(0.55)),
            alignment: .leading
        )
        .cornerRadius(12)
    }
    
}
    
    
    // MARK: - TIMELINE BAR
    
    struct TrophyTimelineBar: View {
        var progress: CGFloat
        
        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.25))
                    
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
        }
    }
    
    
    
    // MARK: - CORNER EXT
    
    struct RoundedCorner: Shape {
        var radius: CGFloat = .infinity
        var corners: UIRectCorner = .allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
    
    extension View {
        func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
            clipShape(RoundedCorner(radius: radius, corners: corners))
        }
    }
    
    
    // MARK: - WRAPPER
    
    struct AICameraViewRepresentable: UIViewControllerRepresentable {
        var videoURL: URL?
        var frame: CGRect
        @Binding var controller: AIcameraViewController?
        var angle: ServeCameraAngle
        
        func makeUIViewController(context: Context) -> AIcameraViewController {
            let vc = AIcameraViewController(frame: frame)
            if let url = videoURL { vc.setupWithVideoURL(url) }
            DispatchQueue.main.async { self.controller = vc }
            return vc
        }
        
        func updateUIViewController(_ uiViewController: AIcameraViewController, context: Context) {
            uiViewController.updateLayout(frame: frame)
            uiViewController.serveAngle = angle
            
            if let videoURL {
                print("🔄 [AI VIEW] Updating controller with video:", videoURL.lastPathComponent)
                uiViewController.setupWithVideoURL(videoURL)
            } else {
                print("⚠️ [AI VIEW] updateUIViewController called with NIL videoURL")
            }
        }
        
    }
    
    
    // MARK: - DETAILS VIEW
    
    struct AICoachDetailsView: View {
        var details: [String]
        
        var body: some View {
            List {
                ForEach(details, id: \.self) { d in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(d)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Detailed Analysis")
        }
    }
    
    
    // MARK: - Share Sheet
    
    struct ShareSheet: UIViewControllerRepresentable {
        let items: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            // For file URLs, we need to ensure they're accessible
            let activityItems: [Any] = items.map { item in
                if let url = item as? URL {
                    // Return the URL directly - iOS will handle it
                    return url
                }
                return item
            }
            
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            
            // Exclude some activities that don't make sense for videos
            controller.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .print
            ]
            
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
