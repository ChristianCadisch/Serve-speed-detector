//
//  RecordingSetupView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 16.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation


import SwiftUI
import AVKit
import AVFoundation


struct RecordingSetupView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    private let totalPages = 3

    private let placeholder =
        "https://gostanford.com/imgproxy/Pfw3Gktmf2EAVTLYtpVERtWC7HYZUTMcp6JxVItTKog/rs:fit:1980:0:0:0/g:ce:0:0/q:90/aHR0cHM6Ly9zdG9yYWdlLmdvb2dsZWFwaXMuY29tL3N0YW5mb3JkLXByb2QvMjAyNS8xMS8xMS82MEdiQ2Y3NnlPNmZUZU1vYlN3VlFhRFlIcVR6ZkxoWjFnbHZJRjlFLmpwZw.jpg"

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                TabView(selection: $currentPage) {

                    // PAGE 1 — PHONE AGAINST WATER BOTTLE
                    OnboardingPage(
                        name: "phone_on_bottle",
                        isSystemImage: false,
                        title: "Place Your Phone Securely",
                        description:
                        "Lean your phone against a water bottle or your bag. The camera must remain completely still — handheld recordings won't work",
                        size: CGSize(width: 300, height: 300),
                        cornerRadius: 30
                    )
                    .tag(0)

                    // PAGE 2 — COURT DIAGRAM
                    OnboardingPage(
                        name: "setup",
                        isSystemImage: false,
                        title: "Correct Camera Position",
                        description:
                        "Place the phone at the back corner of the court. Make sure the player and landing area are both visible",
                        size: CGSize(width: 300, height: 300),
                        cornerRadius: 30
                    )
                    .tag(1)

                    // PAGE 3 — GOOD EXAMPLE VIDEO
                    RecordingSetupVideoPage(
                        remoteURL: "example_serve",
                        title: "Example of a Good Recording",
                        description:
                        "Your video should clearly show the full serve: the toss, impact, trajectory, and the landing point on the opposite side"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let isTap = abs(value.translation.width) < 5 &&
                                        abs(value.translation.height) < 5
                            guard isTap else { return }

                            let midX = geo.size.width / 2
                            if value.startLocation.x >= midX {
                                if currentPage < totalPages - 1 {
                                    withAnimation { currentPage += 1 }
                                }
                            } else if currentPage > 0 {
                                withAnimation { currentPage -= 1 }
                            }
                        }
                )


                VStack {
                    Spacer()

                    // PAGE INDICATORS
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage
                                      ? Color.accentColor
                                      : Color.secondary.opacity(0.4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    .padding(.bottom, currentPage == totalPages - 1 ? 20 : 60)


                    // CLOSE BUTTON
                    if currentPage == totalPages - 1 {
                        Button {
                            isPresented = false
                        } label: {
                            Text("Done")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 40)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}


struct RecordingSetupVideoPage: View {
    let remoteURL: String
    let title: String
    let description: String
    
    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            if let player = player {
                AspectFillVideoPlayer(player: player)
                    .frame(height: 260)
                    .clipped()               // ensure overflow cropping
                    .cornerRadius(16)
                    .onAppear {
                        player.play()
                        player.actionAtItemEnd = .none
                        
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            }

            Text(title)
                .font(.largeTitle)
                .bold()

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .onAppear {
            if player == nil,
               let url = Bundle.main.url(forResource: remoteURL, withExtension: "mov") {
                player = AVPlayer(url: url)
            }
        }
    }
}




struct AspectFillVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill   // ← KEY FIX
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}





#Preview {
    RecordingSetupView(isPresented: .constant(true))
}
