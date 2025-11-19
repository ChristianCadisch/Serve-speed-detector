//
//  TheoryView.swift
//  Clay Tennis
//
//  Created by Christian on 19.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct TheoryView: View {

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
    }

    private let items: [Item] = [
        Item(title: "Leg Work", icon: "figure.walk"),
        Item(title: "Forehand", icon: "tennis.racket"),
        Item(title: "Backhand", icon: "tennis.racket"),
        Item(title: "Serve", icon: "bolt.circle"),
        Item(title: "Volley", icon: "hand.raised"),
        Item(title: "Tactics", icon: "lightbulb")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                
                // MARK: - Tactics Quiz Card
                NavigationLink {
                    QuizView(vm: QuizViewModel(questions: tacticsQuestions))
                } label: {
                    ZStack {
                        LinearGradient(
                            colors: [Color.white, Color(.systemGray6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .cornerRadius(28)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        VStack(spacing: 14) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .frame(width: 120, height: 120)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                            Text("Tactics Quiz")
                                .font(.title3.bold())

                            Text("Test your understanding of the core tactical principles.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 28)

                            Text("Start Tactics Quiz")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.top, 4)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 28)
                    }
                    .frame(height: 360)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)
                }

                
                // MARK: - Lessons
                
                ForEach(items) { item in
                    NavigationLink(
                        destination: destinationView(for: item.title)
                    ) {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.system(size: 26))
                                .foregroundColor(.accentColor)
                                .frame(width: 40, height: 40)

                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 16)
        }
        //.navigationTitle("Technique Coach")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "Tactics":
            TechniqueStoryView(stories: tacticsStories)
        default:
            TheoryPageView(title: title)
        }
    }

}


struct TheoryPageView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text("Content coming soon…")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.top, 40)

            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}



#Preview {
    TheoryView()
}

