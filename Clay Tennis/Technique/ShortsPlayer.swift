//
//  ShortsPlayer.swift
//  Clay Tennis
//
//  Fullscreen short-form video player
//  Auto-dismisses when playback ends
//

import WebKit
import SwiftUI
import Foundation
import Observation


// MARK: - ShortsPlayer

struct ShortsPlayer: View {

    let videoId: String
    let youtubeId: String
    let title: String
    let subtitle: String

    @State private var isVisible = true

    @Environment(\.dismiss) private var dismiss

    // Clay Tennis accent
    private let accentGreen = Color.green.opacity(0.85)


    var body: some View {
        ZStack {

            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Subtitle only (editorial hint)
                Text(subtitle.uppercased())
                    .font(.caption.weight(.medium))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                // MARK: - Video Card
                ZStack {

                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(
                            color: Color.black.opacity(0.12),
                            radius: 32,
                            y: 18
                        )

                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentGreen.opacity(0.9),
                                    accentGreen.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )

                    YouTubeWebView(
                        youtubeId: youtubeId,
                        isVisible: isVisible
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(6)
                }
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

            }
        }
        .onAppear {
            isVisible = true
            WatchedVideoStore.shared.markWatched(videoId)
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - YouTube WebView Wrapper

struct YouTubeWebView: UIViewRepresentable {

    let youtubeId: String
    let isVisible: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator

        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.allowsBackForwardNavigationGestures = false

        context.coordinator.webView = webView

        let url = URL(string: "https://www.youtube.com/shorts/\(youtubeId)")!
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if isVisible {
            context.coordinator.play(webView)
        } else {
            context.coordinator.pause(webView)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {

        weak var webView: WKWebView?
        private var pageLoaded = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pageLoaded = true
            disableYouTubeNavigation(webView)
        }

        func play(_ webView: WKWebView) {
            guard pageLoaded else { return }

            webView.evaluateJavaScript("""
            document.querySelectorAll('video').forEach(v => {
                v.muted = false;
                v.volume = 1.0;
                if (v.paused) {
                    v.play().catch(() => {});
                }
            });
            """)
        }

        func pause(_ webView: WKWebView) {
            guard pageLoaded else { return }

            webView.evaluateJavaScript("""
            document.querySelectorAll('video').forEach(v => v.pause());
            """)
        }

        private func disableYouTubeNavigation(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
            document.documentElement.style.overflow = 'hidden';
            document.body.style.overflow = 'hidden';

            document.addEventListener('touchmove', function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, { passive: false });

            document.addEventListener('wheel', function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, { passive: false });
            """)
        }
    }

}

// MARK: - Watched Video Store

@Observable
final class WatchedVideoStore {

    static let shared = WatchedVideoStore()

    private let storageKey = "WatchedTrainingVideos"
    private(set) var watchedIDs: Set<String> = []

    private init() {
        load()
    }

    func markWatched(_ id: String) {
        guard !watchedIDs.contains(id) else { return }
        watchedIDs.insert(id)
        persist()
    }

    func isWatched(_ id: String) -> Bool {
        watchedIDs.contains(id)
    }

    private func load() {
        let ids = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        watchedIDs = Set(ids)
    }

    private func persist() {
        UserDefaults.standard.set(Array(watchedIDs), forKey: storageKey)
    }
}




// MARK: - Preview

#Preview {
    ShortsPlayer(
        videoId: "gagii",
        youtubeId: "QdiU1ElVxb8",
    title: "hoi",
    subtitle: "du")
}
