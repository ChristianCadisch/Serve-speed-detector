//
//  FeedView.swift
//  Main view used to see the past tennis serves


import SwiftUI
import AVFoundation
import Photos
import UIKit



struct FeedView: View {
    
    @State private var featuredThumbnail: UIImage?
    
    @State private var feedItems: [FeedItem] = []
    @State private var videoThumbnails: [String: UIImage] = [:]
    @State private var selectedAICoachItem: FeedItem?
    @State private var selectedQuizItem: FeedItem?
    
    
    
    var onAddTapped: () -> Void
    var onTheorySelected: () -> Void
    var onVideoSelected: (URL) -> Void
    var onAICoachSelected: (FeedItem) -> Void
    var onQuizSelected: (QuizIdentifier, QuizDifficulty) -> Void
    var onCoachHubSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Top Bar
            HStack(alignment: .firstTextBaseline) {

                Text("CLAY")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {

                    let weekly = weeklyStreak()
                    let daily = dailyStreak()
                    let useDaily = daily > weekly

                    Text(useDaily ? "DAILY STREAK" : "WEEKLY STREAK")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(.secondary)

                    Text("\(useDaily ? daily : weekly)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                }
            }
            .padding(.horizontal)
            .padding(.top, -28)
            .padding(.bottom, 6)
            .background(Color(.systemBackground))

            
            
            
            // MARK: - Unified Feed List
            List {
                
                // ✅ HERO
                heroSection
                        .listRowInsets(.init())
                        .listRowSeparator(.hidden)
                        .background(Color.clear)
                
                // ✅ PRESCRIBED NEXT STEPS (DIRECTLY UNDER HERO)
                Section {
                    prescribedTrainingCarousel
                        .listRowInsets(.init())
                        .listRowSeparator(.hidden)
                        .background(Color.clear)
                }
                
                // ✅ TIMELINE HISTORY
                ForEach(groupedFeedItems, id: \.title) { section in
                    Section(
                        header:
                            Text(section.title)
                            .font(.caption.bold())
                            .tracking(1)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .padding(.leading)
                    ) {
                        ForEach(section.items) { item in
                            switch item.type {
                            case .serve:
                                serveRow(item)
                            case .quizResult:
                                quizResultRow(item)
                            case .aiCoach:
                                aiCoachRow(item)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationDestination(item: $selectedAICoachItem) { item in
                AICoachDetailView(
                    item: item,
                    onReplayAICoach: { item in
                        onAICoachSelected(item)
                    }

                )
            }

            
            
            
            .navigationDestination(item: $selectedQuizItem) { item in
                let topic = QuizIdentifier.allCases.first {
                    $0.tableName == item.quizTopicKey
                } ?? .serve
                
                let difficulty: QuizDifficulty = {
                    switch item.quizDifficulty {
                    case .easy: return .easy
                    case .medium: return .medium
                    case .hard: return .hard
                    case .none: return .easy
                    }
                }()
                
                QuizResultView(
                    score: item.quizCorrectAnswers ?? 0,
                    total: item.quizTotalQuestions ?? 1,
                    quizID: topic,
                    difficulty: difficulty,
                    onNextQuiz: { id in
                        print("✅ [FEED → QUIZ] Next quiz tapped:", id.topic, id.difficulty)
                        onQuizSelected(id.topic, id.difficulty)
                    },
                    shouldPostToFeed: false
                )
            }
            
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.bottom, 4)
            .environment(\.defaultMinListRowHeight, 0)
            .onAppear {
                loadFeedItems()
            }
            .onReceive(NotificationCenter.default.publisher(for: .feedItemCreated)) { notification in
                if let feedItem = notification.object as? FeedItem {
                    
                    feedItems.append(feedItem)
                    
                    if let url = feedItem.thumbnailURL {
                        generateAndCacheThumbnail(for: url)
                    }
                }
            }
            
            
            
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Streak Calculations

    private struct WeekKey: Hashable {
        let year: Int
        let week: Int
    }
    
    private var emptyFeaturedHero: some View {
        ZStack(alignment: .bottomLeading) {

            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.85),
                    Color.cyan.opacity(0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {

                Text("Record Your First Serve")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 6)

                Text("Start your training and unlock AI analysis")
                    .font(.footnote.weight(.semibold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(28)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .onTapGesture {
            onCoachHubSelected()
        }
    }
    
    private var heroSection: some View {
        Group {
            if feedItems.isEmpty {
                emptyFeaturedHero
            } else if let hero = editorialHero {
                featuredHero(hero)
            }
        }
    }



    private func weeklyStreak() -> Int {
        let calendar = Calendar.current

        // Extract all unique year-week pairs
        let uniqueWeeks = Set(
            feedItems.map { item -> WeekKey in
                let comp = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: item.date)
                return WeekKey(
                    year: comp.yearForWeekOfYear ?? 0,
                    week: comp.weekOfYear ?? 0
                )
            }
        )



        // Convert to sorted array (latest first)
        let sortedWeeks = uniqueWeeks.sorted {
            ($0.year, $0.week) > ($1.year, $1.week)
        }

        guard let first = sortedWeeks.first else { return 0 }

        var streak = 1
        var expectedYear = first.year
        var expectedWeek = first.week

        for key in sortedWeeks.dropFirst() {
            let year = key.year
            let week = key.week

            expectedWeek -= 1
            if expectedWeek == 0 {
                expectedYear -= 1
                let weeksInPrevYear = calendar.range(
                    of: .weekOfYear,
                    in: .yearForWeekOfYear,
                    for: Date()
                )?.count ?? 52
                expectedWeek = weeksInPrevYear
            }

            if year == expectedYear && week == expectedWeek {
                streak += 1
            } else {
                break
            }
        }


        return streak
    }


    private func dailyStreak() -> Int {
        let calendar = Calendar.current

        // Extract all unique days (midnight-normalized)
        let uniqueDays = Set(
            feedItems.map { calendar.startOfDay(for: $0.date) }
        )
        let sortedDays = uniqueDays.sorted(by: >)

        guard let first = sortedDays.first else { return 0 }

        var streak = 1
        var expectedDate = first

        for day in sortedDays.dropFirst() {
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate

            if calendar.isDate(day, inSameDayAs: expectedDate) {
                streak += 1
            } else {
                break
            }
        }

        // Only return when 1 ≤ streak < 100
        return (streak >= 1 && streak < 100) ? streak : 0
    }

    
    private var editorialHero: FeedItem? {
        feedItems
            .sorted(by: { $0.date > $1.date })
            .first(where: { $0.fastestSpeedKmh != nil || $0.aiTipCount != nil })
    }
    
    private var groupedFeedItems: [(title: String, items: [FeedItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: feedItems) { item -> String in
            if calendar.isDateInToday(item.date) { return "TODAY" }
            else if calendar.isDateInYesterday(item.date) { return "YESTERDAY" }
            else { return "LAST WEEK" }
        }
        
        return grouped
            .map { ($0.key, $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted { $0.items.first!.date > $1.items.first!.date }
    }
    
    private var prescribedTrainingCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("RECOMMENDED QUIZZES")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    
                    trainingPrescriptionCard(
                        title: "Serve Fundamentals",
                        subtitle: "Start the quiz",
                        accent: .blue,
                        destinationTopic: .serve
                    )

                    trainingPrescriptionCard(
                        title: "Tactics Awareness",
                        subtitle: "Improve decisions",
                        accent: .orange,
                        destinationTopic: .tactics
                    )

                    trainingPrescriptionCard(
                        title: "Forehand Technique",
                        subtitle: "Master core mechanics",
                        accent: .green,
                        destinationTopic: .forehand
                    )

                    
                    seeMoreTrainingCard
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
    
    private func trainingPrescriptionCard(
        title: String,
        subtitle: String,
        accent: Color,
        destinationTopic: QuizIdentifier? = nil
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("PRIORITY DRILL")
                .font(.caption2.bold())
                .tracking(1)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(size: 17, weight: .semibold))

            Text(subtitle.uppercased())
                .font(.caption2)
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(width: 210)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.25), accent.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .onTapGesture {
            if let t = destinationTopic {
                onQuizSelected(t, .easy) 
            } else {
                onTheorySelected()
            }
        }
    }


    
    private var seeMoreTrainingCard: some View {
        VStack(spacing: 10) {
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("See All Training")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
        }
        .frame(width: 120, height: 120)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .onTapGesture {
            onTheorySelected()
        }
    }
    
    
    
    private func featuredHero(_ item: FeedItem) -> some View {
        ZStack(alignment: .bottomLeading) {

            GeometryReader { geo in
                if let url = item.thumbnailURL,
                   let image = videoThumbnails[url.path] {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: 380)
                        .clipped()
                }
            }
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.85),
                        .black.opacity(0.45),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {

                Text(item.primaryMetricText ?? item.title)
                    .font(.system(size: 58, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)

                if let subtitle = item.subtitle {
                    Text(subtitle.uppercased())
                        .font(.caption)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(28)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .onTapGesture {
            switch item.type {
            case .serve:
                if let url = item.thumbnailURL { onVideoSelected(url) }
            case .aiCoach:
                selectedAICoachItem = item
            case .quizResult:
                selectedQuizItem = item
            }
        }
    }

    
    
    
    
    private func serveRow(_ item: FeedItem) -> some View {
        HStack(spacing: 14) {

            if let url = item.thumbnailURL,
               let thumbnail = videoThumbnails[url.path] {

                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)   // MATCH AI COACH
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {

                Text(item.subtitle?.uppercased() ?? "SESSION SERVE")
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(.secondary)

                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))
            }

            Spacer()

            if let speed = item.fastestSpeedKmh {
                VStack(spacing: 0) {
                    Text("\(Int(speed))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded)) // MATCH AI
                    Text("KM/H")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)  // MATCH AI COACH
        .background {
            ZStack(alignment: .leading) {

                Color(.secondarySystemBackground)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.85), .cyan.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .onTapGesture {
            if let url = item.thumbnailURL { onVideoSelected(url) }
        }
    }


    
    
    
    
    
    private func loadFeedItems() {
        guard let data = UserDefaults.standard.data(forKey: "FeedItems"),
              let items = try? JSONDecoder().decode([FeedItem].self, from: data) else {
            feedItems = []
            return
        }
        
        feedItems = items
        
        for item in items {
            if let url = item.thumbnailURL,
               FileManager.default.fileExists(atPath: url.path) {
                
                generateAndCacheThumbnail(for: url)
                
            } else if item.assetLocalIdentifier != nil {
                
                recoverVideoIfNeeded(for: item) { recoveredURL in
                    guard let recoveredURL else { return }
                    
                    DispatchQueue.main.async {
                        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
                            feedItems[index] = FeedItem(
                                id: item.id,
                                type: item.type,
                                date: item.date,
                                thumbnailURL: recoveredURL,
                                assetLocalIdentifier: item.assetLocalIdentifier,
                                title: item.title,
                                subtitle: item.subtitle,
                                primaryMetricText: item.primaryMetricText,
                                secondaryMetricText: item.secondaryMetricText,
                                fastestSpeedKmh: item.fastestSpeedKmh,
                                serveCount: item.serveCount,
                                aiTipCount: item.aiTipCount,
                                aiTips: item.aiTips,
                                aiTipsDetailed: item.aiTipsDetailed,
                                positiveAITips: item.positiveAITips,
                                side: item.side,
                                quizTopicKey: item.quizTopicKey,
                                quizDifficulty: item.quizDifficulty,
                                quizCorrectAnswers: item.quizCorrectAnswers,
                                quizTotalQuestions: item.quizTotalQuestions,
                            )
                            
                            generateAndCacheThumbnail(for: recoveredURL)
                            FeedItemStorage.save(feedItems)
                        }
                    }
                }
            }
        }
        
        
    }
    
    
    
    
    
    private func generateAndCacheThumbnail(for url: URL) {
        let key = url.path
        
        guard videoThumbnails[key] == nil else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    videoThumbnails[key] = image
                }
                
            } catch {
                print("❌ [THUMB] FAILURE for:", key)
                print("❌ [THUMB] Error:", error.localizedDescription)
            }
        }
    }
    
    
    
    
    
    
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "plus.app")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            Text(NSLocalizedString("feed_empty_title", tableName: "general", comment: ""))
                .font(.title3)
                .bold()
            
            Text(NSLocalizedString("feed_empty_subtitle", tableName: "general", comment: ""))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { onAddTapped() }) {
                Text(
                    NSLocalizedString(
                        "feed_add_first_video",
                        tableName: "general",
                        comment: ""
                    )
                )
                .font(.headline)
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }
    
    // MARK: - Quiz Result Row
    
    private func quizResultRow(_ item: FeedItem) -> some View {
        HStack(spacing: 14) {

            if let topicKey = item.quizTopicKey,
               let topic = QuizIdentifier.allCases.first(where: { $0.tableName == topicKey }) {

                Image(topic.thumbnailImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)   // unified size
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {

                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))

                Text(item.quizDifficulty?.localizedTitle.uppercased() ?? "")
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(.secondary)

                if let c = item.quizCorrectAnswers,
                   let t = item.quizTotalQuestions {

                    let pct = Int((Double(c) / Double(max(t, 1))) * 100)

                    Text("\(pct)% MASTERY")
                        .font(.footnote.bold())
                        .tracking(0.5)
                        .foregroundStyle(pct >= 70 ? .primary : .secondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .onTapGesture {
            selectedQuizItem = item
        }
    }



    
    
    
    // MARK: - Difficulty Badge
    
    private func difficultyBadge(_ difficulty: FeedDifficulty) -> some View {
        Text(difficulty.localizedTitle.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(difficultyColor(difficulty).opacity(0.2))
            )
            .foregroundColor(difficultyColor(difficulty))
    }
    
    
    // MARK: - Reused Progress Bar (LessonDetailView Style)
    
    private func quizProgressBar(progress: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 6)
    }
    
    
    private func recoverVideoIfNeeded(for item: FeedItem, completion: @escaping (URL?) -> Void) {
        guard let assetID = item.assetLocalIdentifier else {
            completion(nil)
            return
        }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = assets.firstObject else {
            completion(nil)
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let urlAsset = avAsset as? AVURLAsset else {
                completion(nil)
                return
            }
            
            let fm = FileManager.default
            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let newURL = docs.appendingPathComponent("recovered_\(UUID().uuidString).mov")
            
            do {
                try fm.copyItem(at: urlAsset.url, to: newURL)
                completion(newURL)
            } catch {
                completion(nil)
            }
        }
    }
    
    
    
    // MARK: - Difficulty Color Mapping
    
    private func difficultyColor(_ difficulty: FeedDifficulty?) -> Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .blue
        case .hard:
            return .purple
        case .none:
            return .gray
        }
    }
    
    
    private func aiCoachRow(_ item: FeedItem) -> some View {
        HStack(spacing: 14) {

            if let url = item.thumbnailURL,
               let thumbnail = videoThumbnails[url.path] {

                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {

                if let tips = item.aiTipCount {
                    if let side = item.side{
                        Text("ANALYSIS FROM \(side.uppercased())")
                            .font(.caption2.bold())
                            .tracking(1)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))

            }

            Spacer()

            if let tips = item.aiTipCount {
                VStack(spacing: 0) {
                    Text("\(tips)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))

                    Text("FIXES")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background {
            ZStack(alignment: .leading) {

                Color(.secondarySystemBackground)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                    )
                    .frame(width: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .onTapGesture {
            selectedAICoachItem = item
        }
    }

}


// MARK: - FeedDifficulty Localization

extension FeedDifficulty {
    var localizedTitle: String {
        switch self {
        case .easy:
            return NSLocalizedString("difficulty_easy_adjective", tableName: "general", comment: "")
        case .medium:
            return NSLocalizedString("difficulty_medium_adjective", tableName: "general", comment: "")
        case .hard:
            return NSLocalizedString("difficulty_hard_adjective", tableName: "general", comment: "")
        }
    }
}



enum FeedItemType: String, Codable {
    case serve
    case aiCoach
    case quizResult
}

enum FeedDifficulty: String, Codable {
    case easy
    case medium
    case hard
}

struct FeedItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: FeedItemType
    let date: Date

    // ✅ NEW: AI feedback payload
    var aiTips: [String]
    var aiTipsDetailed: [String]
    var positiveAITips: [String]
    var keyword: [String]

    // Shared visuals
    let thumbnailURL: URL?          // cache only
    let assetLocalIdentifier: String?   // ✅ permanent identity


    // Text
    let title: String
    let subtitle: String?

    // Trailing metric
    let primaryMetricText: String?

    // Secondary metric
    let secondaryMetricText: String?

    // Serve-specific
    let fastestSpeedKmh: Double?
    let serveCount: Int?

    // AI Coach–specific
    let aiTipCount: Int?
    let side: String?

    // Quiz-specific
    let quizTopicKey: String?
    let quizDifficulty: FeedDifficulty?
    let quizCorrectAnswers: Int?
    let quizTotalQuestions: Int?

    init(
        id: UUID = UUID(),
        type: FeedItemType,
        date: Date,

        thumbnailURL: URL?,
        assetLocalIdentifier: String?,

        title: String,
        subtitle: String? = nil,

        primaryMetricText: String? = nil,
        secondaryMetricText: String? = nil,

        fastestSpeedKmh: Double? = nil,
        serveCount: Int? = nil,

        aiTipCount: Int? = nil,
        aiTips: [String] = [],
        aiTipsDetailed: [String] = [],
        positiveAITips: [String] = [],
        keyword: [String] = [],
        side: String? = nil,


        quizTopicKey: String? = nil,
        quizDifficulty: FeedDifficulty? = nil,
        quizCorrectAnswers: Int? = nil,
        quizTotalQuestions: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.thumbnailURL = thumbnailURL
        self.assetLocalIdentifier = assetLocalIdentifier
        self.title = title
        self.subtitle = subtitle
        self.primaryMetricText = primaryMetricText
        self.secondaryMetricText = secondaryMetricText
        self.fastestSpeedKmh = fastestSpeedKmh
        self.serveCount = serveCount
        self.aiTipCount = aiTipCount
        self.aiTips = aiTips
        self.aiTipsDetailed = aiTipsDetailed
        self.positiveAITips = positiveAITips
        self.keyword = keyword
        self.side = side
        self.quizTopicKey = quizTopicKey
        self.quizDifficulty = quizDifficulty
        self.quizCorrectAnswers = quizCorrectAnswers
        self.quizTotalQuestions = quizTotalQuestions
    }
    
}




