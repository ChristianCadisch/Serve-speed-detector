//
//  LessonDetailView.swift
//  Clay Tennis
//
//  Created by Christian on 23.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import SwiftUI

import SwiftUI

// MARK: - LessonDetailView (Enhanced Design)

struct LessonDetailView: View {
    let topic: QuizIdentifier
    @Binding var highScores: [LessonQuizID: Int]
    let onHighScoreUpdated: (LessonQuizID, Int) -> Void
    weak var navigationDelegate: HomeNavigationDelegate?

    private func id(_ d: QuizDifficulty) -> LessonQuizID {
        LessonQuizID(topic: topic, difficulty: d)
    }

    private func score(_ d: QuizDifficulty) -> Int {
        highScores[id(d), default: 0]
    }

    private func total(_ d: QuizDifficulty) -> Int {
        topic.totalQuestions(for: d)
    }

    private func state(_ d: QuizDifficulty) -> DifficultyState {
        let s = score(d)
        let t = total(d)
        if t > 0 && Double(s) / Double(t) >= 0.8 {
            return .completed
        }
        switch d {
        case .easy:
            return .unlocked
        case .medium:
            let easyDone = total(.easy) == 0 || score(.easy) >= total(.easy)
            return easyDone ? .unlocked : .locked
        case .hard:
            let mediumDone = total(.medium) == 0 || score(.medium) >= total(.medium)
            return mediumDone ? .unlocked : .locked
        }
    }

    private var totalCompletedLevels: Int {
        QuizDifficulty.allCases.filter { state($0) == .completed }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                headerSection

                storiesCard

                VStack(spacing: 14) {
                    ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyLevelCard(
                            topic: topic,
                            difficulty: difficulty,
                            state: state(difficulty),
                            highScore: score(difficulty),
                            total: total(difficulty),
                            onHighScoreUpdated: onHighScoreUpdated,
                            navigationDelegate: navigationDelegate
                        )
                    }
                }
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
        
    }

    // MARK: - Header with Progress Ring
    private var headerSection: some View {
        VStack(spacing: 10) {


            // Existing header content
            HStack(spacing: 18) {
                ProgressRing(
                    completed: totalCompletedLevels,
                    total: QuizDifficulty.allCases.count
                )
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.title)
                        .font(.title2.bold())

                    Text("\(totalCompletedLevels) of 3 quizzes completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Stories + 3 quizzes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Stories Card with Thumbnail
    private var storiesCard: some View {
        NavigationLink {
            TechniqueStoryView(stories: topic.stories,
            topic: topic)
        } label: {
            ZStack {
                Image(topic.thumbnailImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(20)

                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .cornerRadius(20)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(topic.title) Theory")
                            .font(.headline)
                            .foregroundColor(.white)


                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .padding()
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Level Card

// MARK: - Animated Difficulty Level Card

struct DifficultyLevelCard: View {
    let topic: QuizIdentifier
    let difficulty: QuizDifficulty
    let state: DifficultyState
    let highScore: Int
    let total: Int
    let onHighScoreUpdated: (LessonQuizID, Int) -> Void
    weak var navigationDelegate: HomeNavigationDelegate?

    @State private var showLockedAlert = false
    @State private var animatedProgress: Double = 0.0

    private var targetProgress: Double {
        total == 0 ? 0 : Double(highScore) / Double(total)
    }

    private var color: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .blue
        case .hard: return .purple
        }
    }

    var body: some View {
        Group {
            if state == .locked {
                cardContent
                    .onTapGesture { showLockedAlert = true }
            } else {
                Button {
                    navigationDelegate?.showQuiz(topic: topic, difficulty: difficulty)
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            animatedProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = targetProgress
                }
            }
        }
        .alert("Quiz Locked", isPresented: $showLockedAlert) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text(lockMessage)
        }
    }

    private var lockMessage: String {
        switch difficulty {
        case .medium: return "Solve Easy first to unlock Medium."
        case .hard: return "Solve Medium first to unlock Hard."
        case .easy: return "This quiz is locked."
        }
    }

    private var cardContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "checklist.checked")
                        .font(.system(size: 20))
                        .foregroundColor(state == .locked ? .gray : color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(difficulty.localizedTitle) Quiz")
                        .font(.headline)
                        .foregroundColor(state == .locked ? .gray : .primary)

                    Text(total == 0 ? "No questions" : "Solved \(highScore)/\(total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                switch state {
                case .locked:
                    Image(systemName: "lock.fill").foregroundColor(.gray)
                case .unlocked:
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                case .completed:
                    Image(systemName: "checkmark.seal.fill").foregroundColor(color)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * animatedProgress)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
        )
        .opacity(state == .locked ? 0.6 : 1)
        .padding(.horizontal)
    }
}


// MARK: - Progress Ring

struct ProgressRing: View {
    let completed: Int
    let total: Int

    @State private var animatedProgress: Double = 0.0

    private var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)

            Circle()
                .trim(from: 0.018, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .blue, .purple]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(completed)/\(total)")
                .font(.caption.bold())
        }
        .onAppear {
            animatedProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.9)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

/*
#Preview {
    let topic: QuizIdentifier = .serve

    let mockScores: [LessonQuizID: Int] = [
        LessonQuizID(topic: topic, difficulty: .easy): 2,
        LessonQuizID(topic: topic, difficulty: .medium): 2,
        LessonQuizID(topic: topic, difficulty: .hard): 0
    ]

    return NavigationStack {
        LessonDetailView(
            topic: topic,
            highScores: mockScores,
            onHighScoreUpdated: { _, _ in }
        )
    }
}
*/
