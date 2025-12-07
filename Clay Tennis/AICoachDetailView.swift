//
//  AICoachDetailView.swift
//  Clay Tennis
//
//  Created by Christian on 07.12.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct AICoachDetailView: View {
    
    let item: FeedItem
    let onReplayAICoach: (URL) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateTips = false
    
    private var previewTips: [String] {
        Array(item.aiTips.prefix(2))
    }
    
    var body: some View {
        ZStack {
            
            // MARK: - Blurred Background Thumbnail
            if let url = item.thumbnailURL,
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 28)
                    .overlay(Color.black.opacity(0.25))
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - HERO CARD
                    heroCard
                    
                    // MARK: - INSIGHT PREVIEW
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Insights")
                            .font(.title3.bold())
                        
                        ForEach(previewTips, id: \.self) { tip in
                            insightCard(text: tip)
                                .opacity(animateTips ? 1 : 0)
                                .offset(y: animateTips ? 0 : 10)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.85),
                                    value: animateTips
                                )
                        }
                    }
                    .padding(.horizontal, 22)
                    
                    // MARK: - SESSION META
                    metaSection
                    
                    // MARK: - REPLAY CTA
                    replayButton
                        .padding(.horizontal, 22)
                        .padding(.bottom, 40)
                }
                .padding(.top, 80)
            }
        }
        .onAppear {
            animateTips = true
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - HERO CARD
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            HStack {
                Label("AI Coach Analysis", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(item.aiTipCount ?? 0) Technique Insights")
                .font(.largeTitle.bold())
            
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(26)
        .shadow(color: .black.opacity(0.25), radius: 18, y: 8)
        .padding(.horizontal, 22)
    }
    
    // MARK: - INSIGHT CARD
    
    private func insightCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.white.opacity(0.35)
                )
        )
        .overlay(
            Rectangle()
                .frame(width: 4)
                .foregroundColor(.blue.opacity(0.6)),
            alignment: .leading
        )
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    // MARK: - META SECTION
    
    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session Details")
                .font(.headline)
            
            HStack(spacing: 10) {
                metaChip("Serve")
                metaChip("Trophy Pose")
                metaChip("Right Arm")
            }
        }
        .padding(.horizontal, 22)
    }
    
    private func metaChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.15))
            )
            .foregroundColor(.blue)
    }
    
    // MARK: - REPLAY BUTTON
    
    private var replayButton: some View {
        Button {
            if let url = item.thumbnailURL {
                onReplayAICoach(url)
            }
            
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                
                Text("Reopen AI Analysis")
                    .font(.headline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .foregroundColor(.blue)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
    }
}
