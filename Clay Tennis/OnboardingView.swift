//
//  OnboardingView.swift
//  Instruction pages meant for first time users
//

import Foundation
import SwiftUI
import Photos

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
                        title: NSLocalizedString("onboarding_page1_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("onboarding_page1_desc", tableName: "general", comment: ""),
                        cornerRadius: 30
                    )
                    .tag(0)

                    OnboardingPage(
                        name: "camera",
                        title: NSLocalizedString("onboarding_page2_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("onboarding_page2_desc", tableName: "general", comment: "")
                    )
                    .tag(1)

                    OnboardingPage(
                        name: "setup",
                        isSystemImage: false,
                        title: NSLocalizedString("onboarding_page3_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("onboarding_page3_desc", tableName: "general", comment: ""),
                        size: CGSize(width: 300, height: 3000),
                        cornerRadius: 30
                    )
                    .tag(2)

                    OnboardingPage(
                        name: "chart.bar.fill",
                        title: NSLocalizedString("onboarding_page4_title", tableName: "general", comment: ""),
                        description: NSLocalizedString("onboarding_page4_desc", tableName: "general", comment: "")
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
                                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                        print("📸 Photo permission status after onboarding:", status)
                                    }

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
                            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                print("📸 Photo permission status after onboarding:", status)
                            }
                            UIApplication.shared.connectedScenes
                                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                                .first?
                                .rootViewController?
                                .dismiss(animated: true)
                        } label: {
                            Text(NSLocalizedString("onboarding_get_started", tableName: "general", comment: ""))
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
            .frame(maxWidth: size.width)
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

