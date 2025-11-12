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
    private let totalPages = 3

    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        image: "tennisball",
                        title: "Welcome to Clay",
                        description: "Analyze and improve your serve with AI-powered feedback."
                    )
                    .tag(0)

                    OnboardingPage(
                        image: "camera.fill",
                        title: "Record Serves",
                        description: "Upload or record your serves directly in the app."
                    )
                    .tag(1)

                    OnboardingPage(
                        image: "chart.bar.fill",
                        title: "Track Progress",
                        description: "See your speed history and performance trends."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            // treat as tap only if there was essentially no drag
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
                                }
                            } else {
                                if currentPage > 0 {
                                    withAnimation { currentPage -= 1 }
                                }
                            }
                        }
                )

                VStack {
                    Spacer()

                    // indicators don’t need to intercept gestures
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.4))
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
                            UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                        } label: {
                            Text("Get Started")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
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
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)

            Text(title)
                .font(.largeTitle)
                .bold()

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}



#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
