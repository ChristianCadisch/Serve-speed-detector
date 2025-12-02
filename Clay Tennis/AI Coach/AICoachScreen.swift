//
//  AICoachScreen.swift
//  Clay Tennis
//
//  Created by Christian on 01.12.2025.
//  Improved UI Version
//

import SwiftUI
import AVFoundation

// MARK: - MAIN COACH SCREEN

struct AICoachScreen: View {
    @ObservedObject var state = GameStateObserver.shared
    
    var videoURL: URL
    @State private var controller: AIcameraViewController? = nil
    @State private var showHeroBanner = false
    @State private var animateFeedback = false
    @State private var trophyFrameThumbnail: UIImage? = nil
    @State private var showAnalysisCard = false
    @State private var observation = ""
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .top) {
                
                // VIDEO
                AICameraViewRepresentable(
                    videoURL: videoURL,
                    frame: UIScreen.main.bounds,
                    controller: $controller
                )
                .frame(height: showHeroBanner ? UIScreen.main.bounds.height * 0.4 : UIScreen.main.bounds.height * 0.7)
                .clipped()
                .shadow(color: .black.opacity(0.18), radius: 14, y: 4)
                
                // TOP FLOATING HERO BANNER
                if showHeroBanner {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "figure.tennis")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.blue)
                            
                            if observation == "Trophy" {
                                Text("Trophy Pose Detected")
                                    .font(.headline.weight(.semibold))
                                    .fontDesign(.rounded)
                            }else {
                                Text("Serve Detected")
                                    .font(.headline.weight(.semibold))
                                    .fontDesign(.rounded)
                            }
                            
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(18)
                        .shadow(radius: 10)
                        .padding(.leading, 80)  // Push it to the right of back button
                        .padding(.top, -50)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
                
                // TIMELINE + MARKERS
                VStack {
                    Spacer()
                    TrophyTimelineBar(
                        progress: state.videoProgress
                    )
                    .frame(height: 7)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)
                }
            }
            .id("videoLayer")
            
            // ANALYSIS CARD
                        if showHeroBanner {
                            ZStack(alignment: .bottom) {
                                ScrollView(.vertical, showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        
                                        // SNAPSHOT HEADER (thumbnail)
                                        if let img = trophyFrameThumbnail {
                                            snapshotHeader(image: Image(uiImage: img))
                                                .padding(.top, 12)
                                        }
                                        
                                        // INTRO SECTION
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkles")
                                                .foregroundColor(.blue)
                                                .font(.headline)
                                            
                                            Text("Clay's insights")
                                                .font(.title3.weight(.semibold))
                                                .fontDesign(.rounded)
                                        }
                                        
                                        
                                        
                                        // FEEDBACK BUBBLES
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(state.feedbackArray.prefix(2), id: \.self) { item in
                                                feedbackBubble(text: item)
                                                    .opacity(animateFeedback ? 1 : 0)
                                                    .offset(y: animateFeedback ? 0 : 8)
                                                    .animation(
                                                        .spring(response: 0.45, dampingFraction: 0.85),
                                                        value: animateFeedback
                                                    )
                                            }
                                            
                                        }
                                        
                                    }
                                    .padding(30)
                                    .padding(.bottom, 120) // Space for button
                                    .blur(radius: 0.001)
                                }
                                .padding(.top, 0)
                                .background(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.15), radius: 18, y: -6)
                                )
                                .onAppear {
                                    animateFeedback = true
                                }
                                
                                // CONTINUE BUTTON (floating over scroll)
                                VStack {
                                    Spacer()
                                    Button(action: {
                                        controller?.setOverlayVisible(true)
                                        controller?.continuePlayback()
                                        withAnimation(.spring()) {
                                            showHeroBanner = false
                                        }
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
                            }
                            
                        }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: state.trophyFramePosition) { newVal in
            guard newVal != nil else { return }
            
            controller?.setOverlayVisible(false)
            self.observation = "Trophy"
            withAnimation(.spring()) {
                showHeroBanner = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    showAnalysisCard = true
                }
            }
        }
        .onChange(of: state.serveFramePosition) { newVal in
            guard newVal != nil else { return }
            
            controller?.setOverlayVisible(false)
            self.observation = "Serve"
            withAnimation(.spring()) {
                showHeroBanner = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    showAnalysisCard = true
                }
            }
        }
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
    
    private func feedbackBubble(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)   // smaller icon
            
            Text(text)
                .font(.callout)       // tighter text
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
                .foregroundColor(.blue.opacity(0.55)),
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
    
    func makeUIViewController(context: Context) -> AIcameraViewController {
        let vc = AIcameraViewController(frame: frame)
        if let url = videoURL { vc.setupWithVideoURL(url) }
        DispatchQueue.main.async { self.controller = vc }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AIcameraViewController, context: Context) {}
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


// MARK: - PREVIEW

struct AICoachScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AICoachScreen(
                videoURL: Bundle.main.url(forResource: "sample", withExtension: "mp4") ?? URL(fileURLWithPath: "")
            )
        }
    }
}
