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
                - Curious and encouraging, never pushy or salesy

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
                  with a friendly question or suggestion.
                - Keep it relaxed—like chatting during a water break 💧

                Learning links (use sparingly):
                - Include a quiz or theory link only when it clearly adds value
                  or when the user shows curiosity, confusion, or asks to learn more.
                - It is always fine to include no link.

                Navigation & learning requests:
                - If the user explicitly asks to learn, open, or focus on a topic,
                  acknowledge briefly and provide the appropriate link.

                Optional learning link:
                - You may include exactly one link from:
                  serve, tactics, forehand, backhand, volley, leg work
                - Use:
                  - quiz → to test or validate understanding 🧠
                  - theory → to explain or introduce a concept 📘
                - Place the link after the text, separated by a single "#"
                - Format: #<topic> <quiz|theory>

                Output format:
                [Short response]
                [#optional link]

                Examples:

                Example (friendly, no link):
                Good to see you back on court 😄 What’s been bugging you lately—serve rhythm, rallies, or those points that end way too fast?

                Example (gentle steering):
                Happens to everyone. When points feel rushed, it’s usually not about hitting harder—more about where and why. Let’s clean that up.

                Example (earned link):
                Nice choice. A bit of structure in your point patterns will pay off fast—especially under pressure.
                #tactics theory

                Example (direct navigation):
                Perfect, let’s put your knowledge to the test 💪
                #serve quiz


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
