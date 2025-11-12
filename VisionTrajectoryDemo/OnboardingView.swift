//
//  OnboardingView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 12.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import SwiftUI
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    private let totalPages = 5
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        image: "onboarding",
                        title: "Welcome to Clay",
                        description: "Your personal AI serve coach — powered by the newest AI technology"
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        image: "camera.fill",
                        title: "Keep the Camera Steady",
                        description: "For accurate ball tracking, keep the camera completely still — handheld videos don’t work. Just lean your phone against a bottle or bag behind the court"
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        image: "timelapse",
                        title: "Record in Slow Motion",
                        description: "Use slow-motion mode (120 – 240 fps) for the most precise tracking"
                    )
                    .tag(2)
                    
                    OnboardingPage(
                        image: "viewfinder.circle",
                        title: "Capture the Whole Serve",
                        description: "Ensure the entire serve is visible — from your toss and contact point to the ball landing on the other side of the net"
                    )
                    .tag(3)
                    
                    OnboardingPage(
                        image: "chart.bar.fill",
                        title: "Let’s Get Started",
                        description: "Upload or record your first serve"
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let isTap =
                            abs(value.translation.width) < 5 &&
                            abs(value.translation.height) < 5
                            guard isTap else { return }
                            
                            let midX = geo.size.width / 2
                            if value.startLocation.x >= midX {
                                if currentPage < totalPages - 1 {
                                    withAnimation { currentPage += 1 }
                                } else {
                                    hasSeenOnboarding = true
                                    UserDefaults.standard.set(true, forKey: "HasSeenOnboarding")
                                }
                            } else if currentPage > 0 {
                                withAnimation { currentPage -= 1 }
                            }
                        }
                )
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage
                                      ? Color.accentColor
                                      : Color.secondary.opacity(0.4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    .padding(.bottom, 60)
                    .allowsHitTesting(false)
                    
                    if currentPage == totalPages - 1 {
                        Button {
                            hasSeenOnboarding = true
                            UserDefaults.standard.set(true, forKey: "HasSeenOnboarding")
                            UIApplication.shared.connectedScenes
                                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                                .first?
                                .rootViewController?
                                .dismiss(animated: true)
                        } label: {
                            Text("Get Started")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 40)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            if image == "onboarding" {
                            // Case 1: Custom Asset ("onboarding")
                            Image(image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200) // Larger size
                        } else {
                            // Case 2: SF Symbol (any other name, like "timelapse")
                            Image(systemName: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80) // Smaller size
                                .foregroundColor(.accentColor)
                        }
            Text(title)
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color.primary)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.secondary)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
    
}


#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}

