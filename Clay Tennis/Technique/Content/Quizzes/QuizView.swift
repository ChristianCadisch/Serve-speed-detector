//
//  QuizView.swift
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
    @State private var animateIn = false
    @State private var buttonPressed = false

    let quizID: QuizIdentifier
    let onQuizFinished: (QuizIdentifier, Int) -> Void
    let onFinish: () -> Void
    let navigationDelegate: HomeNavigationDelegate?

    private var topicAccent: Color {
        quizID.tintColor
    }

    var body: some View {
        ZStack(alignment: .top) {

            LinearGradient(
                colors: [
                    topicAccent.opacity(0.15),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if vm.finished {
                QuizResultView(
                    score: vm.score,
                    total: vm.questions.count,
                    quizID: quizID,
                    onNextQuiz: { id in
                        onQuizFinished(quizID, vm.score)
                        navigationDelegate?.showQuiz(
                            topic: id.topic,
                            difficulty: id.difficulty
                        )
                    }
                )
            } else {
                quizContent
            }
        }
    }

    private var quizContent: some View {
        VStack(spacing: 28) {

            VStack(spacing: 8) {
                quizProgressBars(
                    count: vm.questions.count,
                    index: vm.currentIndex,
                    progress: progress
                )
                .padding(.horizontal, 18)

                Text(
                    String(
                        format: NSLocalizedString("question_counter_format", tableName: "Quiz", comment: ""),
                        vm.currentIndex + 1,
                        vm.questions.count
                    )
                )
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            let question = vm.questions[vm.currentIndex]

            Text(LocalizedStringKey(question.textKey), tableName: "Quiz")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                ForEach(question.answers) { answer in
                    QuizOptionView(
                        answer: answer,   // pass keys directly
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

            Spacer()

            if !hasEntered {
                actionButton(titleKey: "enter_button") {
                    vm.evaluateCurrentQuestion()
                    hasEntered = true
                    showContinue = true
                    onQuizFinished(quizID, vm.score)
                }
            } else if showContinue {
                actionButton(titleKey: "continue_button") {
                    vm.submit()
                    onQuizFinished(quizID, vm.score)
                }
            }


        }
        .padding(.bottom, 22)
        .onAppear { resetState() }
        .onChange(of: vm.currentIndex) { _ in resetState() }
    }

    private func actionButton(titleKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(titleKey), tableName: "Quiz")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(18)
        }
        .padding(.horizontal, 20)
    }


    private func quizProgressBars(count: Int, index: Int, progress: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule()
                            .fill(topicAccent)
                            .frame(
                                width: geo.size.width *
                                (i < index ? 1 : i == index ? progress : 0)
                            )
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private func resetState() {
        progress = 0
        hasEntered = false
        showContinue = false
        animateIn = false
    }
}


#Preview {
    QuizView(
        vm: QuizViewModel(
            questions: QuizIdentifier.serve.questions(for: .easy)
        ),
        quizID: .serve,
        onQuizFinished: { _, _ in },
        onFinish: { },
        navigationDelegate: nil
    )
}
