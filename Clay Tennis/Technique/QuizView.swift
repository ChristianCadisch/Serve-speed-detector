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
            QuizResultView(score: vm.score, total: vm.questions.count)
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
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quiz Complete")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("\(score)/\(total) correct")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        Color.primary.ignoresSafeArea()
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
