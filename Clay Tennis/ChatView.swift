//
//  ModelChatView.swift
//  Clay Tennis
//
//  Premium Coach Control Center
//

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

// MARK: - Navigation Actions (Injected from HomeViewController)

struct CoachActions {
    let openCoachHub: () -> Void
    let openTheory: () -> Void
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
                You are a professional tennis coach.
                Be concise, confident, and directive.
                Always guide the user toward a concrete training action.
                Never exceed three short paragraphs.
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

                var accumulated = ""
                let stream = session.streamResponse(to: text)

                for try await partial in stream {
                    accumulated = partial.content
                    if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                        messages[idx] = ChatMessage(
                            id: assistantID,
                            role: .assistant,
                            text: accumulated
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

// MARK: - Main View

struct ChatView: View {

    let actions: CoachActions

    @State private var viewModel = ModelChatViewModel()
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    @State private var showTrainingPrescription = false


    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {

                        if viewModel.messages.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {


                                if showTrainingPrescription {
                                    
                                    Text("YOUR TRAINING PLAN")
                                        .font(.caption.bold())
                                        .tracking(1.2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    TrainingPrescriptionActions(
                                        onTechnique: {
                                            actions.openCoachHub()
                                        },
                                        onTheory: {
                                            actions.openTheory()
                                        },
                                        onRealCoach: {
                                            // placeholder for future integration
                                        }
                                    )
                                    
                                } else {
                                    
                                    Text("START TRAINING")
                                        .font(.caption.bold())
                                        .tracking(1.2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    CoachEntryCards(
                                        onCoachHub: {
                                            actions.openCoachHub()
                                        },
                                        onTheory: {
                                            actions.openTheory()
                                        },
                                        onPlan: {
                                            showTrainingPrescription = true
                                        }
                                    )
                                }

                                
                            }
                            .padding(.top, 20)
                        }
                        
                        


                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    isFocused = false
                }


            }

            InputBar(
                text: $inputText,
                isGenerating: viewModel.isGenerating,
                onSend: {
                    let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    inputText = ""
                    viewModel.send(trimmed)
                }
            )
            .focused($isFocused)

        }
        .overlay(alignment: .topLeading) {
            if showTrainingPrescription {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showTrainingPrescription = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            Color.white.opacity(0.15),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                }
                .padding(.leading, 14)
                .padding(.top, 10)
                .transition(
                    .move(edge: .leading)
                    .combined(with: .opacity)
                )
            }
        }

        .task { viewModel.prewarm() }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                Text(message.text)
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(message.text)
                    .padding(14)
                    .background(Color.accentColor.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message.text)
    }
}

private struct TrainingPrescriptionActions: View {

    let onTechnique: () -> Void
    let onTheory: () -> Void
    let onRealCoach: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {


            PrescriptionButton(
                title: "Test your knowledge",
                subtitle: "Go to the quizzes",
                icon: "brain.head.profile",
                action: onTheory
            )
            
            PrescriptionButton(
                title: "Talk to Clay AI",
                subtitle: "Your AI Tennis coach",
                icon: "sparkles",
                action: onTheory
            )

            PrescriptionButton(
                title: "Work with a Real Coach",
                subtitle: "Find a tennis coach near you",
                icon: "person.crop.circle.badge.plus",
                action: onRealCoach,
                isSecondary: true
            )
        }
        .padding(.horizontal)
    }
}

private struct PrescriptionButton: View {

    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    var isSecondary: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSecondary ? Color.gray : Color.accentColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}




// MARK: - Entry Cards

private struct CoachEntryCards: View {

    let onCoachHub: () -> Void
    let onTheory: () -> Void
    let onPlan: () -> Void

    var body: some View {
        VStack(spacing: 18) {

            NavigationActionCard(
                title: "Coach Hub",
                subtitle: "Measure speed & get AI technique feedback",
                cta: "Go to Coach Hub",
                icon: "figure.tennis",
                gradient: [.purple, .pink],
                isPrimary: true,
                action: onCoachHub
            )

            NavigationActionCard(
                title: "Theory & Quizzes",
                subtitle: "Build fundamentals off-court",
                cta: "Go to Theory",
                icon: "brain.head.profile",
                gradient: [.green, Color.green.opacity(0.7)],
                isPrimary: false,
                action: onTheory
            )

            ConversationalActionCard(
                title: "Plan My Training",
                subtitle: "Let the coach decide your next step",
                icon: "sparkles",
                action: onPlan
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Navigation Action Card

private struct NavigationActionCard: View {

    let title: String
    let subtitle: String
    let cta: String
    let icon: String
    let gradient: [Color]
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {

                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(cta.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(isPrimary ? 22 : 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.thinMaterial)
            )
            .shadow(
                color: .black.opacity(isPrimary ? 0.24 : 0.16),
                radius: isPrimary ? 28 : 18,
                y: isPrimary ? 14 : 9
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Conversational Action Card

private struct ConversationalActionCard: View {

    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {

                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Bar

private struct InputBar: View {
    @Binding var text: String
    let isGenerating: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {

                TextField("Ask your coach anything…", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
                )
                .foregroundStyle(
                    isGenerating
                    ? .secondary
                    : Color.accentColor.opacity(0.9)
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }
}

#Preview {
    ChatView(
        actions: CoachActions(
            openCoachHub: {},
            openTheory: {}
        )
    )
}
