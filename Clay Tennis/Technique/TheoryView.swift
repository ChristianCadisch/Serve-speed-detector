//
//  TheoryView.swift
//  Clay Tennis
//
//  Created by Christian on 19.11.2025.
//  Copyright © 2025 Apple.
//

import SwiftUI

extension View {
    func mirroredHorizontally(_ shouldMirror: Bool) -> some View {
        self.scaleEffect(x: shouldMirror ? -1 : 1, y: 1, anchor: .center)
    }
}

enum QuizIdentifier: Int, CaseIterable, Hashable {
    case serve
    case tactics
    case forehand
    case backhand
    case volley
    case legwork

    static let progression: [QuizIdentifier] = [
        .serve, .tactics, .forehand, .backhand, .volley, .legwork
    ]

    var title: String {
        switch self {
        case .serve: return "Serve"
        case .tactics: return "Tactics"
        case .forehand: return "Forehand"
        case .backhand: return "Backhand"
        case .volley: return "Volley"
        case .legwork: return "Leg Work"
        }
    }

    var iconName: String {
        switch self {
        case .serve: return "figure.tennis"
        case .tactics: return "lightbulb"
        case .forehand, .backhand: return "tennis.racket"
        case .volley: return "arrow.forward.circle"
        case .legwork: return "figure.run"
        }
    }

    var isMirrored: Bool {
        self == .backhand
    }

    var questions: [QuizQuestion] {
        switch self {
        case .serve: return serveQuestions
        case .tactics: return tacticsQuestions
        case .forehand: return forehandQuestions
        case .backhand: return backhandQuestions
        case .volley: return volleyQuestions
        case .legwork: return legworkQuestions
        }
    }

    var stories: [Story] {
        switch self {
        case .serve: return serveStories
        case .tactics: return tacticsStories
        case .forehand: return forehandStories
        case .backhand: return backhandStories
        case .volley: return volleyStories
        case .legwork: return legworkStories
        }
    }

    var totalQuestions: Int {
        questions.count
    }

    var progressionIndex: Int {
        Self.progression.firstIndex(of: self) ?? 0
    }

    var userDefaultsKey: String {
        "QuizHighScore_\(progressionIndex)"
    }

    func state(highScores: [QuizIdentifier: Int]) -> LessonState {
        let index = self.progressionIndex

        if index == 0 {
            let score = highScores[self, default: 0]
            return score >= totalQuestions ? .completed : .unlocked
        }

        let previousQuiz = Self.progression[index - 1]
        let previousScore = highScores[previousQuiz, default: 0]

        if previousScore < previousQuiz.totalQuestions {
            return .locked
        }

        let score = highScores[self, default: 0]
        return score >= totalQuestions ? .completed : .unlocked
    }
}

enum LessonState {
    case locked
    case unlocked
    case completed
}

struct TheoryView: View {

    @Environment(\.dismiss) var dismiss
    @State private var highScores: [QuizIdentifier: Int] = [:]

    private let quizzes = QuizIdentifier.progression

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    featuredCard

                    VStack(spacing: 14) {
                        ForEach(quizzes, id: \.self) { quiz in
                            let state = quiz.state(highScores: highScores)

                            LockableLessonRow(
                                quiz: quiz,
                                state: state
                            )
                        }
                    }
                }
                .padding(.top, 16)
            }
            .navigationTitle("Technique")
            .onAppear {
                loadHighScores()
            }
        }
    }

    private var featuredQuiz: QuizIdentifier {
        quizzes.first { quizProgress(for: $0) < 1.0 } ?? quizzes.last!
    }

    private var featuredCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended")
                .font(.headline)
                .padding(.horizontal)

            NavigationLink {
                TechniqueStoryView(stories: featuredQuiz.stories)
            } label: {
                VStack(spacing: 18) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: featuredQuiz.iconName)
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                                .mirroredHorizontally(featuredQuiz.isMirrored)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(featuredQuiz.title)
                                .font(.title3.bold())

                            Text("Continue your progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    QuizProgressCardBar(
                        quiz: featuredQuiz,
                        highScore: highScores[featuredQuiz, default: 0],
                        total: featuredQuiz.totalQuestions
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
    }

    private func quizProgress(for quiz: QuizIdentifier) -> Double {
        let score = highScores[quiz, default: 0]
        guard quiz.totalQuestions > 0 else { return 0 }
        return Double(score) / Double(quiz.totalQuestions)
    }

    private func loadHighScores() {
        var loaded: [QuizIdentifier: Int] = [:]

        for quiz in QuizIdentifier.allCases {
            let score = UserDefaults.standard.integer(forKey: quiz.userDefaultsKey)
            loaded[quiz] = score
        }

        highScores = loaded

        print("📥 Loaded high scores:")
        for quiz in QuizIdentifier.progression {
            let score = loaded[quiz, default: 0]
            let total = quiz.totalQuestions
            let progress = total == 0 ? 0 : Double(score) / Double(total)
            print("• \(quiz.title): \(score)/\(total) → \(progress)")
        }
    }

    func updateHighScore(for quiz: QuizIdentifier, newScore: Int) {
        let current = highScores[quiz, default: 0]

        guard newScore > current else {
            print("ℹ️ Score \(newScore) did not beat high score \(current)")
            return
        }

        highScores[quiz] = newScore
        UserDefaults.standard.set(newScore, forKey: quiz.userDefaultsKey)

        print("✅ New high score for \(quiz.title): \(newScore)")
    }
}

struct LockableLessonRow: View {
    let quiz: QuizIdentifier
    let state: LessonState

    @State private var showLockedAlert = false

    var body: some View {
        Group {
            if state == .locked {
                rowContent
                    .onTapGesture {
                        showLockedAlert = true
                    }
            } else {
                NavigationLink {
                    TechniqueStoryView(stories: quiz.stories)
                } label: {
                    rowContent
                }
            }
        }
        .alert("Training Locked", isPresented: $showLockedAlert) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text(lockReasonText)
        }
    }

    private var lockReasonText: String {
        if let index = QuizIdentifier.progression.firstIndex(of: quiz),
           index > 0 {
            let previous = QuizIdentifier.progression[index - 1]
            return "Complete the \(previous.title) quiz to unlock \(quiz.title)."
        } else {
            return "This training is currently locked."
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(state == .locked ? Color.gray.opacity(0.15) : Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: quiz.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(state == .locked ? .gray : .blue)
                    .mirroredHorizontally(quiz.isMirrored)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.headline)
                    .foregroundColor(state == .locked ? .gray : .primary)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            indicator
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .opacity(state == .locked ? 0.6 : 1)
        .padding(.horizontal)
    }

    private var statusText: String {
        switch state {
        case .locked: return "Locked"
        case .unlocked: return "Unlocked"
        case .completed: return "Completed"
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .locked:
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)

        case .unlocked:
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)

        case .completed:
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
        }
    }
}

struct QuizProgressCardBar: View {
    let quiz: QuizIdentifier
    let highScore: Int
    let total: Int

    private var progress: Double {
        total == 0 ? 0 : Double(highScore) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: progress >= 0.8 ? [.green, .mint] : [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Solved \(highScore)/\(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if progress >= 1.0 {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
    }
}

