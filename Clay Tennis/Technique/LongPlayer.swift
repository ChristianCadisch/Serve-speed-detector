//
//  LongPlayer.swift
//  Clay Tennis
//
//  Premium lesson-style UI for long-form videos.
//  Bullets only, bottom primary CTA, gradient style consistent with CoachHub.
//

import SwiftUI
import WebKit

// MARK: - Notification

extension Notification.Name {
    static let requestLongLessonFullscreen = Notification.Name("requestLongLessonFullscreen")
}

// MARK: - LongPlayer

struct LongPlayer: View {

    let videoId: String
    let youtubeId: String
    let title: String
    let subtitle: String
    let durationText: String
    let learningPoints: [String]
    private let progressThresholdCompletion = 0.0


    // Accent (match Clay Tennis theme)
    private let gradientColors: [Color] = [.green, .mint]

    var body: some View {
        ZStack {

            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Hero Poster (non-interactive)
                ZStack {

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 28, y: 18)

                    ZStack {
                        YouTubePosterWebView(youtubeId: youtubeId)
                            .allowsHitTesting(false) // ⬅️ non-interactive

                        // Demote YouTube chrome
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.55),
                                Color.black.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(6)
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // MARK: - Lesson Meta
                HStack {
                    VStack(alignment: .leading, spacing: 14) {

                        Text(subtitle.uppercased())
                            .font(.caption.bold())
                            .tracking(1)
                            .foregroundStyle(.secondary)

                        Text(title)
                            .font(.title2.weight(.semibold))

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                            Text(durationText)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                        // MARK: - Learning Bullets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You'll learn")
                                .font(.subheadline.weight(.semibold))

                            ForEach(learningPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(point)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                    
                    Spacer()  // ⬅️ Push everything to the left
                }
                .padding(.horizontal, 32)
                .padding(.top, 22)

                Spacer()

                // MARK: - Bottom Primary CTA (consistent style)
                Button {
                    NotificationCenter.default.post(
                        name: .requestLongLessonFullscreen,
                        object: nil
                    )
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title3.weight(.semibold))

                        Text("START LESSON")
                            .font(.headline.weight(.semibold))

                        Spacer()

                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 64)
                    .background(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
        .background(
            LongLessonFullscreenBridge(youtubeId: youtubeId, videoId: videoId)
                .opacity(0)
        )
    }
}

// MARK: - Poster WebView (static)

struct YouTubePosterWebView: UIViewRepresentable {

    let youtubeId: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = false

        let url = URL(string: "https://www.youtube.com/shorts/\(youtubeId)")!
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Fullscreen Bridge (same strategy as ShortsPlayer)

struct LongLessonFullscreenBridge: UIViewRepresentable {

    let youtubeId: String
    let videoId: String   // ✅ canonical ID from TrainingVideo.id

    func makeCoordinator() -> Coordinator {
        Coordinator(videoId: videoId)
    }

    func makeUIView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()

        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "progress")
        controller.add(context.coordinator, name: "completed")
        config.userContentController = controller

        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false

        context.coordinator.webView = webView

        let url = URL(string: "https://www.youtube.com/shorts/\(youtubeId)")!
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        weak var webView: WKWebView?
        private let videoId: String
        private var pageLoaded = false

        init(videoId: String) {
            self.videoId = videoId
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(enterFullscreen),
                name: .requestLongLessonFullscreen,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pageLoaded = true

            webView.evaluateJavaScript("""
            (function() {
                const video = document.querySelector('video');
                if (!video) return;

                video.addEventListener('timeupdate', () => {
                    if (!video.duration) return;
                    const progress = video.currentTime / video.duration;
                    window.webkit.messageHandlers.progress.postMessage(progress);
                });

                video.addEventListener('ended', () => {
                    window.webkit.messageHandlers.completed.postMessage(true);
                });
            })();
            """)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "progress",
               let value = message.body as? Double {

                LongLessonProgressStore.shared.updateProgress(
                    videoId: videoId,
                    progress: value
                )
            }

            if message.name == "completed" {
                LongLessonProgressStore.shared.markCompleted(videoId: videoId)
            }
        }

        @objc
        private func enterFullscreen() {
            guard pageLoaded, let webView else { return }

            webView.evaluateJavaScript("""
            (function() {
                const video = document.querySelector('video');
                if (!video) return;

                video.muted = false;
                video.volume = 1.0;

                const p = video.play();
                if (p !== undefined) {
                    p.then(() => video.webkitEnterFullscreen && video.webkitEnterFullscreen())
                     .catch(() => video.webkitEnterFullscreen && video.webkitEnterFullscreen());
                } else {
                    video.webkitEnterFullscreen && video.webkitEnterFullscreen();
                }
            })();
            """)
        }
    }
}





// MARK: - Preview

#Preview {
    LongPlayer(
        videoId: "hjoi",
        youtubeId: "IiRGdagtOKE",
        title: "Build a Reliable Tennis Serve from Scratch",
        subtitle: "Serve · Technique",
        durationText: "17 min",
        learningPoints: [
            "Correct continental grip",
            "Simple, repeatable service motion",
            "Building rhythm and consistency"
        ]
    )
}
