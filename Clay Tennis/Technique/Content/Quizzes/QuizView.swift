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

    private let barStepDuration: TimeInterval = 0.02
    private let barFullDuration: TimeInterval = 4.0

    private var topicAccent: Color {
        quizID.tintColor
    }

    var body: some View {
        ZStack(alignment: .top) {

            // Background
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
                    quizID: quizID
                ) {
                    onQuizFinished(quizID, vm.score)
                    onFinish()   // ← this should navigate back to the lesson view
                }

            }
 else {

                    quizContent

                }
        }
        
    }
    
    private var quizContent: some View {
        VStack(spacing: 28) {

            // Progress + counter
            VStack(spacing: 8) {
                quizProgressBars(
                    count: vm.questions.count,
                    index: vm.currentIndex,
                    progress: progress
                )
                .padding(.horizontal, 18)

                Text("Question \(vm.currentIndex + 1) of \(vm.questions.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            let question = vm.questions[vm.currentIndex]

            // Question card
            Text(question.text)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(topicAccent.opacity(0.08), lineWidth: 1)
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 6,
                    x: 0,
                    y: 2
                )
                .padding(.horizontal, 20)

            // Answers
            VStack(spacing: 14) {
                ForEach(question.answers) { answer in
                    QuizOptionView(
                        answer: answer,
                        isSelected: vm.selectedAnswers.contains(answer.id),
                        revealed: hasEntered
                    )
                    .onTapGesture {
                        if !hasEntered {
                            withAnimation(.easeOut(duration: 0.15)) {
                                vm.toggleAnswer(answer.id, type: question.type)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // Action button
            if !hasEntered {
                actionButton(title: "Enter") {
                    vm.evaluateCurrentQuestion()

                    withAnimation(.easeOut(duration: 0.15)) {
                        hasEntered = true
                        showContinue = true
                    }

                    onQuizFinished(quizID, vm.score)
                }
            }
            else if showContinue {
                actionButton(title: "Continue") {
                    vm.submit()
                    
                    onQuizFinished(quizID, vm.score)
                }
            }
        }
        .padding(.bottom, 22)
        .onAppear { resetState() }
        .onChange(of: vm.currentIndex) { _ in resetState() }
    }

    // MARK: - Action Button

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Color.primary
                )
                .cornerRadius(18)
                .scaleEffect(buttonPressed ? 0.97 : 1)
                .shadow(
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .padding(.horizontal, 20)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.05)) {
                        buttonPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        buttonPressed = false
                    }
                }
        )
    }

    // MARK: - Progress Bars

    private func quizProgressBars(count: Int, index: Int, progress: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(Color(.systemGray5))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        topicAccent,
                                        topicAccent.opacity(0.75)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width *
                                (i < index ? 1 :
                                 i == index ? progress : 0)
                            )
                    }
                }
                .frame(height: 6)
            }
        }
    }

    // MARK: - State Reset

    private func resetState() {
        progress = 0
        hasEntered = false
        showContinue = false
        animateIn = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.25)) {
                animateIn = true
            }
        }
    }
}




struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView(
            vm: QuizViewModel(questions: serveQuestions),
            quizID: .backhand,
            onQuizFinished: { _, _ in },
            onFinish: { }
        )
        .previewLayout(.sizeThatFits)
    }
}


