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
    private let totalPages = 4
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        name: "onboarding",
                        isSystemImage: false,
                        title: "Welcome to Clay",
                        description: "Your personal AI serve coach — powered by the newest AI technology",
                        cornerRadius: 30
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        name: "camera",
                        title: "Keep the Camera Steady",
                        description: "Record with your phone on the floor and use slow motion settings for the most precise results"
                    )
                    .tag(1)

                    OnboardingPage(
                        name: "setup",
                        isSystemImage: false,
                        title: "Capture the Whole Serve",
                        description: "Make sure the full serve is visible: the toss, contact point, trajectory, and landing on the opposite side",
                        size: CGSize(width: 300, height: 3000),
                        cornerRadius: 30
                    )
                    .tag(2)
                    
                    OnboardingPage(
                        name: "chart.bar.fill",
                        title: "Let’s Get Started",
                        description: "Upload or record your first serve"
                    )
                    .tag(3)
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
    let name: String
    var isSystemImage: Bool = true
    let title: String
    let description: String
    var size: CGSize = .init(width: 200, height: 200)
    var cornerRadius: CGFloat? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Group {
                if isSystemImage {
                    Image(systemName: name)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.accentColor)
                } else {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(maxWidth: size.width)                    // ← use maxWidth ONLY
            .clipShape(
                cornerRadius == nil
                    ? AnyShape(Rectangle())
                    : AnyShape(RoundedRectangle(cornerRadius: cornerRadius!))
            )


            Text(title)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.primary)

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
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

