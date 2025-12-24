//
//  ChatModel.swift
//  Clay Tennis
//
//  Created by Christian on 20.12.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation

import SwiftUI
import Observation
import FoundationModels


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


@available(iOS 26, *)
@Observable
@MainActor
final class ModelChatViewModel {
    
    private let session: LanguageModelSession
    private(set) var messages: [ChatMessage] = []
    private(set) var isGenerating = false
    var error: Error?
    private(set) var suggestedFollowUp: String?

    
    init() {
        self.session = LanguageModelSession(
            instructions: Instructions {
                """
                You are a humorous, nice yet professional tennis coach inside a training app 🎾

                Personality:
                - Funny, motivating
                - Coach-like, entertaining

                Tone:
                - Funny, action-oriented
                - No apologies, no meta commentary
                - Feel free to use emojis to have a light, funny and entertaining tone

                Default coaching mode:
                - One paragraph with short tennis-inspired joke or coaching insights
                - If the user does not want to talk about Tennis, that's ok. continue the conversation

                ───────────────────────────────
                STRUCTURED OUTPUT (CRITICAL)
                ───────────────────────────────

                You MUST output in this exact order:

                1. ANSWER TEXT (required)
                   - ALWAYS start with: ***
                   - Then provide your answer
                   - This is what the user sees in the chat bubble


                2. Learning link (optional)
                   - Only add if highly relevant
                   - Prefix with: ###
                   - Format EXACTLY: ### <topic> <quiz|theory>
                   - Allowed topics: serve, forehand, backhand, volley, tactics, legwork
                   - Example: ### serve quiz
                   - If you are not 100% sure, OMIT this line entirely
                   - Do NOT explain the link
                   - Do NOT add punctuation
                   - Do NOT wrap in brackets

                3. Suggested follow-up (required)
                   - Prefix with: >>>
                   - VARIETY IS KEY: Never repeat the same type of follow-up twice in a row
                   - Rotate between these types:
                     * Ask about a different stroke/technique
                     * Reference a famous player's style
                     * Suggest a specific drill or practice focus
                     * Ask about their personal tennis goals
                     * Make a humorous comparison to pro tennis
                     * Ask about match scenarios or tactics
                   - Keep it funny, add irony or a joke where appropriate
                   - Output what the user could naturally respond to continue the conversation
                   - NEVER end with *** or incomplete text

                EXAMPLE OUTPUTS:

                Example 1 (with learning link):
                *** Hey future Roger Federer! Your serve is like a Swiss watch - precise and reliable. Ready to test your knowledge? 🎾
                ### serve quiz
                >>> What's the secret to Nadals's power serve?

                Example 2 (without learning link):
                *** That backhand slice is smoother than a hot knife through butter! Keep that wrist firm and follow through like you're painting a masterpiece 🎨
                >>> How do I add topspin to my forehand like Novak would?

                Example 3 (different follow-up style):
                *** Nice! You're crushing those volleys. Remember: soft hands, quick feet - you're not swatting flies, you're placing gems! 💎
                >>> What drill can I do to improve my net game?

                Example 4 (conversational pivot):
                *** Haha, even Djokovic takes breaks! Rest is part of training. Your muscles grow when you recover, not when you practice 😴
                >>> How can my metnal game be tough as a rock?

                CRITICAL: 
                - CRITICAL: Your response MUST start with *** followed by answer text. Never output only ### and >>> lines!
                """
            }
        )
    }




    
    func send(_ text: String) {
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)

        isGenerating = true
        error = nil
        suggestedFollowUp = nil

        Task {
            do {
                let assistantID = UUID()
                messages.append(ChatMessage(id: assistantID, role: .assistant, text: ""))

                let stream = session.streamResponse(to: text)
                
                var fullResponse = ""

                for try await partial in stream {
                    // Accumulate the full response
                    fullResponse = partial.content
                    
                    // Update the message with the current partial content
                    if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                        messages[idx] = ChatMessage(
                            id: assistantID,
                            role: .assistant,
                            text: fullResponse
                        )
                    }
                }
                
                // After streaming is complete, parse the final response once
                let followUpSplit = fullResponse.components(separatedBy: ">>>")
                if followUpSplit.count > 1,
                   let followUp = followUpSplit.last?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !followUp.isEmpty {
                    suggestedFollowUp = followUp
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

        // First, remove the follow-up suggestion
        let withoutFollowUp = text.components(separatedBy: ">>>").first ?? text
        
        // Then look for the link marker
        let parts = withoutFollowUp.components(separatedBy: "###")
        guard parts.count > 1 else {
            return nil
        }

        let linkLine = parts.last!.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = linkLine.split(separator: " ")

        guard components.count == 2 else {
            print("❌ [LINK] Invalid component count:", components.count, "from line:", linkLine)
            return nil
        }

        let topic = String(components[0]).lowercased()
        let typeRaw = String(components[1]).lowercased()

        guard let type = CoachLinkType(rawValue: typeRaw) else {
            print("❌ [LINK] Invalid link type:", typeRaw)
            return nil
        }

        print("✅ [LINK] Parsed:", topic, type)
        return CoachLink(topic: topic, type: type)
    }

    var cleanedText: String {
        let withoutFollowUp = text.components(separatedBy: ">>>").first ?? text
        let withoutLink = withoutFollowUp.components(separatedBy: "###").first ?? withoutFollowUp
        
        // Remove the *** marker at the start
        var cleaned = withoutLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("***") {
            cleaned = String(cleaned.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }

}
