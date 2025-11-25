//
//  QuizHelperViews.swift
//  Clay Tennis
//
//  Created by Christian on 24.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct QuizResultView: View {
    let score: Int
    let total: Int
    let quizID: QuizIdentifier
    let onNextQuiz: (LessonQuizID) -> Void
    
    @State private var nextLesson: LessonQuizID?
    @State private var appear = false
    @State private var showConfetti = false
    
    private var topicAccent: Color {
        quizID.tintColor
    }
    
    private var performanceText: String {
        let ratio = Double(score) / Double(total)
        switch ratio {
        case 0.8...: return "Excellent!"
        case 0.5...: return "Good Job!"
        default: return "Keep Practicing!"
        }
    }
    
    var body: some View {
        ZStack {
            
            // Confetti overlay
            if showConfetti {
                ConfettiView(colors: [
                    topicAccent,
                    topicAccent.opacity(0.7),
                    .white,
                    Color.primary
                ])
                .ignoresSafeArea()
                
            }
            
            // Background gradient
            LinearGradient(
                colors: [
                    topicAccent.opacity(0.10),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            VStack(spacing: 32) {
                
                VStack(spacing: 12) {
                    Text("Quiz Complete")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 10)
                    
                    Text(performanceText)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 10)
                }
                
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(topicAccent.opacity(0.15), lineWidth: 2)
                        )
                    
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("out of \(total)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .scaleEffect(appear ? 1 : 0.86)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appear)
                
                Spacer()
                
                
                
                nextQuizBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
            }
            .padding(.top, 80)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appear = true
            }
            
            showConfetti = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                showConfetti = false
            }
        }
    }
    
    
    
    private var nextLessonID: LessonQuizID {
        let topic = quizID
        let difficulty = QuizDifficulty.easy  // or compute next difficulty here
        
        let idx = topic.progressionIndex + 1
        let nextTopic = QuizIdentifier.progression.indices.contains(idx)
        ? QuizIdentifier.progression[idx]
        : topic
        
        return LessonQuizID(topic: nextTopic, difficulty: difficulty)
    }
    
    private var nextQuizBar: some View {
        let id = nextLessonID
        let topic = id.topic
        let difficulty = id.difficulty
        
        let solved = UserDefaults.standard.integer(forKey: id.userDefaultsKey)
        let total = topic.totalQuestions(for: difficulty)
        let progress = total == 0 ? 0 : Double(solved) / Double(total)
        
        return Button {
            print("➡️ NextQuizBar tapped")
            print("   id.topic:", id.topic.title)
            print("   id.difficulty:", id.difficulty.title)
            onNextQuiz(nextLessonID)
        } label: {
            VStack(spacing: 14) {
                
                HStack(spacing: 14) {
                    
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: topic.iconName)
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .semibold))
                            .mirroredHorizontally(topic.isMirrored)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Quiz")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(topic.title) • \(difficulty.title)")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                HeroProgressBar(
                    progress: progress,
                    label: "\(solved)/\(total) solved"
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.black)
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    
    
    
    // MARK: - Add parameter to QuizResultView
    
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Quiz Complete")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
            
            Text(performanceText)
                .font(.title2.weight(.semibold))
                .foregroundColor(.secondary)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
        }
    }
    
    private var scoreCircle: some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 140, height: 140)
                .overlay(
                    Circle()
                        .stroke(topicAccent.opacity(0.15), lineWidth: 2)
                )
            
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("out of \(total)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .scaleEffect(appear ? 1 : 0.86)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appear)
    }
    
    
}




// MARK: - Confetti System

struct ConfettiView: View {
    let colors: [Color]
    
    @State private var confetti: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(confetti) { particle in
                    Rectangle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 1.6)
                        .position(particle.position)
                        .rotationEffect(particle.rotation)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateConfetti(size: geo.size)
                animateConfetti(height: geo.size.height)
            }
        }
    }
    
    private func generateConfetti(size: CGSize) {
        confetti = (0..<180).map { _ in
            ConfettiParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -CGFloat.random(in: 0...300)
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6...12),
                speed: CGFloat.random(in: 2...6),
                rotation: .degrees(Double.random(in: 0...360)),
                opacity: 1
            )
        }
    }
    
    private func animateConfetti(height: CGFloat) {
        withAnimation(.linear(duration: 4)) {
            for i in confetti.indices {
                confetti[i].position.y = height + 200
                confetti[i].rotation = .degrees(Double.random(in: 720...1440))
                confetti[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let speed: CGFloat
    var rotation: Angle
    var opacity: Double
}



enum QuizQuestionType {
    case single
    case multiple
}

struct QuizAnswer: Identifiable {
    let id = UUID()
    let text: String
    let isCorrect: Bool
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let text: String
    let type: QuizQuestionType
    let answers: [QuizAnswer]
}


class QuizViewModel: ObservableObject {
    @Published var questions: [QuizQuestion]
    @Published var currentIndex: Int = 0
    @Published var selectedAnswers: Set<UUID> = []
    @Published var score: Int = 0
    @Published var finished: Bool = false
    
    init(questions: [QuizQuestion]) {
        self.questions = questions
    }
    
    func toggleAnswer(_ id: UUID, type: QuizQuestionType) {
        switch type {
        case .single:
            selectedAnswers = [id]
        case .multiple:
            if selectedAnswers.contains(id) {
                selectedAnswers.remove(id)
            } else {
                selectedAnswers.insert(id)
            }
        }
    }
    
    
    func evaluateCurrentQuestion() {
        let current = questions[currentIndex]
        let correctSet = Set(current.answers.filter { $0.isCorrect }.map { $0.id })
        
        if correctSet == selectedAnswers {
            score += 1
        }
    }
    
    func submit() {
        selectedAnswers.removeAll()
        
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            finished = true
        }
    }
    
}


struct QuizOptionView: View {
    let answer: QuizAnswer
    let isSelected: Bool
    let revealed: Bool
    
    @State private var hasAnimatedCorrect = false
    @State private var checkScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        HStack {
            Text(answer.text)
                .foregroundColor(.primary)
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
            
            Spacer()
            
            if revealed {
                if answer.isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .scaleEffect(checkScale)
                        .onChange(of: revealed) { _ in
                            tryAnimateCorrect()
                        }
                        .onChange(of: isSelected) { _ in
                            tryAnimateCorrect()
                        }
                } else if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            } else if isSelected {
                Image(systemName: "circle.fill")
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(backgroundStyle)
        .overlay(correctGlow)
        .cornerRadius(12)
        .onAppear {
            resetAnimationStates()
        }
    }
    
    private var backgroundStyle: Color {
        if revealed {
            if answer.isCorrect {
                return Color.green.opacity(0.25)
            } else if isSelected {
                return Color.red.opacity(0.25)
            } else {
                return Color.primary.opacity(0.12)
            }
        } else {
            return Color.primary.opacity(isSelected ? 0.25 : 0.12)
        }
    }
    
    private var correctGlow: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.green.opacity(glowOpacity), lineWidth: 2)
            .blur(radius: 4)
    }
    
    private func tryAnimateCorrect() {
        guard revealed,
              isSelected,
              answer.isCorrect,
              !hasAnimatedCorrect else { return }
        
        hasAnimatedCorrect = true
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            checkScale = 1.2
            glowOpacity = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                checkScale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                glowOpacity = 0
            }
        }
    }
    
    private func resetAnimationStates() {
        hasAnimatedCorrect = false
        checkScale = 1.0
        glowOpacity = 0
    }
}



// UPDATED QuizIdentifier: remove questions/totalQuestions, replace with per-difficulty access
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
    
    var isMirrored: Bool { self == .backhand }
    
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
    
    var progressionIndex: Int {
        Self.progression.firstIndex(of: self) ?? rawValue
    }
    
    // NEW: per-difficulty question sets
    func questions(for difficulty: QuizDifficulty) -> [QuizQuestion] {
        switch (self, difficulty) {
            
            // TODO: swap these to your real arrays, e.g. serveEasyQuestions, serveMediumQuestions, serveHardQuestions
        case (.serve, .easy): return serveQuestions
        case (.serve, .medium): return serveQuestions
        case (.serve, .hard): return serveQuestions
            
        case (.tactics, .easy): return tacticsQuestions
        case (.tactics, .medium): return tacticsQuestions
        case (.tactics, .hard): return tacticsQuestions
            
        case (.forehand, .easy): return forehandQuestions
        case (.forehand, .medium): return forehandQuestions
        case (.forehand, .hard): return forehandQuestions
            
        case (.backhand, .easy): return backhandQuestions
        case (.backhand, .medium): return backhandQuestions
        case (.backhand, .hard): return backhandQuestions
            
        case (.volley, .easy): return volleyQuestions
        case (.volley, .medium): return volleyQuestions
        case (.volley, .hard): return volleyQuestions
            
        case (.legwork, .easy): return legworkQuestions
        case (.legwork, .medium): return legworkQuestions
        case (.legwork, .hard): return legworkQuestions
        }
    }
    
    func totalQuestions(for difficulty: QuizDifficulty) -> Int {
        questions(for: difficulty).count
    }
}



enum LessonState {
    case locked
    case unlocked
    case completed
}

// NEW: difficulty + per-difficulty quiz key
enum QuizDifficulty: Int, CaseIterable, Hashable {
    case easy
    case medium
    case hard
    
    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var orderIndex: Int { rawValue }
}

struct LessonQuizID: Hashable {
    let topic: QuizIdentifier
    let difficulty: QuizDifficulty
    
    var userDefaultsKey: String {
        "QuizHighScore_\(topic.progressionIndex)_\(difficulty.orderIndex)"
    }
}

