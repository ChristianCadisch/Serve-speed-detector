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
    var onSettingsTapped: () -> Void
    var onVideoSelected: (URL) -> Void
    var onAICoachSelected: (String) -> Void
    var onQuizSelected: (QuizIdentifier, QuizDifficulty) -> Void


    var body: some View {
            VStack(spacing: 0) {

                // MARK: - Top Bar
                HStack {
                    Text(NSLocalizedString("feed_title", tableName: "general", comment: ""))
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "tennisball")
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "feed_serve_counter_format",
                                    tableName: "general",
                                    comment: ""
                                ),
                                //serveCounts.values.reduce(0, +)
                            )
                        )
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -45)
                .padding(.bottom, 2)
                .background(Color(.systemBackground))



                // MARK: - Unified Feed List
                List {

                    // MARK: - Featured Serve (UNCHANGED)
                    if let featured = feedItems.sorted(by: { $0.date > $1.date }).first {
                        featuredHero(featured)
                    }


                   

                    // MARK: - ✅ Quiz Results (NOW AT THE BOTTOM)
                    if !feedItems.isEmpty {
                        Section(
                            header: Text(
                                NSLocalizedString("feed_quiz_results_title", tableName: "general", comment: "")
                            )
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(nil)
                        ) {
                            ForEach(feedItems.sorted(by: { $0.date > $1.date }).dropFirst()) { item in
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
                .navigationDestination(item: $selectedAICoachItem) { item in
                    AICoachDetailView(
                        item: item,
                        onReplayAICoach: { _ in   // ✅ explicitly accept the required URL argument
                            if let assetID = item.assetLocalIdentifier {
                                onAICoachSelected(assetID)
                            } else {
                                print("❌ [FEED] Missing assetLocalIdentifier for AI Coach item")
                            }
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

                        print("🟢 [FEED] New item received:", feedItem.type)
                        feedItems.append(feedItem)

                        if let url = feedItem.thumbnailURL {
                            print("🖼 [FEED] Generating thumbnail for new item:", url.lastPathComponent)
                            generateAndCacheThumbnail(for: url)
                        }
                    }
                }



            }
            .edgesIgnoringSafeArea(.bottom)
        }

    // MARK: - Helper Methods

    
    private func featuredHero(_ item: FeedItem) -> some View {
        ZStack(alignment: .bottomLeading) {

            GeometryReader { geo in
                Group {
                    // ✅ SERVE & AI COACH
                    if let url = item.thumbnailURL,
                       let image = videoThumbnails[url.path] {

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()                 // ✅ FORCE FILL
                            .frame(width: geo.size.width,  // ✅ HARD WIDTH CLAMP
                                   height: 300)            // ✅ HARD HEIGHT CLAMP
                            .clipped()                      // ✅ HARD CROP

                    // ✅ QUIZ
                    } else if item.type == .quizResult,
                              let key = item.quizTopicKey,
                              let topic = QuizIdentifier.allCases.first(where: { $0.tableName == key }) {

                        Image(topic.thumbnailImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width,
                                   height: 300)
                            .clipped()

                    // ✅ FALLBACK
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: geo.size.width, height: 300)
                    }
                }
            }
            .frame(height: 300)



            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)

                if let metric = item.primaryMetricText {
                    Text(metric)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            switch item.type {
            case .serve:
                if let url = item.thumbnailURL {
                    onVideoSelected(url)
                }
            case .aiCoach:
                selectedAICoachItem = item
            case .quizResult:
                selectedQuizItem = item
            }
        }
    }



    private func serveRow(_ item: FeedItem) -> some View {
        HStack(spacing: 0) {

            if let url = item.thumbnailURL,
               let thumbnail = videoThumbnails[url.path] {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 100)
                    .clipped()
                    .mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 100)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline).bold()

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 12)

            Spacer()

            if let speed = item.fastestSpeedKmh {
                VStack(spacing: 2) {
                    Text("\(Int(speed))")
                        .font(.title3.bold())
                    Text("km/h")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .onTapGesture {
            if let url = item.thumbnailURL {
                    onVideoSelected(url)
                }
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
                                quizTopicKey: item.quizTopicKey,
                                quizDifficulty: item.quizDifficulty,
                                quizCorrectAnswers: item.quizCorrectAnswers,
                                quizTotalQuestions: item.quizTotalQuestions
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
        HStack(spacing: 0) {

            if let topicKey = item.quizTopicKey,
               let topic = QuizIdentifier.allCases.first(where: { $0.tableName == topicKey }) {

                Image(topic.thumbnailImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 100)
                    .clipped()
                    .mask(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 100)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .fontWeight(.bold)

                if let difficulty = item.quizDifficulty {
                    difficultyBadge(difficulty)
                }

                if let correct = item.quizCorrectAnswers,
                   let total = item.quizTotalQuestions {

                    quizProgressBar(
                        progress: total == 0 ? 0 : Double(correct) / Double(total),
                        color: difficultyColor(item.quizDifficulty)
                    )
                }
            }
            .padding(.leading, 12)

            Spacer()

            // ✅ Right-Side Performance Metric (Updated: "Solved")
            if let correct = item.quizCorrectAnswers,
               let total = item.quizTotalQuestions {

                VStack(spacing: 2) {
                    Text("\(Int(Double(correct) / Double(max(total, 1)) * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(NSLocalizedString("quiz_solved_label", tableName: "general", comment: "Solved"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.blue.opacity(0.15))
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .contentShape(Rectangle())
        .listRowInsets(
            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
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
        HStack(spacing: 0) {

            if let url = item.thumbnailURL,
               let thumbnail = videoThumbnails[url.path] {

                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 100)
                    .clipped()
                    .mask(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )

            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 100)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .fontWeight(.bold)

                if let subtitle = item.subtitle {
                    HStack(spacing: 6) {
                        Image(systemName: "tennisball")
                            .font(.caption2)
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 12)

            Spacer()

            if let tips = item.aiTipCount {
                VStack(spacing: 2) {
                    Text("\(tips)")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Tips")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.purple.opacity(0.15))
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedAICoachItem = item
        }
        .listRowInsets(
            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
        .listRowSeparator(.hidden)
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
        self.quizTopicKey = quizTopicKey
        self.quizDifficulty = quizDifficulty
        self.quizCorrectAnswers = quizCorrectAnswers
        self.quizTotalQuestions = quizTotalQuestions
    }
}




