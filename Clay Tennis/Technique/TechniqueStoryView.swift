//
//  TechniqueStoryView.swift
//  Clay Tennis
//
//  Created by Christian on 19.11.2025.
//  Copyright © 2025 Apple.
//

import Foundation
import SwiftUI

struct TechniqueStoryView: View {
    let stories: [Story]

    @State private var currentIndex: Int = 0
    @State private var progress: CGFloat = 0
    @State private var isPaused: Bool = false
    @State private var timer: Timer?

    private let storyDuration: TimeInterval = 4.0
    private let progressRefreshRate: TimeInterval = 0.02

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {

                stories[currentIndex].background
                    .ignoresSafeArea()

                // --- PROGRESS BARS AT THE VERY TOP ---
                progressBars
                    .padding(.top, 6)
                    .padding(.horizontal, 12)

                // --- CONTENT ---
                VStack {
                    Spacer().frame(height: 50) // space for bars + back button

                    VStack(spacing: 12) {
                        Text(stories[currentIndex].title)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        if let subtitle = stories[currentIndex].subtitle {
                            Text(subtitle)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }

                        Text(stories[currentIndex].text)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                    Spacer()
                }

                // --- TAP ZONES ---
                tapZones(width: geo.size.width)
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - PROGRESS BARS

    private var progressBars: some View {
        HStack(spacing: 6) {
            ForEach(0..<stories.count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.25))

                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * currentProgress(for: i))
                    }
                }
                .frame(height: 4)
            }
        }
    }

    private func currentProgress(for index: Int) -> CGFloat {
        if index < currentIndex { return 1 }
        if index > currentIndex { return 0 }
        return progress
    }

    // MARK: - TAP ZONES

    private func tapZones(width: CGFloat) -> some View {
        ZStack {
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { previousStory() }

                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { nextStory() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())

        // 1. Swipe gesture
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -40 {
                        nextStory()
                    } else if value.translation.width > 40 {
                        previousStory()
                    }
                }
        )

        // 2. Tap + hold pause gesture (Instagram style)
        .onLongPressGesture(
            minimumDuration: 0.15,
            maximumDistance: 10,
            pressing: { pressing in
                if pressing {
                    pauseStory()
                } else {
                    resumeStory()
                }
            },
            perform: {}
        )
    }



    // MARK: - TIMER

    private func startTimer() {
        timer?.invalidate()
        progress = 0

        timer = Timer.scheduledTimer(withTimeInterval: progressRefreshRate, repeats: true) { _ in
            guard !isPaused else { return }

            progress += CGFloat(progressRefreshRate / storyDuration)

            if progress >= 1 {
                nextStory()
            }
        }
    }

    private func pauseStory() { isPaused = true }
    private func resumeStory() { isPaused = false }

    private func nextStory() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            timer?.invalidate()
        }
    }

    private func previousStory() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        }
    }
}

// MARK: - STORY MODEL

struct Story: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let text: String
    let background: Color
}

#Preview {
    TechniqueStoryView(stories: tacticsStories)
}
