//
//  LongPlayer.swift
//  Clay Tennis
//
//  Fullscreen long-form YouTube player
//

import SwiftUI
import WebKit
import UIKit

struct LongPlayer: View {

    let youtubeId: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {

            Color.black
                .ignoresSafeArea()

            YouTubeEmbedView(youtubeId: youtubeId)
                .ignoresSafeArea()

            // MARK: - Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)

                    Spacer()
                }
                Spacer()
            }
        }
    }
}

//
// MARK: - YouTube Embed WebView
//

private struct YouTubeEmbedView: UIViewRepresentable {

    let youtubeId: String

    func makeUIView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        if #available(iOS 14.0, *) {
            config.allowsPictureInPictureMediaPlayback = true
        }

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        let html = embedHTML(for: youtubeId)

        webView.loadHTMLString(
            html,
            baseURL: URL(string: "https://www.youtube.com")
        )

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func embedHTML(for id: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html, body {
                    width: 100%;
                    height: 100%;
                    background-color: black;
                    overflow: hidden;
                }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&autoplay=0&rel=0&modestbranding=1"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
                frameborder="0">
            </iframe>
        </body>
        </html>
        """
    }
}


//
// MARK: - Orientation Manager
//

enum OrientationManager {

    static func lockLandscape() {
        let orientation = UIInterfaceOrientation.landscapeRight
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    static func unlockOrientation() {
        let orientation = UIInterfaceOrientation.portrait
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
}


#Preview {
    let longVideo = TrainingVideo(
        id: "serve_masterclass_beginners",
        youtubeId: "IiRGdagtOKE",
        category: "serve",
        title: "Serve Technique Masterclass for Beginners",
        durationSeconds: 780,
        type: "technique",
        level: "advanced",
        filetype: "longform"
    )

    return NavigationStack {
        LongPlayer(youtubeId: longVideo.youtubeId)
    }
}
