//
//  LessonDetailView.swift
//  Clay Tennis
//
//  Created by Christian on 23.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct LessonDetailView: View {
    let topic: QuizIdentifier
    let highScores: [LessonQuizID: Int]
    let onHighScoreUpdated: (LessonQuizID, Int) -> Void

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
        if t > 0 && s >= t { return .completed }

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

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                header

                storiesCard

                VStack(spacing: 12) {
                    ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyQuizCard(
                            topic: topic,
                            difficulty: difficulty,
                            state: state(difficulty),
                            highScore: score(difficulty),
                            total: total(difficulty),
                            onHighScoreUpdated: onHighScoreUpdated
                        )
                    }
                }
                .padding(.top, 4)

                Spacer(minLength: 24)
            }
            .padding(.top, 12)
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.opacity(0.02))
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: topic.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .mirroredHorizontally(topic.isMirrored)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(topic.title)
                    .font(.title2.bold())

                Text("Stories + 3 quizzes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private var storiesCard: some View {
        NavigationLink {
            TechniqueStoryView(stories: topic.stories)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Theory Stories")
                        .font(.headline)

                    Text("\(topic.stories.count) stories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}


struct DifficultyQuizCard: View {
    let topic: QuizIdentifier
    let difficulty: QuizDifficulty
    let state: DifficultyState
    let highScore: Int
    let total: Int
    let onHighScoreUpdated: (LessonQuizID, Int) -> Void

    @State private var showLockedAlert = false

    var body: some View {
        Group {
            if state == .locked {
                cardContent
                    .onTapGesture { showLockedAlert = true }
            } else {
                NavigationLink {
                    QuizView(
                        vm: QuizViewModel(questions: topic.questions(for: difficulty)),
                        quizID: topic,
                        onQuizFinished: { _, score in
                            onHighScoreUpdated(
                                LessonQuizID(topic: topic, difficulty: difficulty),
                                score
                            )
                        },
                        onFinish: { }
                    )
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(state == .locked ? Color.gray.opacity(0.15) : Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "checklist.checked")
                    .font(.system(size: 22))
                    .foregroundColor(state == .locked ? .gray : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(difficulty.title) Quiz")
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
                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .opacity(state == .locked ? 0.6 : 1)
        .padding(.horizontal)
    }
}
