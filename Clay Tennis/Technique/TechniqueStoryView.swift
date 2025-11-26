//
//  TechniqueStoryView.swift
//  Clay Tennis
//
//  Story view with quiz-style gradients + topic colors + improved readability
//

import Foundation
import SwiftUI

struct TechniqueStoryView: View {
    let stories: [Story]
    let topic: QuizIdentifier

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentIndex: Int = 0
    @State private var progress: CGFloat = 0
    @State private var isPaused: Bool = false
    @State private var timer: Timer?

    private let storyDuration: TimeInterval = 4.0
    private let progressRefreshRate: TimeInterval = 0.02

    // MARK: - Topic Color

    private var topicAccent: Color {
        topic.tintColor
    }

    // MARK: - Readability Colors

    private var primaryText: Color {
        colorScheme == .dark ? .white : .white
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.85) : .white.opacity(0.85)
    }

    private var overlayOpacity: Double {
        colorScheme == .dark ? 0.35 : 0.25
    }

    private var barBackground: Color {
        Color.white.opacity(0.25)
    }

    private var barForeground: Color {
        Color.white
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {

                // --- Topic Gradient Background ---
                LinearGradient(
                    colors: [
                        topicAccent.opacity(0.9),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // --- Contrast overlay for readability ---
                LinearGradient(
                    colors: [
                        Color.black.opacity(overlayOpacity),
                        Color.black.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // --- PROGRESS BARS ---
                progressBars
                    .padding(.top, 6)
                    .padding(.horizontal, 12)

                // --- STORY CONTENT ---
                VStack {
                    Spacer().frame(height: 80)

                    VStack(spacing: 12) {
                        Text(stories[currentIndex].title)
                            .font(.largeTitle.bold())
                            .foregroundColor(primaryText)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                        if let subtitle = stories[currentIndex].subtitle {
                            Text(subtitle)
                                .font(.headline)
                                .foregroundColor(secondaryText)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                        }

                        Text(stories[currentIndex].text)
                            .font(.body)
                            .foregroundColor(primaryText.opacity(0.95))
                            .padding(.top, 4)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                    Spacer()
                }

                // --- INTERACTION ZONES ---
                tapZones(width: geo.size.width)
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Progress Bars

    private var progressBars: some View {
        HStack(spacing: 6) {
            ForEach(0..<stories.count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(barBackground)

                        Capsule()
                            .fill(barForeground)
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

    // MARK: - Tap Zones + Gestures

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

        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 80 {
                        timer?.invalidate()
                        dismiss()
                        return
                    }

                    if value.translation.width < -40 {
                        nextStory()
                    } else if value.translation.width > 40 {
                        previousStory()
                    }
                }
        )

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

    // MARK: - Timer Logic

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
            dismiss()
        }
    }

    private func previousStory() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        }
    }
}

// MARK: - Story Model

struct Story: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let text: String
    let background: Color
}


// MARK: - Preview

#Preview {
    TechniqueStoryView(
        stories: [
            Story(
                title: "Why the Serve Matters",
                subtitle: "You start in green",
                text: "The serve is the only stroke you control 100%. It starts every point and decides initiative. Great servers use it not just for speed, but for positioning and point construction.",
                background: Color.blue
            ),
            Story(
                title: "Build Pressure",
                subtitle: "Dictate the point",
                text: "A good serve doesn’t need to be an ace. It just needs to create advantage.",
                background: Color(red: 0.1, green: 0.5, blue: 0.8)
            )
        ],
        topic: .serve
    )
}
