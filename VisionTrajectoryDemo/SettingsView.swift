//
//  Settings.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 12.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var showOnboarding = false

    var body: some View {
        Form {
            Section {
                Button {
                    showOnboarding = true
                } label: {
                    Text("Display Onboarding")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }

            Section(header: Text("Support")) {
                Button("Troubleshooting") { }
                Button("Give Feedback") { }
                Button("Share App") { }
            }

            Section(header: Text("About")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clay v1.0").font(.subheadline)
                    Text("Built to help you analyze and improve your tennis serve.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
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
