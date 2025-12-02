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
    @State private var showHeroBanner = true
    @State private var animateFeedback = false
    @State private var trophyFrameThumbnail: UIImage? = nil

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
                .frame(height: UIScreen.main.bounds.height * 0.52)
                .clipped()
                .shadow(color: .black.opacity(0.18), radius: 14, y: 4)

                // TOP FLOATING HERO BANNER
                if showHeroBanner {
                    VStack(spacing: 6) {

                        HStack(spacing: 10) {
                            Image(systemName: "figure.tennis")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.blue)

                            Text("Trophy Pose Detected")
                                .font(.headline.weight(.semibold))
                                .fontDesign(.rounded)

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }

                        Text("Great position — here’s what I noticed.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)
                    .shadow(radius: 10)
                    .padding(.top, 30)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // TIMELINE + MARKERS
                VStack {
                    Spacer()
                    TrophyTimelineBar(
                        progress: state.videoProgress,
                        trophyMarker: state.trophyFramePosition ?? 0
                    )
                    .frame(height: 7)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)
                }
            }

            // ANALYSIS CARD
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {

                    // SNAPSHOT HEADER (thumbnail)
                    if let img = trophyFrameThumbnail {
                        snapshotHeader(image: Image(uiImage: img))
                            .padding(.top, 12)
                    }

                    // INTRO SECTION
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nice trophy pose, James 👏")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)

                        Text("Here’s what your motion looks like at the key moment:")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundColor(.secondary)
                    }

                    // FEEDBACK SECTION HEADER
                    Text("Breakdown")
                        .font(.title3.weight(.semibold))
                        .fontDesign(.rounded)
                        .padding(.top, 4)

                    // FEEDBACK BUBBLES
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(state.feedbackArray.indices, id: \.self) { idx in
                            feedbackBubble(text: state.feedbackArray[idx])
                                .opacity(animateFeedback ? 1 : 0)
                                .offset(y: animateFeedback ? 0 : 8)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.85)
                                        .delay(Double(idx) * 0.07),
                                    value: animateFeedback
                                )
                        }
                    }

                }
                .padding(30)
                .padding(.bottom, 110)
            }
            .background(
                (colorScheme == .dark
                 ? Color.black.opacity(0.92)
                 : Color(uiColor: .systemBackground).opacity(0.97))
                    .cornerRadius(28, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.14), radius: 12, y: -4)
            )
            .onAppear {
                loadThumbnail()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showHeroBanner = false
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animateFeedback = true
                    }
                }
            }

            // CTA SHEET
            VStack(spacing: 10) {

                // GRABBER
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 42, height: 5)
                    .padding(.top, 4)

                HStack(spacing: 16) {

                    NavigationLink(
                        destination: AICoachDetailsView(details: state.feedbackArrayDetailed)
                    ) {
                        Text("Details")
                            .font(.headline.bold())
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                            )
                    }

                    Button(action: {
                        controller?.continuePlayback()
                    }) {
                        Text("Continue")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.cornerRadius(14))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
        HStack(alignment: .top, spacing: 12) {

            // Accent Icon
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.body)
                    .fontDesign(.rounded)
            }
        }
        .padding(16)
        .background(
            (colorScheme == .dark
             ? Color.white.opacity(0.08)
             : Color.blue.opacity(0.08))
            .overlay(
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(.blue.opacity(0.65)),
                alignment: .leading
            )
            .cornerRadius(16)
        )
    }

    // MARK: - FRAME THUMBNAIL EXTRACTION

    private func loadThumbnail() {
        trophyFrameThumbnail = state.trophyFrameImage
    }
}


// MARK: - TIMELINE BAR

struct TrophyTimelineBar: View {
    var progress: CGFloat
    var trophyMarker: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {

                // BACKGROUND BAR
                Capsule()
                    .fill(Color.gray.opacity(0.25))

                // FILLED PROGRESS
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.85), Color.blue.opacity(0.55)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)

                // MOVING DOT
                Circle()
                    .fill(Color.blue)
                    .frame(width: 14, height: 14)
                    .offset(x: max(0, (geo.size.width * progress) - 7))

                // TROPHY MARKER
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 3, height: 14)
                    .cornerRadius(2)
                    .offset(x: geo.size.width * trophyMarker)
            }
        }
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
