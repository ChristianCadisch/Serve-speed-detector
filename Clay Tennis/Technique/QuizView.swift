//
//  File.swift
//  Clay Tennis
//
//  Created by Christian on 19.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct QuizView: View {
    @StateObject var vm: QuizViewModel
    @State private var progress: CGFloat = 0
    @State private var hasEntered = false
    @State private var showContinue = false
    @State private var showResults = false
    let onFinish: () -> Void


    private let barStepDuration: TimeInterval = 0.02
    private let barFullDuration: TimeInterval = 4.0

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                quizProgressBars(count: vm.questions.count,
                                 index: vm.currentIndex,
                                 progress: progress)
                    .padding(.top, 6)
                    .padding(.horizontal, 12)
                
                let question = vm.questions[vm.currentIndex]
                
                Text(question.text)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(question.answers) { answer in
                        QuizOptionView(
                            answer: answer,
                            isSelected: vm.selectedAnswers.contains(answer.id),
                            revealed: hasEntered
                        )
                        .onTapGesture {
                            if !hasEntered {
                                vm.toggleAnswer(answer.id, type: question.type)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                if !hasEntered {
                    Button {
                        hasEntered = true
                        showContinue = true
                    } label: {
                        Text("Enter")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                } else if showContinue {
                    Button {
                        vm.submit()
                        progress = 0
                        hasEntered = false
                        showContinue = false
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                
                Spacer()
            }
        }
        .onAppear {
            progress = 0
        }
        .onChange(of: vm.currentIndex) { _ in
            progress = 0
        }
        .onChange(of: vm.finished) { finished in
            if finished {
                showResults = true
            }
        }
        .sheet(isPresented: $showResults) {
            QuizResultView(
                score: vm.score,
                total: vm.questions.count,
                onDone: {
                    onFinish()
                    vm.finished = false      // reset state
                    showResults = false      // dismiss sheet
                    vm.currentIndex = 0      // optional: restart quiz
                    vm.score = 0             // optional
                }
            )
        }
    }
    
    private func quizProgressBars(count: Int, index: Int, progress: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * (i < index ? 1 : (i == index ? progress : 0)))
                    }
                }
                .frame(height: 4)
            }
        }
    }
}


struct QuizResultView: View {
    let score: Int
    let total: Int
    let onDone: () -> Void

    
    @State private var appear = false

    
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
            LinearGradient(
                colors: [.black, .gray.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                
                VStack(spacing: 12) {
                    Text("Quiz Complete")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 10)
                    
                    Text(performanceText)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 10)
                }
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("out of \(total)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .scaleEffect(appear ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appear)
                
                Spacer()
                
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        onDone()
                    }

            }
            .padding(.top, 80)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appear = true
            }
        }
    }
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
    
    func submit() {
        let current = questions[currentIndex]
        let correctSet = Set(current.answers.filter { $0.isCorrect }.map { $0.id })

        if correctSet == selectedAnswers {
            score += 1
        }

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

    var body: some View {
        HStack {
            Text(answer.text)
                .foregroundColor(.white)
                .font(.body)
            Spacer()
            if revealed {
                if answer.isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            } else if isSelected {
                Image(systemName: "circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            revealed ?
            (answer.isCorrect ? Color.green.opacity(0.25) :
             isSelected ? Color.red.opacity(0.25) :
             Color.white.opacity(0.12))
            :
            Color.white.opacity(isSelected ? 0.25 : 0.12)
        )
        .cornerRadius(12)
    }
}

struct QuizResultView_Previews: PreviewProvider {
    static var previews: some View {
        QuizResultView(
            score: 7,
            total: 10,
            onDone: {}
        )
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
