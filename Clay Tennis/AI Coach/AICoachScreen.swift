//
//  AICoachScreen.swift
//  Clay Tennis
//
//  Created by Christian on 01.12.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

// MARK: - MAIN COACH SCREEN

struct AICoachScreen: View {
    @ObservedObject var state = GameStateObserver()

    var videoURL: URL
    @State private var controller: AIcameraViewController? = nil

    var body: some View {
        VStack(spacing: 0) {

            // Video + pose overlay
            AICameraViewRepresentable(
                videoURL: videoURL,
                frame: UIScreen.main.bounds,
                controller: $controller
            )
            .frame(height: UIScreen.main.bounds.height * 0.55)
            .clipped()

            // Feedback block
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    Text("Hey James,")
                        .font(.title2.bold())
                        .padding(.top, 8)

                    Text("Solid Trophy Pose! Let’s analyze it:")
                        .font(.headline)

                    ForEach(state.feedbackArray, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)

                            Text(item)
                                .font(.body)
                        }
                    }

                    if !state.feedbackArrayDetailed.isEmpty {
                        NavigationLink {
                            AICoachDetailsView(details: state.feedbackArrayDetailed)
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.top, 16)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
        Button(action: {
            controller?.continuePlayback()
        }) {
            HStack {
                Spacer()
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding()
                Spacer()
            }
            .background(Color.blue.opacity(0.8))
            .cornerRadius(12)
        }
        .padding(.top, 12)

        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SWIFTUI WRAPPER

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

    func updateUIViewController(_ uiViewController: AIcameraViewController, context: Context) {
        /*
        if let url = videoURL {
            uiViewController.setupWithVideoURL(url)
        }
        */
    }
    
    func continueVideo() {
        controller?.continuePlayback()
    }

}

// MARK: - DETAILS VIEW

struct AICoachDetailsView: View {
    var details: [String]

    var body: some View {
        List {
            ForEach(details, id: \.self) { detail in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)

                    Text(detail)
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
