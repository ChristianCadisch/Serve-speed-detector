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



struct TheoryView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showQuiz = false
    @State private var highScores: [Int] = Array(repeating: 0, count: QuizIdentifier.allCases.count)
    
    
    private func quizKey(for quiz: QuizIdentifier) -> String {
        "QuizHighScore_\(quiz.rawValue)"
    }
    private func loadHighScores() {
        for quiz in QuizIdentifier.allCases {
            let saved = UserDefaults.standard.integer(forKey: quizKey(for: quiz))
            highScores[quiz.rawValue] = saved
        }
    }
    
    private func quizProgress(for quiz: QuizIdentifier, totalQuestions: Int) -> Double {
        let highScore = highScores[quiz.rawValue]
        return totalQuestions == 0 ? 0 : Double(highScore) / Double(totalQuestions)
    }




    private struct Item: Identifiable {
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
        let index = quiz.rawValue
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
                                quiz: .tactics,
                                highScore: highScores[QuizIdentifier.tactics.rawValue],
                                total: tacticsQuestions.count
                            )
                            .padding(.horizontal, 28)
                            .padding(.top, 4)
                            
                            Image(systemName: "lightbulb")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .frame(width: 120, height: 120)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            Text("Serve Quiz")
                                .font(.title3.bold())

                            Text("Test your understanding of the serve technique.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 28)
                            
                            


                            Text("Start Serve Quiz")
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
                        vm: QuizViewModel(questions: tacticsQuestions),
                        quizID: .serve,
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
                
                ForEach(items) { item in
                    NavigationLink(
                        destination: destinationView(for: item.title)
                    ) {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.system(size: 26))
                                .foregroundColor(.accentColor)
                                .frame(width: 40, height: 40)
                                .mirroredHorizontally(item.isMirrored)

                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
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

