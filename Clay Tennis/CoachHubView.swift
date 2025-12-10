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
            
            // Only show angle chip in technique mode
            if selectedMode == .technique {
                angleChip
            }
            
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
    }
    
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SERVE")
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(.secondary)
            
            Text("Training Hub")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
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

    
    
    // MARK: - Angle Chip
    
    private var angleChip: some View {
        HStack(spacing: 8) {

            angleButton(.side)
            angleButton(.back)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    private func angleButton(_ angle: ServeCameraAngle) -> some View {
        Button(action: {
            print("🎥 [CoachHub] Tapped angle:", angle)
            detectedAngle = angle
        }) {
            Text(angle.title.uppercased())
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(detectedAngle == angle ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        detectedAngle == angle
                        ? LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
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
        VStack(spacing: 12) {
            Button(action: {
                print("🎥 [CoachHub] Record tapped — selectedMode:", selectedMode)
                recordAction()
            }) {
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

enum AngleSource {
    case auto
    case manual
}


