//
//  TheoryView.swift
//  Clay Tennis
//
//  Created by Christian on 19.11.2025.
//  Copyright © 2025 Apple.
//

import SwiftUI

struct TheoryView: View {

    @Environment(\.dismiss) var dismiss
    @State private var highScores: [LessonQuizID: Int] = [:]

    private let topics = QuizIdentifier.progression

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    featuredCard

                    VStack(spacing: 14) {
                        ForEach(topics, id: \.self) { topic in
                            NavigationLink {
                                LessonDetailView(
                                    topic: topic,
                                    highScores: highScores,
                                    onHighScoreUpdated: updateHighScore(for:newScore:)
                                )
                            } label: {
                                LessonRow(
                                    topic: topic,
                                    highScores: highScores
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .navigationTitle("Technique")
            .onAppear { loadHighScores() }
        }
    }

    private var featuredLessonQuiz: LessonQuizID {
        for topic in topics {
            for difficulty in QuizDifficulty.allCases {
                let id = LessonQuizID(topic: topic, difficulty: difficulty)
                let score = highScores[id, default: 0]
                let total = topic.totalQuestions(for: difficulty)
                if total == 0 || score < total {
                    return id
                }
            }
        }
        return LessonQuizID(topic: topics.last!, difficulty: .hard)
    }

    private var featuredCard: some View {
        let id = featuredLessonQuiz
        let topic = id.topic
        let difficulty = id.difficulty
        let score = highScores[id, default: 0]
        let total = topic.totalQuestions(for: difficulty)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Recommended")
                .font(.headline)
                .padding(.horizontal)

            NavigationLink {
                LessonDetailView(
                    topic: topic,
                    highScores: highScores,
                    onHighScoreUpdated: updateHighScore(for:newScore:)
                )
            } label: {
                VStack(spacing: 18) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: topic.iconName)
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                                .mirroredHorizontally(topic.isMirrored)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(topic.title)
                                .font(.title3.bold())

                            Text("\(difficulty.title) quiz up next")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    QuizProgressCardBar(
                        quizTitle: "\(topic.title) · \(difficulty.title)",
                        highScore: score,
                        total: total
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

    private func loadHighScores() {
        var loaded: [LessonQuizID: Int] = [:]

        for topic in QuizIdentifier.allCases {
            for difficulty in QuizDifficulty.allCases {
                let id = LessonQuizID(topic: topic, difficulty: difficulty)
                loaded[id] = UserDefaults.standard.integer(forKey: id.userDefaultsKey)
            }
        }

        highScores = loaded

        print("📥 Loaded high scores:")
        for topic in topics {
            for difficulty in QuizDifficulty.allCases {
                let id = LessonQuizID(topic: topic, difficulty: difficulty)
                let score = loaded[id, default: 0]
                let total = topic.totalQuestions(for: difficulty)
                let progress = total == 0 ? 0 : Double(score) / Double(total)
                print("• \(topic.title) \(difficulty.title): \(score)/\(total) → \(progress)")
            }
        }
    }

    func updateHighScore(for id: LessonQuizID, newScore: Int) {
        let current = highScores[id, default: 0]
        guard newScore > current else { return }

        highScores[id] = newScore
        UserDefaults.standard.set(newScore, forKey: id.userDefaultsKey)

        print("✅ New high score for \(id.topic.title) \(id.difficulty.title): \(newScore)")
    }
}


// UPDATED LessonRow to show overall topic completion
struct LessonRow: View {
    let topic: QuizIdentifier
    let highScores: [LessonQuizID: Int]

    private func score(for difficulty: QuizDifficulty) -> Int {
        highScores[LessonQuizID(topic: topic, difficulty: difficulty), default: 0]
    }

    private func total(for difficulty: QuizDifficulty) -> Int {
        topic.totalQuestions(for: difficulty)
    }

    private var isTopicCompleted: Bool {
        QuizDifficulty.allCases.allSatisfy { d in
            let t = total(for: d)
            return t == 0 || score(for: d) >= t
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: topic.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .mirroredHorizontally(topic.isMirrored)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.headline)

                Text(isTopicCompleted ? "Completed" : "Tap to open")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isTopicCompleted ? "checkmark.seal.fill" : "chevron.right")
                .foregroundColor(isTopicCompleted ? .green : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}


// NEW: per-difficulty state inside a topic
enum DifficultyState {
    case locked
    case unlocked
    case completed
}


struct QuizProgressCardBar: View {
    let quizTitle: String
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
                Text("\(quizTitle) · \(highScore)/\(total)")
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






extension View {
    func mirroredHorizontally(_ shouldMirror: Bool) -> some View {
        self.scaleEffect(x: shouldMirror ? -1 : 1, y: 1, anchor: .center)
    }
}

#Preview {
    let mockTopic: QuizIdentifier = .serve

    let mockScores: [LessonQuizID: Int] = [
        LessonQuizID(topic: .serve, difficulty: .easy): 5,
        LessonQuizID(topic: .serve, difficulty: .medium): 2,
        LessonQuizID(topic: .serve, difficulty: .hard): 0,

        LessonQuizID(topic: .tactics, difficulty: .easy): 3,
        LessonQuizID(topic: .tactics, difficulty: .medium): 0,
        LessonQuizID(topic: .tactics, difficulty: .hard): 0
    ]

    return NavigationStack {
        TheoryView()
            .onAppear {
                // Inject mock data by writing to UserDefaults for Preview
                for (id, score) in mockScores {
                    UserDefaults.standard.set(score, forKey: id.userDefaultsKey)
                }
            }
    }
}
