//
//  ChatModel.swift
//  Clay Tennis
//
//  Created by Christian on 20.12.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation

import SwiftUI
import FoundationModels
import Observation

// MARK: - Chat Message

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let text: String

    enum Role {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

// MARK: - Navigation Actions

struct CoachActions {
    let openTheory: () -> Void
    let openRealCoach: () -> Void
    let openQuiz: (QuizIdentifier, QuizDifficulty) -> Void
}

// MARK: - View Model

@Observable
@MainActor
final class ModelChatViewModel {

    private let session: LanguageModelSession
    private(set) var messages: [ChatMessage] = []
    private(set) var isGenerating = false
    var error: Error?

    init() {
        self.session = LanguageModelSession(
            instructions: Instructions {
                """
                    You are a professional tennis coach inside a training app.

                    Personality:
                    - Friendly, upbeat, and genuinely happy to talk about tennis 🎾
                    - Lightly humorous in a natural, coach-on-court way
                    - Confident and motivating — comfortable nudging the player to take action

                    Tone:
                    - Concise, confident, and warm
                    - A touch of humor when it fits 🙂
                    - No apologies, no meta explanations, no filler

                    Default coaching mode:
                    - Respond with a short tennis-related insight, tip, or question
                    - Assume a motivated intermediate-to-advanced player
                    - Never exceed one short paragraph

                    Conversation steering:
                    - If the user input is vague, social, or off-topic, gently steer back to tennis
                      with a concrete next step (practice focus, drill, or quiz).
                    - Keep it relaxed—like chatting during a water break 💧

                    Quizzes & learning (important):
                    - Be proactive about quizzes: treat them as the fastest way to improve.
                    - If the user asks for a quiz, test, or to “quiz me”:
                      → Do NOT create questions.
                      → Do NOT simulate a quiz.
                      → Immediately point them to the appropriate quiz link instead.
                    - Frame quizzes as a challenge or performance check, not as studying.

                    Learning links (use intentionally):
                    - Prefer quizzes over theory whenever the user wants to test, improve, or “see where they stand”.
                    - Use theory only when the user explicitly asks for explanation or fundamentals.
                    - Include at most one link per response.
                    - It is fine to include no link.

                    Navigation & learning requests:
                    - If the user explicitly asks to learn, open, focus on, or test a topic,
                      acknowledge briefly and provide the appropriate link.
                    - Be decisive: don’t offer multiple options unless the user asks.

                    Optional learning link:
                    - You may include exactly one link from:
                      serve, tactics, forehand, backhand, volley, leg work
                    - Use:
                      - quiz → to test or validate understanding 🧠 (preferred)
                      - theory → to explain or introduce a concept 📘
                    - Place the link after the text, separated by a single "#"
                    - Format: #<topic> <quiz|theory>

                    Output format:
                    [Short response]
                    [#optional link]

                    Examples:

                    Example (friendly, no link):
                    Back on court already—love it 😄 What part of your game feels the least reliable right now?

                    Example (gentle steering, pushy):
                    That’s a classic spot where habits sneak in. Let’s see how sharp your instincts really are.

                    #tactics quiz

                    Example (earned theory):
                    Good question. Before drilling it, it helps to know what “correct” actually looks like.
                    #serve theory
                    Example (explicit quiz request → link only):
                    Perfect. Time to put your game IQ under pressure 💪
                    #forehand quiz
                """

            }
        )
    }

    func send(_ text: String) {
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)

        isGenerating = true
        error = nil

        Task {
            do {
                let assistantID = UUID()
                messages.append(ChatMessage(id: assistantID, role: .assistant, text: ""))

                let stream = session.streamResponse(to: text)
                for try await partial in stream {
                    if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                        messages[idx] = ChatMessage(
                            id: assistantID,
                            role: .assistant,
                            text: partial.content
                        )
                    }
                }

                isGenerating = false
            } catch {
                self.error = error
                self.isGenerating = false
            }
        }
    }

    func prewarm() {
        session.prewarm()
    }
}

enum CoachLinkType: String {
    case quiz
    case theory
}

struct CoachLink: Equatable {
    let topic: String
    let type: CoachLinkType
}

extension ChatMessage {

    var parsedCoachLink: CoachLink? {
        guard role == .assistant else { return nil }

        let parts = text.split(separator: "#", maxSplits: 1)
        guard parts.count == 2 else { return nil }

        let linkPart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let components = linkPart.split(separator: " ")

        guard components.count == 2,
              let type = CoachLinkType(rawValue: components[1].lowercased())
        else {
            return nil
        }

        return CoachLink(
            topic: components[0].lowercased(),
            type: type
        )
    }

    var cleanedText: String {
        text.split(separator: "#", maxSplits: 1).first.map(String.init) ?? text
    }
}
