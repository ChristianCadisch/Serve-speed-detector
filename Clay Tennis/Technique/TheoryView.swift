//
//  TheoryView.swift
//  Clay Tennis
//
//  Created by Christian on 19.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

extension View {
    func mirroredHorizontally(_ shouldMirror: Bool) -> some View {
        self.scaleEffect(x: shouldMirror ? -1 : 1, y: 1, anchor: .center)
    }
}

enum QuizIdentifier: Int, CaseIterable {
    case tactics
    case serve
    case forehand
    case backhand
    case volley
    case legwork

    var title: String {
        switch self {
        case .tactics: return "Tactics"
        case .serve: return "Serve"
        case .forehand: return "Forehand"
        case .backhand: return "Backhand"
        case .volley: return "Volley"
        case .legwork: return "Leg Work"
        }
    }
}

enum LessonState {
    case locked
    case unlocked
    case completed
}

extension QuizIdentifier {

    static var progression: [QuizIdentifier] {
        [.serve, .tactics, .forehand, .backhand, .volley, .legwork]
    }

    func state(highScores: [Int]) -> LessonState {

        let index = Self.progression.firstIndex(of: self) ?? 0

        // First lesson is always available
        if index == 0 {
            let score = highScores[self.progressionIndex]
            let total = totalQuestionsStatic(for: self)
            return score >= total ? .completed : .unlocked
        }

        let previous = Self.progression[index - 1]
        let previousScore = highScores[previous.progressionIndex]
        let previousTotal = totalQuestionsStatic(for: previous)

        // If previous lesson not completed, lock this one
        if previousScore < previousTotal {
            return .locked
        }

        let myScore = highScores[self.progressionIndex]
        let myTotal = totalQuestionsStatic(for: self)

        return myScore >= myTotal ? .completed : .unlocked
    }
    
    private func totalQuestionsStatic(for quiz: QuizIdentifier) -> Int {
        switch quiz {
        case .serve: return serveQuestions.count
        case .tactics: return tacticsQuestions.count
        case .forehand: return forehandQuestions.count
        case .backhand: return backhandQuestions.count
        case .volley: return volleyQuestions.count
        case .legwork: return legworkQuestions.count
        }
    }


}

extension QuizIdentifier {
    var progressionIndex: Int {
        QuizIdentifier.progression.firstIndex(of: self)!
    }
}




struct TheoryView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showQuiz = false
    @State private var highScores: [Int] = Array(repeating: 0, count: QuizIdentifier.allCases.count)
    private var featuredQuiz: QuizIdentifier {
        for quiz in QuizIdentifier.progression {
            let index = quiz.progressionIndex
            let total = totalQuestions(for: quiz)

            if highScores[index] < total {
                return quiz
            }
        }
        return QuizIdentifier.progression.last!
    }



    
    private func quizKey(for quiz: QuizIdentifier) -> String {
        "QuizHighScore_\(quiz.progressionIndex)"
    }
    private func loadHighScores() {
        var loaded = Array(repeating: 0, count: QuizIdentifier.allCases.count)

        for quiz in QuizIdentifier.allCases {
            let saved = UserDefaults.standard.integer(forKey: quizKey(for: quiz))
            loaded[quiz.progressionIndex] = saved
        }

        highScores = loaded
        
        print("📥 Loaded high scores:")
        for quiz in QuizIdentifier.progression {
            let score = highScores[quiz.progressionIndex]
            let total = totalQuestions(for: quiz)
            let progress = total == 0 ? 0 : Double(score) / Double(total)

            print("•", quiz.title, "- Score:", score, "/", total, "→ progress:", progress)
        }

        
    }

    
    private func quizProgress(for quiz: QuizIdentifier, totalQuestions: Int) -> Double {
        let highScore = highScores[quiz.progressionIndex]
        return totalQuestions == 0 ? 0 : Double(highScore) / Double(totalQuestions)
    }
    
    private func totalQuestions(for quiz: QuizIdentifier) -> Int {
        switch quiz {
        case .serve: return serveQuestions.count
        case .tactics: return tacticsQuestions.count
        case .forehand: return forehandQuestions.count
        case .backhand: return backhandQuestions.count
        case .volley: return volleyQuestions.count
        case .legwork: return legworkQuestions.count
        }
    }

    
    private func quizForItem(_ item: Item) -> QuizIdentifier {
        switch item.title {
        case "Serve": return .serve
        case "Tactics": return .tactics
        case "Forehand": return .forehand
        case "Backhand": return .backhand
        case "Volley": return .volley
        case "Leg Work": return .legwork
        default: return .serve
        }
    }





    struct Item: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let isMirrored: Bool

        init(title: String, icon: String, isMirrored: Bool = false) {
            self.title = title
            self.icon = icon
            self.isMirrored = isMirrored
        }
    }


    private let items: [Item] = [
        Item(title: "Serve", icon: "figure.tennis"),
        Item(title: "Tactics", icon: "lightbulb"),
        Item(title: "Forehand", icon: "tennis.racket"),
        Item(title: "Backhand", icon: "tennis.racket", isMirrored: true),
        Item(title: "Volley", icon: "arrow.forward.circle"),
        Item(title: "Leg Work", icon: "figure.run")

    ]

    
    private func updateHighScore(for quiz: QuizIdentifier, newScore: Int) {
        let index = quiz.progressionIndex
        let current = highScores[index]

        if newScore > current {
            highScores[index] = newScore
            
            let key = quizKey(for: quiz)
            UserDefaults.standard.set(newScore, forKey: key)

            print("✅ New high score for \(quiz): \(newScore)")
        } else {
            print("ℹ️ Score \(newScore) did not beat high score \(current) for \(quiz)")
        }
    }



    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                
                // MARK: - Tactics Quiz Card
                Button {
                    showQuiz = true
                } label: {
                    ZStack {
                        LinearGradient(
                            colors: [Color.white, Color(.systemGray6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .cornerRadius(28)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        VStack(spacing: 14) {
                            
                            QuizProgressCardBar(
                                quiz: featuredQuiz,
                                highScore: highScores[featuredQuiz.progressionIndex],
                                total: totalQuestions(for: featuredQuiz)
                            )


                            .padding(.horizontal, 28)
                            .padding(.top, 4)
                            
                            Image(systemName: iconForQuiz(featuredQuiz))
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .frame(width: 120, height: 120)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            Text("\(featuredQuiz.title) Quiz")
                                .font(.title3.bold())

                            Text("Test your understanding of \(featuredQuiz.title.lowercased()) technique.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 28)
                            
                            


                            Text("Start \(featuredQuiz.title) Quiz")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.top, 4)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 28)
                    }
                    .frame(height: 360)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)
                }
                .sheet(isPresented: $showQuiz) {
                    QuizView(
                        vm: QuizViewModel(questions: questionsForQuiz(featuredQuiz)),
                        quizID: featuredQuiz,
                        onQuizFinished: { quiz, score in
                            updateHighScore(for: quiz, newScore: score)
                        },
                        onFinish: {
                            showQuiz = false
                        }
                    )
                }

                .onAppear {
                    loadHighScores()
                }


                
                // MARK: - Lessons
                
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let quiz = quizForItem(item)
                    let state = quiz.state(highScores: highScores)

                    LockableLessonRow(
                        item: item,
                        quiz: quiz,
                        state: state
                    ) {
                        dismiss()
                    }
                }
            }
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    private func questionsForQuiz(_ quiz: QuizIdentifier) -> [QuizQuestion] {
        switch quiz {
        case .serve: return serveQuestions
        case .tactics: return tacticsQuestions
        case .forehand: return forehandQuestions
        case .backhand: return backhandQuestions
        case .volley: return volleyQuestions
        case .legwork: return legworkQuestions
        }
    }

    
    private func iconForQuiz(_ quiz: QuizIdentifier) -> String {
        switch quiz {
        case .serve: return "figure.tennis"
        case .tactics: return "lightbulb"
        case .forehand: return "tennis.racket"
        case .backhand: return "tennis.racket"
        case .volley: return "arrow.forward.circle"
        case .legwork: return "figure.run"
        }
    }

    
    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "Tactics":
            TechniqueStoryView(stories: tacticsStories)
        case "Serve":
            TechniqueStoryView(stories: serveStories)
        case "Forehand":
            TechniqueStoryView(stories: forehandStories)
        case "Backhand":
            TechniqueStoryView(stories: backhandStories)
        case "Volley":
            TechniqueStoryView(stories: volleyStories)
        case "Leg Work":
            TechniqueStoryView(stories: legworkStories)
        default:
            TheoryPageView(title: title)
        }
    }
}


struct LockableLessonRow: View {

    let item: TheoryView.Item
    let quiz: QuizIdentifier
    let state: LessonState
    let action: () -> Void
    
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
                        destinationView
                    } label: {
                        rowContent
                    }
                }
            }
            .alert("Locked Training", isPresented: $showLockedAlert) {
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
            return "Complete the required quiz to unlock this lesson."
        }
    }


    private var destinationView: some View {
        switch quiz {
        case .serve: TechniqueStoryView(stories: serveStories)
        case .tactics: TechniqueStoryView(stories: tacticsStories)
        case .forehand: TechniqueStoryView(stories: forehandStories)
        case .backhand: TechniqueStoryView(stories: backhandStories)
        case .volley: TechniqueStoryView(stories: volleyStories)
        case .legwork: TechniqueStoryView(stories: legworkStories)
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {

            ZStack {
                Circle()
                    .fill(state == .locked ? Color.gray.opacity(0.15) : Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .foregroundColor(state == .locked ? .gray : .blue)
                    .mirroredHorizontally(item.isMirrored)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
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
        case .locked: return "Locked — complete previous quiz"
        case .unlocked: return "Unlocked"
        case .completed: return "Mastered"
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .locked:
            Image(systemName: "lock.fill").foregroundColor(.gray)
        case .unlocked:
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        case .completed:
            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
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
        .onAppear {
            print("📊 [ProgressBar]")
            print("Quiz:", quiz.title)
            print("High score:", highScore)
            print("Total questions:", total)
            print("Expected progress:", progress)
        }
        .onChange(of: highScore) { newValue in
            print("🔄 High score changed for \(quiz.title)")
            print("New high score:", newValue)
            print("Total questions:", total)
            print("Expected progress:", Double(newValue) / Double(total))
        }

    }
}


struct TheoryPageView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text("Content coming soon…")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.top, 40)

            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}



#Preview {
    TheoryView()
}

