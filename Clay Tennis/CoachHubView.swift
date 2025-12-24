//
//  CoachHub.swift
//  Clay Tennis
//
//  Created by Christian on 08.12.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct CoachHubView: View {
    
    // MARK: - Public State (inject from parent)
    
    @Binding var selectedMode: ServeMode           // .speed | .technique
    @Binding var detectedAngle: ServeCameraAngle   // .side | .back
    @Binding var angleDetectionSource: AngleSource // .auto | .manual
    @State private var activeSetupMode: ServeMode?
    @State private var showAngleSelectionSheet = false


    private let hasSeenSpeedSetupKey = "hasSeenSpeedRecordingSetup"
    private let hasSeenTechniqueSetupKey = "hasSeenTechniqueRecordingSetup"

    let latestTechniqueItem: FeedItem?

    let recordAction: () -> Void
    let uploadAction: () -> Void
    
    let latestFocusTitle: String?
    let latestFocusStrength: String?
    let latestFocusCorrection: String?
    
    // Speed mode data
    let lastServeSpeed: Double?  // in km/h
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 28) {
            
            header
            
            modeSelector
            
            
            actionButtons
            
            if selectedMode == .technique && hasInsight {
                coachingFocusCard
            } else if selectedMode == .speed && lastServeSpeed != nil {
                lastServeCard
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(item: $activeSetupMode) { mode in
            switch mode {
            case .speed:
                SpeedRecordingSetupView(isPresented: Binding(
                    get: { activeSetupMode != nil },
                    set: { _ in activeSetupMode = nil }
                ))
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: hasSeenSpeedSetupKey)
                }

            case .technique:
                TechniqueRecordingSetupView(isPresented: Binding(
                    get: { activeSetupMode != nil },
                    set: { _ in activeSetupMode = nil }
                ))
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: hasSeenTechniqueSetupKey)
                }
            }
        }
        .sheet(isPresented: $showAngleSelectionSheet) {
            angleSelectionSheet
        }


    }
    
    
    
    
    private var angleSelectionSheet: some View {
        VStack(spacing: 22) {

            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("How was your video filmed?")
                    .font(.headline.weight(.semibold))

                HStack(spacing: 6) {
                    Text("This helps the AI analyze your serve correctly")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        activeSetupMode = .technique
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }


            VStack(spacing: 12) {

                angleSelectionButton(
                    angle: .side,
                    title: "Filmed from the side",
                    subtitle: "Best for knee bend & trophy pose"
                )

                angleSelectionButton(
                    angle: .back,
                    title: "Filmed from the back",
                    subtitle: "Best for arm path & pronation"
                )
            }

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 22)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    
    private func angleSelectionButton(
        angle: ServeCameraAngle,
        title: String,
        subtitle: String
    ) -> some View {

        Button {
            print("🎥 [CoachHub] Selected angle:", angle)

            detectedAngle = angle
            angleDetectionSource = .manual

            showAngleSelectionSheet = false
            recordAction()
        } label: {
            HStack(spacing: 16) {

                Image(systemName: angle == .side ? "figure.walk" : "figure.stand")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }


    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SERVE")
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        HStack(spacing: 10) {
            
            modeButton(.speed)
            modeButton(.technique)
            
            Spacer()
        }
    }
    
    private func modeButton(_ mode: ServeMode) -> some View {
        Button(action: {
            print("🟡 [CoachHub] Tapped mode:", mode)
            print("🟡 [CoachHub] Current selectedMode:", selectedMode)
            
            selectedMode = mode
            
            print("🟢 [CoachHub] New selectedMode:", selectedMode)
        }) {
            Text(mode.title.uppercased())
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(selectedMode == mode ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(
                        selectedMode == mode
                        ? (
                            mode == .technique
                            ? LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                          )
                        : LinearGradient(
                            colors: [Color(.tertiarySystemBackground), Color(.tertiarySystemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                )
        }
        .buttonStyle(.plain)
    }

    
    
    
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 10) {

            // PRIMARY CTA
            Button(action: {
                print("🎥 [CoachHub] Record tapped — selectedMode:", selectedMode)

                switch selectedMode {

                case .speed:
                    if !UserDefaults.standard.bool(forKey: hasSeenSpeedSetupKey) {
                        activeSetupMode = .speed
                    } else {
                        recordAction()
                    }

                case .technique:
                    if !UserDefaults.standard.bool(forKey: hasSeenTechniqueSetupKey) {
                        activeSetupMode = .technique
                    } else {
                        showAngleSelectionSheet = true
                    }
                }
            })  {
                HStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.title3.weight(.semibold))
                    
                    Text(recordButtonTitle)
                        .font(.headline.weight(.semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [
                            selectedMode == .speed ? .blue : .purple,
                            selectedMode == .speed ? .cyan : .pink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            // CONTEXTUAL HELP LINK
            Button {
                activeSetupMode = selectedMode
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("How to set up your phone")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            }

            .buttonStyle(.plain)
        }
    }


    
    private var recordButtonTitle: String {
        switch selectedMode {
        case .speed:     return "Measure Serve Speed"
        case .technique: return "Get Technique Feedback"
        }
    }
    
    private var uploadButtonTitle: String {
        switch selectedMode {
        case .speed:     return "Upload Speed Serve"
        case .technique: return "Upload Technique Serve"
        }
    }
    
    
    // MARK: - Last Serve Card (Speed Mode)
    
    private var lastServeCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            Text("LAST SERVE")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let speed = lastServeSpeed {
                    Text("\(Int(speed))")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("km/h")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)

                Text(selectedSlogan)
                    .font(.body.weight(.medium))

                Spacer()
            }
            .onAppear {
                selectedSlogan = powerSlogans.randomElement() ?? "Great power!"
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    
    @State private var selectedSlogan = ""
    private let powerSlogans = [
        "Great power!",
        "Huge pop on contact!",
        "Explosive acceleration!",
        "Lightning-fast racket speed!"
    ]


    
    
    // MARK: - Coaching Focus Card (Technique Mode)
    
    private var coachingFocusCard: some View {

        guard let item = latestTechniqueItem else { return AnyView(EmptyView()) }

        let positive = item.positiveAITips.first
        let negative = item.aiTips.first

        return AnyView(
            VStack(alignment: .leading, spacing: 18) {

                Text("CURRENT FOCUS")
                    .font(.caption.bold())
                    .tracking(1)
                    .foregroundStyle(.secondary)

                Text(item.title)
                    .font(.title2.weight(.semibold))

                if let p = positive {
                    insightRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: p
                    )
                }

                if let n = negative {
                    insightRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        text: n
                    )
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        )
    }
    
    

    
    private func insightRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text(text)
                .font(.body.weight(.medium))
            
            Spacer()
        }
    }
    
    
    // MARK: - Helpers
    
    private var hasInsight: Bool {
        latestFocusTitle != nil ||
        latestFocusStrength != nil ||
        latestFocusCorrection != nil ||
        latestTechniqueItem != nil
    }
}


// MARK: - Supporting Types

enum ServeMode: String {
    case speed
    case technique
    
    var title: String {
        switch self {
        case .speed: return "Speed"
        case .technique: return "Technique"
        }
    }
}

extension ServeMode: Identifiable {
    var id: String { rawValue }
}


enum ServeCameraAngle: String {
    case side
    case back
    
    var title: String {
        switch self {
        case .side: return "Side View"
        case .back: return "Back View"
        }
    }
}

extension ServeCameraAngle {
    init?(feedSide: String?) {
        guard let feedSide else { return nil }
        self.init(rawValue: feedSide)
    }
}
extension ServeCameraAngle {
    init?(storedValue: String?) {
        guard let value = storedValue?.lowercased() else { return nil }
        self.init(rawValue: value)
    }
}



enum AngleSource {
    case auto
    case manual
}


// MARK: - Preview

#Preview {
    CoachHubView(
        selectedMode: .constant(.speed),
        detectedAngle: .constant(.side),
        angleDetectionSource: .constant(.auto),
        latestTechniqueItem: nil,
        recordAction: {},
        uploadAction: {},
        latestFocusTitle: "Trophy Position",
        latestFocusStrength: "Good shoulder rotation",
        latestFocusCorrection: "Raise your tossing arm longer",
        lastServeSpeed: 172
    )
}
