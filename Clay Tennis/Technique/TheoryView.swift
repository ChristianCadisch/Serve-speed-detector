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
    @State private var refreshToken = UUID()


    private let topics = QuizIdentifier.progression
    weak var navigationDelegate: HomeNavigationDelegate?

    var body: some View {
        
            ScrollView {
                VStack(spacing: 22) {

                    featuredCard

                    Text(NSLocalizedString("all_topics", tableName: "Quiz", comment: ""))
                        .font(.headline)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 14) {
                        ForEach(topics, id: \.self) { topic in
                            Button {
                                navigationDelegate?.showLessonDetail(
                                    topic: topic,
                                    highScores: $highScores,
                                    onHighScoreUpdated: updateHighScore(for:newScore:)
                                )
                            } label: {
                                LessonRow(
                                    topic: topic,
                                    highScores: highScores
                                )
                            }
                            .buttonStyle(PressableCardButtonStyle())

                        }
                    }
                }
                .padding(.top, 12)
            }
            .id(refreshToken)
            .navigationTitle(NSLocalizedString("technique_coach_title", tableName: "Quiz", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadHighScores() }
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        
    }
    
    func forceRefresh() {
        refreshToken = UUID()
    }

    
    private var featuredCard: some View {
        let id = featuredLessonQuiz
        let topic = id.topic
        let difficulty = id.difficulty
        let score = highScores[id, default: 0]
        let total = topic.totalQuestions(for: difficulty)
        let progress = total == 0 ? 0 : Double(score) / Double(total)

        return VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("recommended_lesson", tableName: "Quiz", comment: ""))
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                navigationDelegate?.showLessonDetail(
                    topic: topic,
                    highScores: $highScores,
                    onHighScoreUpdated: updateHighScore(for:newScore:)
                )
            } label: {

                ZStack(alignment: .bottomLeading) {

                    Image(topic.thumbnailImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 305)
                        .clipped()
                        .cornerRadius(24)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.05)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .cornerRadius(24)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(topic.tintColor.opacity(0.22))
                                    .frame(width: 58, height: 58)

                                Image(systemName: topic.iconName)
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .mirroredHorizontally(topic.isMirrored)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.title)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)

                                Text(
                                    String(
                                        format: NSLocalizedString("next_up", tableName: "Quiz", comment: ""),
                                        difficulty.localizedTitle
                                    )
                                )
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            Spacer()

                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HeroProgressBar(
                            progress: progress,
                            label: String(
                                format: NSLocalizedString("solved_counter_format", tableName: "Quiz", comment: ""),
                                score,
                                total
                            )
                        )
                    }
                    .padding()
                }
                .padding(.horizontal)
            }
            .buttonStyle(PressableCardButtonStyle())
        }
    }

    private func heroProgressBar(progress: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: progress >= 0.8 ? [.green, .mint] : [.white, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
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
            }
        }
    }

    func updateHighScore(for id: LessonQuizID, newScore: Int) {
        let current = highScores[id, default: 0]
        guard newScore > current else { return }

        highScores[id] = newScore
        UserDefaults.standard.set(newScore, forKey: id.userDefaultsKey)

    }
}



struct HeroProgressBar: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: progress >= 0.8
                                    ? [.green, .mint]
                                    : [.white, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}



// MARK: - UPDATED LessonRow (tiny dots + per-topic tint + nicer copy)

struct LessonRow: View {
    let topic: QuizIdentifier
    let highScores: [LessonQuizID: Int]

    private func score(for difficulty: QuizDifficulty) -> Int {
        highScores[LessonQuizID(topic: topic, difficulty: difficulty), default: 0]
    }

    private func total(for difficulty: QuizDifficulty) -> Int {
        topic.totalQuestions(for: difficulty)
    }

    private func dotState(_ d: QuizDifficulty) -> DifficultyState {
        let s = score(for: d)
        let t = total(for: d)
        if t > 0 && s >= t { return .completed }

        switch d {
        case .easy:
            return .unlocked
        case .medium:
            let easyDone = total(for: .easy) == 0 || score(for: .easy) >= total(for: .easy)
            return easyDone ? .unlocked : .locked
        case .hard:
            let mediumDone = total(for: .medium) == 0 || score(for: .medium) >= total(for: .medium)
            return mediumDone ? .unlocked : .locked
        }
    }

    private var isTopicCompleted: Bool {
        QuizDifficulty.allCases.allSatisfy { d in
            let t = total(for: d)
            return t == 0 || score(for: d) >= t
        }
    }

    private var nextDifficultyText: String {
        for d in QuizDifficulty.allCases {
            if dotState(d) != .completed {
                return String(
                    format: NSLocalizedString("next_up", tableName: "Quiz", comment: ""),
                    d.localizedTitle
                )
            }
        }
        return "Mastered"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(topic.tintColor.opacity(0.14))
                    .frame(width: 46, height: 46)

                Image(systemName: topic.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(topic.tintColor)
                    .mirroredHorizontally(topic.isMirrored)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.headline)

                Text(
                    isTopicCompleted
                    ? NSLocalizedString("all_levels_completed", tableName: "Quiz", comment: "")
                    : nextDifficultyText
                )
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                difficultyDot(.easy)
                difficultyDot(.medium)
                difficultyDot(.hard)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func difficultyDot(_ d: QuizDifficulty) -> some View {
        let st = dotState(d)
        let c: Color = {
            switch d {
            case .easy: return .green
            case .medium: return .blue
            case .hard: return .purple
            }
        }()

        Circle()
            .fill(st == .completed ? c : Color.clear)
            .overlay(
                Circle()
                    .stroke(
                        st == .locked ? Color.gray.opacity(0.5) : c.opacity(0.9),
                        lineWidth: 1.5
                    )
            )
            .frame(width: 9, height: 9)
            .opacity(st == .locked ? 0.6 : 1.0)
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

extension QuizIdentifier {
    var tintColor: Color {
        switch self {
        case .serve: return .blue
        case .tactics: return .orange
        case .forehand: return .green
        case .backhand: return .purple
        case .volley: return .teal
        case .legwork: return .mint
        }
    }
    
    var thumbnailImageName: String {
            switch self {
            case .serve: return "serve"
            case .tactics: return "tactics"
            case .forehand: return "forehand"
            case .backhand: return "backhand"
            case .volley: return "volley"
            case .legwork: return "legworks"
            }
        }
}

extension QuizIdentifier {

    var titleKey: String {
        switch self {
        case .serve: return "topic_serve"
        case .tactics: return "topic_tactics"
        case .forehand: return "topic_forehand"
        case .backhand: return "topic_backhand"
        case .volley: return "topic_volley"
        case .legwork: return "topic_legwork"
        }
    }

    var localizedTitle: String {
        NSLocalizedString(self.titleKey, tableName: "Quiz", comment: "")
    }
}


struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.26, dampingFraction: 0.85), value: configuration.isPressed)
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
