//
//  Settings.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 12.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var showOnboarding = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top App Card
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color.white, Color(.systemGray6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                    VStack(spacing: 12) {
                        Image("onboarding") // your asset name
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(16)
                            .shadow(radius: 4)

                        Text("Welcome to Clay")
                            .font(.title3.bold())

                        Text("Analyze and improve your serve with AI-powered feedback.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)

                        Button(action: { showOnboarding = true }) {
                            Text("View Full Onboarding")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 32)
                }
                .frame(height: 280)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, -12) // soft overlap with form

                // Form content (visually consistent, full bottom area)
                VStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Support")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Group {
                            Button("Troubleshooting") { }
                            Divider()
                            Button("Give Feedback") { }
                            Divider()
                            Button("Share App") { }
                        }
                        .tint(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clay v1.0").font(.subheadline)
                            Text("Built to help you analyze and improve your tennis serve.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40) // ✅ ensures visible bottom space
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                .onChange(of: hasSeenOnboarding) { newValue in
                    if newValue { showOnboarding = false }
                }
        }
    }
}

#Preview {
    SettingsView(hasSeenOnboarding: .constant(true))
}
