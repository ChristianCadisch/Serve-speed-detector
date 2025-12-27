//
//  RecordingSetupView.swift
//  Instruction pages on how to set up the recording

import Foundation
import SwiftUI
import AVKit
import AVFoundation

struct SpeedRecordingSetupView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var isCameraErrorSource = false
    @Environment(\.dismiss) private var dismiss
    private let totalPages = 4

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
                        title: NSLocalizedString("recording_page1_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("recording_page1_desc", tableName: "general", comment: ""),
                        size: CGSize(width: 300, height: 300),
                        cornerRadius: 30
                    )
                    .tag(0)

                    // PAGE 2 — COURT DIAGRAM
                    OnboardingPage(
                        name: "setup",
                        isSystemImage: false,
                        title: NSLocalizedString("recording_page2_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("recording_page2_desc", tableName: "general", comment: ""),
                        size: CGSize(width: 300, height: 300),
                        cornerRadius: 30
                    )
                    .tag(1)

                    // PAGE 3 — GOOD EXAMPLE VIDEO
                    RecordingSetupVideoPage(
                        remoteURL: "example_serve",
                        title: NSLocalizedString("recording_page3_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("recording_page3_desc", tableName: "general", comment: "")
                    )
                    .tag(2)
                    
                    // PAGE 4 - SlowMo
                    OnboardingPage(
                        name: "timelapse",
                        isSystemImage: true,
                        title: NSLocalizedString(
                            "onboarding_camera_settings_title",
                            tableName: "general",
                            comment: ""
                        ),
                        description: NSLocalizedString(
                            "onboarding_camera_settings_description",
                            tableName: "general",
                            comment: ""
                        ),
                        size: CGSize(width: 300, height: 300),
                        cornerRadius: 30
                    )

                    .tag(3)
                    
                }
                .gesture(swipeDownToDismiss)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let isTap =
                                abs(value.translation.width) < 5 &&
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
                    .padding(.bottom,
                             (currentPage == totalPages - 1 ? 10 : -20)
                    )

                    // CLOSE BUTTON
                    if currentPage == totalPages - 1 {
                        Button {
                            isPresented = false
                            dismiss()
                        } label: {
                            Text(NSLocalizedString("recording_setup_done", tableName: "general", comment: ""))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 0)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
    }
    
    private var swipeDownToDismiss: some Gesture {
        DragGesture()
            .onEnded { value in
                // Strong downward intent
                if value.translation.height > 120 &&
                   abs(value.translation.width) < 80 {
                    isPresented = false
                    dismiss()
                }
            }
    }

}


struct TechniqueRecordingSetupView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var isCameraErrorSource = false
    @Environment(\.dismiss) private var dismiss
    private let totalPages = 3

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                TabView(selection: $currentPage) {

                    // PAGE 1 — SIDE VS BACK
                    // PAGE 1 — SIDE VS BACK
                    OnboardingPage(
                        name: "mode",
                        isSystemImage: false,
                        title: NSLocalizedString(
                            "onboarding_angle_selection_title",
                            tableName: "general",
                            comment: ""
                        ),
                        description: NSLocalizedString(
                            "onboarding_angle_selection_description",
                            tableName: "general",
                            comment: ""
                        ),
                        size: CGSize(width: 350, height: 300),
                        cornerRadius: 30
                    )
                    .tag(0)


                    // PAGE 2 — CAMERA POSITION
                    // PAGE 2 — CAMERA POSITION
                    OnboardingPage(
                        name: "player_visual",
                        isSystemImage: false,
                        title: NSLocalizedString(
                            "onboarding_recording_position_title",
                            tableName: "general",
                            comment: ""
                        ),
                        description: NSLocalizedString(
                            "onboarding_recording_position_description",
                            tableName: "general",
                            comment: ""
                        ),
                        size: CGSize(width: 300, height: 300),
                        cornerRadius: 30
                    )
                    .tag(1)



                    // PAGE 3 — UNDERSTAND FEEDBAK
                    // PAGE 3 — UNDERSTAND FEEDBACK
                    OnboardingPage(
                        name: "feedback_detail",
                        isSystemImage: false,
                        title: NSLocalizedString(
                            "onboarding_understand_feedback_title",
                            tableName: "general",
                            comment: ""
                        ),
                        description: NSLocalizedString(
                            "onboarding_understand_feedback_description",
                            tableName: "general",
                            comment: ""
                        ),
                        size: CGSize(width: 200, height: 200),
                        cornerRadius: 30
                    )
                    .tag(2)


                    
                }
                .gesture(swipeDownToDismiss)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let isTap =
                                abs(value.translation.width) < 5 &&
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
                    .padding(.bottom,
                             (currentPage == totalPages - 1 ? 10 : -20)
                    )

                    // CLOSE BUTTON
                    if currentPage == totalPages - 1 {
                        Button {
                            isPresented = false
                            dismiss()
                        } label: {
                            Text(NSLocalizedString("recording_setup_done", tableName: "general", comment: ""))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 0)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
    }
    
    private var swipeDownToDismiss: some Gesture {
        DragGesture()
            .onEnded { value in
                // Strong downward intent
                if value.translation.height > 120 &&
                   abs(value.translation.width) < 80 {
                    isPresented = false
                    dismiss()
                }
            }
    }

}





struct RecordingSetupVideoPage: View {
    let remoteURL: String
    let title: String
    let description: String
    var frame_height: CGFloat = 260

    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            if let player = player {
                AspectFillVideoPlayer(player: player)
                    .frame(height: frame_height)
                    .clipped()
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
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}




#Preview {
    TechniqueRecordingSetupView(isPresented: .constant(true))
}
