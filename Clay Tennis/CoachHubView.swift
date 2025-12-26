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
    @State private var pendingRecordAfterAngleSelection = false

    private let hasSeenSpeedSetupKey = "hasSeenSpeedRecordingSetup"
    private let hasSeenTechniqueSetupKey = "hasSeenTechniqueRecordingSetup"

    let latestTechniqueItem: FeedItem?

    let recordAction: () -> Void
    let uploadAction: () -> Void

    // ✅ NEW: parent-provided replay hook (URL-based, like FeedView)
    let onReplayServe: (URL) -> Void

    let latestFocusTitle: String?
    let latestFocusStrength: String?
    let latestFocusCorrection: String?

    // Speed mode data
    let lastServeSpeed: Double?  // in km/h

    private var recentServeItems: [FeedItem] {
        FeedItemStorage
            .load()
            .filter { $0.type == .serve }
            .sorted { $0.date < $1.date }
            .suffix(10)
    }

    private var recentServeSpeeds: [Double] {
        recentServeItems.compactMap { $0.fastestSpeedKmh }
    }

    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 28) {
            
            header
            
            modeSelector
            
            
            actionButtons
            
            if selectedMode == .technique && hasInsight {
                coachingFocusCard
            } else if selectedMode == .speed && lastServeSpeed != nil {
                ServeSpeedTrendCard(
                    speeds: recentServeItems.compactMap { $0.fastestSpeedKmh },
                    onSelectIndex: { index in
                        print("🎾 [Serve Trend] Selected index:", index)
                    },
                    onReplayServe: { index in
                        guard
                            index < recentServeItems.count,
                            let url = recentServeItems[index].thumbnailURL
                        else {
                            print("❌ [CoachHub] Missing serve URL for replay")
                            return
                        }

                        print("🎬 [CoachHub] Replaying serve:", url.lastPathComponent)
                        onReplayServe(url)
                    }
                )
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
                .onDisappear {
                    if pendingRecordAfterAngleSelection {
                        pendingRecordAfterAngleSelection = false
                        recordAction()
                    }
                }
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
            
            pendingRecordAfterAngleSelection = true
            showAngleSelectionSheet = false
        }  label: {
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
            Button {
                print("🎯 [CoachHub] Opening AI Coach detail for:", item.id)
                NotificationCenter.default.post(
                    name: .showAICoachDetail,
                    object: item
                )
            } label: {
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
            }
            .buttonStyle(.plain)
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





// MARK: - Enhanced Serve Speed Trend Card with Detail Overlay

struct ServeSpeedTrendCard: View {
    
    let speeds: [Double]
    let onSelectIndex: (Int) -> Void
    let onReplayServe: (Int) -> Void  // NEW: callback for replay
    
    @State private var selectedIndex: Int? = nil
    @State private var showDetailOverlay = false
    
    private let yAxisSteps = 4
    
    private var maxSpeed: Double {
        max((speeds.max() ?? 0) * 1.05, 1)
    }
    
    private var minSpeed: Double {
        max((speeds.min() ?? 0) * 0.95, 0)
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("SERVE SPEED TREND")
                    .font(.caption.bold())
                    .tracking(1)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .top, spacing: 12) {
                    
                    yAxisLabels
                    
                    VStack(spacing: 6) {
                        ZStack {
                            graphFill
                            graphLine
                            graphPoints
                        }
                        .frame(height: 150)
                        
                        xAxisLabels
                    }
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            )
            .blur(radius: showDetailOverlay ? 2 : 0)
            .animation(.easeInOut(duration: 0.2), value: showDetailOverlay)
            
            // Detail Overlay
            if showDetailOverlay, let index = selectedIndex {
                serveDetailOverlay(for: index)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
            }
        }
    }
    
    // MARK: - Detail Overlay
    
    private func serveDetailOverlay(for index: Int) -> some View {
        let speed = speeds[index]
        let isPersonalBest = speed == speeds.max()
        let avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
        let improvement = speed - avgSpeed
        
        return ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDetailOverlay = false
                    }
                }
            
            // Detail Card
            VStack(spacing: 0) {
                
                // Header with close button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SERVE #\(index + 1)")
                            .font(.caption.bold())
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(Int(speed))")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("km/h")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDetailOverlay = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary, .quaternary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Stats Grid
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        statPill(
                            icon: "chart.line.uptrend.xyaxis",
                            label: "vs Average",
                            value: improvement >= 0
                            ? "+\(Int(improvement)) km/h"
                            : "\(Int(improvement)) km/h",
                            color: improvement >= 0 ? .green : .orange
                        )
                        
                        if isPersonalBest {
                            statPill(
                                icon: "trophy.fill",
                                label: "Personal Best",
                                value: "🎾",
                                color: .yellow
                            )
                        }
                    }
                    
                    if index > 0 {
                        let previousSpeed = speeds[index - 1]
                        let change = speed - previousSpeed
                        
                        statPill(
                            icon: change >= 0 ? "arrow.up.right" : "arrow.down.right",
                            label: "vs Previous",
                            value: change >= 0
                            ? "+\(Int(change)) km/h"
                            : "\(Int(change)) km/h",
                            color: change >= 0 ? .blue : .secondary
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Replay Button
                    Button {
                        onReplayServe(index)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDetailOverlay = false
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                            
                            Text("Watch Replay")
                                .font(.headline.weight(.semibold))
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.callout.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                    
                    // Secondary Action
                    Button {
                        // Could add share/export functionality here
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.callout)
                            
                            Text("Share Result")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(.secondary)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
            )
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Stat Pill
    
    private func statPill(
        icon: String,
        label: String,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemFill))
        )
    }
    
    // MARK: - Y Axis
    
    private var yAxisLabels: some View {
        VStack {
            ForEach((0...yAxisSteps).reversed(), id: \.self) { step in
                let value = minSpeed + (maxSpeed - minSpeed) * Double(step) / Double(yAxisSteps)
                
                Text("\(Int(value))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(height: 150 / CGFloat(yAxisSteps))
            }
        }
    }
    
    // MARK: - X Axis
    
    private var xAxisLabels: some View {
        HStack {
            ForEach(speeds.indices, id: \.self) { index in
                Text(index == speeds.count - 1 ? "Now" : "\(index + 1)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Line
    
    private var graphLine: some View {
        GeometryReader { geo in
            Path { path in
                let points = points(in: geo.size)
                guard let first = points.first else { return }
                path.move(to: first)
                for p in points.dropFirst() {
                    path.addLine(to: p)
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
    }
    
    // MARK: - Fill
    
    private var graphFill: some View {
        GeometryReader { geo in
            Path { path in
                let points = points(in: geo.size)
                guard let first = points.first else { return }
                
                path.move(to: CGPoint(x: first.x, y: geo.size.height))
                path.addLine(to: first)
                
                for p in points.dropFirst() {
                    path.addLine(to: p)
                }
                
                path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.25),
                        Color.cyan.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MARK: - Points (Interactive)
    
    private var graphPoints: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            
            ZStack {
                ForEach(pts.indices, id: \.self) { index in
                    let isSelected = selectedIndex == index
                    let point = pts[index]
                    
                    Circle()
                        .fill(isSelected ? Color.blue : Color.white)
                        .frame(
                            width: isSelected ? 14 : 8,
                            height: isSelected ? 14 : 8
                        )
                        .shadow(
                            color: isSelected ? .blue.opacity(0.6) : .clear,
                            radius: 6
                        )
                        .position(point)
                        .zIndex(isSelected ? 1 : 0)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let tapLocation = value.location
                        
                        guard let closestIndex = pts.enumerated().min(by: { a, b in
                            let distA = hypot(a.element.x - tapLocation.x, a.element.y - tapLocation.y)
                            let distB = hypot(b.element.x - tapLocation.x, b.element.y - tapLocation.y)
                            return distA < distB
                        })?.offset else { return }
                        
                        let distance = hypot(
                            pts[closestIndex].x - tapLocation.x,
                            pts[closestIndex].y - tapLocation.y
                        )
                        
                        if distance < 30 {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedIndex = closestIndex
                                showDetailOverlay = true
                            }
                            onSelectIndex(closestIndex)
                        }
                    }
            )
        }
    }
    
    // MARK: - Helpers
    
    private func points(in size: CGSize) -> [CGPoint] {
        guard speeds.count > 1 else { return [] }
        
        return speeds.enumerated().map { index, speed in
            let x = size.width * CGFloat(index) / CGFloat(speeds.count - 1)
            let normalized = (speed - minSpeed) / max(maxSpeed - minSpeed, 1)
            let y = size.height * (1 - CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }
    }
}


// MARK: - Updated Preview

#Preview("Serve Speed Trend with Detail") {
    ServeSpeedTrendCard(
        speeds: [
            142, 148, 151, 149, 155,
            158, 160, 162, 159, 165
        ],
        onSelectIndex: { index in
            print("Selected serve #\(index + 1)")
        },
        onReplayServe: { index in
            print("🎬 Replaying serve #\(index + 1)")
        }
    )
    .padding()
    .background(Color(.systemBackground))
}

