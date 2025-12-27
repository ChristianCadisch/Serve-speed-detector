//
//  AICoachDetailView.swift
//  Clay Tennis
//
//  Premium Rebuild + Keyword Display
//

import SwiftUI

struct AICoachDetailView: View {
    
    let item: FeedItem
    let onReplayAICoach: (FeedItem) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateInsights = false
    @State private var showVideoUpload = false
    
    private var positiveTips: [String]? { item.positiveAITips }
    private var positiveTipsDetailed: [String]? { item.positiveAITipsDetailed }
    private var negativeTips: [String]? { item.aiTips }
    private var negativeTipsDetailed: [String]? { item.aiTipsDetailed }
    
    var body: some View {
        ZStack {
            
            backgroundBlurLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    
                    heroHeader
                        .padding(.top, 32)
                    
                    strengthsCorrectionsSection
                    
                    
                    
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
        VStack(alignment: .leading, spacing: 20) {
            
            HStack(spacing: 14) {
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray5),
                                Color(.systemGray4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color(.systemGray))
                    )


                
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        NSLocalizedString(
                            "ai_coach_analysis_title",
                            tableName: "general",
                            comment: ""
                        )
                    )
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text(
                String(
                    format: NSLocalizedString(
                        "ai_coach_technique_insights_count",
                        tableName: "general",
                        comment: ""
                    ),
                    item.aiTipCount ?? 0
                )
            )
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            
            // PRIMARY CTA
            Button {
                onReplayAICoach(item)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3.weight(.semibold))

                    Text(
                        NSLocalizedString(
                            "ai_coach_reopen_analysis",
                            tableName: "general",
                            comment: ""
                        )
                    )
                        .font(.headline.weight(.semibold))

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color.purple,
                            Color.pink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.22), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            // SECONDARY CTA — Coach Review
            Button {
                showVideoUpload = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.title3.weight(.semibold))

                    Text(
                        NSLocalizedString(
                            "ai_coach_submit_to_coach",
                            tableName: "general",
                            comment: ""
                        )
                    )
                        .font(.headline.weight(.semibold))

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color.orange,
                            Color.orange.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
            }
            .buttonStyle(.plain)



            .navigationDestination(isPresented: $showVideoUpload) {
                let url = item.thumbnailURL
                VideoUploadView(initialVideoURL: url)
                    .onAppear {
                        print("🎥 [UPLOAD NAV] Passing initialVideoURL:", url?.absoluteString ?? "nil")
                    }
            }


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
        
        let positives = item.positiveAITips
        let negatives = item.aiTips
        
        
        let displayedInsights: [(title: String, text: String, icon: String, tint: Color)] = {
            
            
            var output: [(String, String, String, Color)] = []
            
            // Add ALL positive tips
            for p in positives {
                output.append((
                    NSLocalizedString("ai_coach_strength_label", tableName: "general", comment: ""),
                    p,
                    "checkmark.circle.fill",
                    .green
                ))
            }
            
            // Add ALL negative tips
            for n in negatives {
                output.append((
                    NSLocalizedString("ai_coach_correction_label", tableName: "general", comment: ""),
                    n,
                    "exclamationmark.triangle.fill",
                    .orange
                ))
            }
            
            output.forEach { (title, text, _, _) in
                print(" - \(title): \(text)")
            }
            
            return output
        }()
        
        return VStack(alignment: .leading, spacing: 22) {
            
            Text(
                NSLocalizedString(
                    "ai_coach_section_overview",
                    tableName: "general",
                    comment: ""
                )
            )
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
        positiveAITipsDetailed: ["trophy pose", "left arm", "contact", "timing"]
    )
}
