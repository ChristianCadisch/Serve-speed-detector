//
//  Settings.swift
//  Settings view, where the user can re-view the onboarding, a detailed camera setup, give feedback and share the app


import SwiftUI

struct SettingsView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var showOnboarding = false
    @State private var showRecordingSetup = false

    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top App Card
                ZStack {
                    LinearGradient(
                        colors: [Color.white, Color(.systemGray6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                    VStack(spacing: 14) {
                        Image("onboarding")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .cornerRadius(16)
                            .shadow(radius: 4)

                        Text("Welcome to Clay")
                            .font(.title3.bold())

                        Text("Analyze your serve with AI")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 28)

                        Button(action: { showOnboarding = true }) {
                            Text("View Onboarding")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top, 40)     
                    .padding(.bottom, 28)
                }
                .frame(height: 360)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 24)

                                VStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Support")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Group {
                            Button("Recording setup guide") {
                                showRecordingSetup = true
                            }
                            Divider()
                            Button("Give Feedback") { if let url = URL(string: "mailto:christian.cadisch@gmail.com") {
                                UIApplication.shared.open(url)
                            }}
                            Divider()
                            Button("Share App") {
                                let url = URL(string: "https://christiancadisch.github.io/tennis.html")!
                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = scene.windows.first?.rootViewController {
                                    rootVC.present(activityVC, animated: true, completion: nil)
                                }}
                        }
                        .tint(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal)
                    
                    
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16) 

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clay v1.0")
                                .font(.subheadline)

                            Text("Built to help you analyze and improve your tennis serve")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)

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
        
        .fullScreenCover(isPresented: $showRecordingSetup) {
            RecordingSetupView(isPresented: $showRecordingSetup)
        }

    }
}

#Preview {
    SettingsView(hasSeenOnboarding: .constant(true))
}
