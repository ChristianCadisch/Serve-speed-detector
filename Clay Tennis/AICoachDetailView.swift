//
//  AICoachDetailView.swift
//  Clay Tennis
//
//  Premium Rebuild + Keyword Display
//

import SwiftUI

struct AICoachDetailView: View {
    
    let item: FeedItem
    let onReplayAICoach: (URL) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateInsights = false
    
    private var positiveTips: [String]? { item.positiveAITips }
    private var negativeTips: [String]? { item.aiTipsDetailed }
    private var keywords: [String] { item.keyword ?? [] }
    
    var body: some View {
        ZStack {
            
            backgroundBlurLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    
                    heroHeader
                        .padding(.top, 32)
                    
                    strengthsCorrectionsSection
        
                    
                    replayCTA
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { animateInsights = true }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - Background Layer
    
    private var backgroundBlurLayer: some View {
        Group {
            if let url = item.thumbnailURL,
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 40)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(colorScheme == .dark ? 0.45 : 0.28),
                                Color.black.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            } else {
                Color(.systemBackground).ignoresSafeArea()
            }
        }
    }
    
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            HStack(spacing: 14) {
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Coach Analysis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text("\(item.aiTipCount ?? 0) Technique Insights")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Tennis serve analysis")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.22), radius: 22, y: 10)
        .padding(.horizontal, 22)
    }
    
    
    // MARK: - Strengths / Corrections Section
    
    private var strengthsCorrectionsSection: some View {

        // 1) Extract all positives / negatives
        let positives = item.positiveAITips
        let negatives = item.aiTips

        // 2) Compute the displayed list OUTSIDE the ViewBuilder
        let displayedInsights: [(title: String, text: String, icon: String, tint: Color)] = {
            
            var output: [(String, String, String, Color)] = []

            if !positives.isEmpty {
                // Show 1 positive + 1 negative (if available)
                if let pos = positives.first {
                    output.append(("Strength", pos, "checkmark.circle.fill", .green))
                }
                if let neg = negatives.first {
                    output.append(("Correction", neg, "exclamationmark.triangle.fill", .orange))
                }
            } else {
                // Show up to 2 negatives
                for neg in negatives.prefix(2) {
                    output.append(("Correction", neg, "exclamationmark.triangle.fill", .orange))
                }
            }

            return output
        }()

        // 3) Render the section
        return VStack(alignment: .leading, spacing: 22) {

            Text("What the Coach Saw")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 22)

            VStack(spacing: 18) {
                ForEach(displayedInsights.indices, id: \.self) { index in
                    let insight = displayedInsights[index]
                    insightRow(
                        title: insight.title,
                        text: insight.text,
                        icon: insight.icon,
                        tint: insight.tint
                    )
                    .opacity(animateInsights ? 1 : 0)
                    .offset(y: animateInsights ? 0 : 12)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.82),
                        value: animateInsights
                    )
                }
            }
            .padding(.horizontal, 22)
        }
    }

    
    
    // MARK: - Insight Row
    
    private func insightRow(
        title: String,
        text: String,
        icon: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            
            HStack(alignment: .top, spacing: 16) {
                
                Image(systemName: icon)
                    .font(.title3.weight(.bold))
                    .foregroundColor(tint)
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.9))
                    
                    Text(text)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.white.opacity(0.60)
                )
        )
        .shadow(color: .black.opacity(0.10), radius: 14, y: 4)
    }
    
    
    // MARK: - Keyword Bar
    
    private var keywordBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword.uppercased())
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(
                                    colorScheme == .dark ? 0.28 : 0.20
                                ))
                        )
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.top, 4)
    }
    
    
    // MARK: - Metadata Section
    
    private var sessionMetadata: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Session Details")
                .font(.headline)
                .padding(.horizontal, 22)
            
            HStack(spacing: 10) {
                metadataChip("Serve")
                metadataChip("Trophy Pose")
                metadataChip("Right Arm")
            }
            .padding(.horizontal, 22)
        }
    }
    
    private func metadataChip(_ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    Color.blue.opacity(
                        colorScheme == .dark ? 0.25 : 0.18
                    )
                )
        )
        .foregroundColor(.blue)
    }
    
    
    // MARK: - Replay CTA
    
    private var replayCTA: some View {
        Button {
            if let url = item.thumbnailURL {
                onReplayAICoach(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title3.weight(.semibold))
                
                Text("Reopen AI Analysis")
                    .font(.headline.weight(.semibold))
                
                Spacer()
            }
            .padding(.horizontal, 22)
            .frame(height: 60)
            .background(.ultraThinMaterial)
            .cornerRadius(22)
        }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
        .padding(.horizontal, 22)
    }
}


struct AICoachDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AICoachDetailView(
            item: FeedItem.example,
            onReplayAICoach: { _ in }
        )
        .previewDisplayName("AI Coach Detail")
    }
}


// MARK: - FeedItem Example

extension FeedItem {
    static let example = FeedItem(
        id: UUID(),
        type: .aiCoach,
        date: Date(),
        thumbnailURL: nil,
        assetLocalIdentifier: "preview-id",
        title: "AI Coach Session",
        aiTipCount: 2,
        aiTips: ["Improve toss height consistency"],
        positiveAITips: ["Well done on your ball toss!"],
        keyword: ["trophy pose", "left arm", "contact", "timing"]
    )
}
