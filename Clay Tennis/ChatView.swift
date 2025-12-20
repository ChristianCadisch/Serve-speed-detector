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

// MARK: - Main View

struct ChatView: View {

    let actions: CoachActions

    @State private var viewModel = ModelChatViewModel()
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    @State private var navigateToFindCoach = false

    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            
                            if viewModel.messages.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    
                                    if isFocused == false {
                                        Text("START TRAINING")
                                            .font(.caption.bold())
                                            .tracking(1.2)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 4)
                                        
                                        CoachEntryCards(
                                            onTalkToClay: {
                                                isFocused = true
                                            },
                                            onTheory: {
                                                actions.openTheory()
                                            },
                                            onRealCoach: {
                                                navigateToFindCoach = true
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
                    .onTapGesture { isFocused = false }
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
        }
        .task { viewModel.prewarm() }
        .navigationDestination(isPresented: $navigateToFindCoach) {
            FindCoach()
        }

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

// MARK: - Entry Cards

private struct CoachEntryCards: View {

    let onTalkToClay: () -> Void
    let onTheory: () -> Void
    let onRealCoach: () -> Void

    var body: some View {
        VStack(spacing: 18) {

            // 1️⃣ Talk to Clay AI — primary, indigo
            NavigationActionCard(
                title: "Talk to Clay AI",
                subtitle: "Your AI Tennis coach",
                icon: "sparkles",
                gradient: [
                    Color(red: 79/255, green: 70/255, blue: 229/255),
                    Color(red: 91/255, green: 33/255, blue: 182/255)
                ],
                isPrimary: true,
                action: onTalkToClay
            )

            // 2️⃣ Theory & Quizzes — secondary, green
            NavigationActionCard(
                title: "Theory & Quizzes",
                subtitle: "Build fundamentals off-court",
                icon: "brain.head.profile",
                gradient: [.green, Color.green.opacity(0.7)],
                isPrimary: false,
                action: onTheory
            )

            // 3️⃣ Work with a Real Coach — escalation, orange
            NavigationActionCard(
                title: "Work with a Real Coach",
                subtitle: "Find a Tennis Coach near you",
                icon: "person.fill.checkmark",
                gradient: [.orange, Color.orange.opacity(0.7)],
                isPrimary: false,
                action: onRealCoach
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Navigation Action Card

private struct NavigationActionCard: View {

    let title: String
    let subtitle: String
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
                    isGenerating ? .secondary : Color.accentColor.opacity(0.9)
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
            openTheory: {},
            openRealCoach: {}
        )
    )
}
