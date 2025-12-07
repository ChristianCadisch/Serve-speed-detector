//
//  FeedView.swift
//  Main view used to see the past tennis serves


import SwiftUI
import AVFoundation
import Photos
import UIKit



struct FeedView: View {
    @State private var analyzedVideos: [URL] = []
    @State private var videoThumbnails: [URL: UIImage] = [:]
    @State private var featuredThumbnail: UIImage?
    @State private var fastestSpeeds: [URL: Double] = [:]
    @State private var assetURLMap: [String: URL] = [:]
    @State private var serveCounts: [URL: Int] = [:]
    @State private var feedItems: [FeedItem] = []

    var onAddTapped: () -> Void
    var onSettingsTapped: () -> Void
    var onVideoSelected: (URL) -> Void

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
                                serveCounts.values.reduce(0, +)
                            )
                        )
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -45)
                .padding(.bottom, 2)
                .background(Color(.systemBackground))

                // MARK: - Empty State
                if analyzedVideos.isEmpty && feedItems.isEmpty {
                    emptyState
                }

                // MARK: - Unified Feed List
                List {

                    // MARK: - Featured Serve (UNCHANGED)
                    if let featuredVideoURL = getFeaturedVideoURL(),
                       let speed = fastestSpeeds[featuredVideoURL] {

                        Section {
                            ZStack(alignment: .bottomLeading) {
                                if let thumbnail = featuredThumbnail {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 300)
                                        .clipped()
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 300)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("feed_most_recent_serve", tableName: "general", comment: ""))
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("\(Int(speed)) km/h")
                                        .font(.largeTitle)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .padding()
                            }
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onVideoSelected(featuredVideoURL)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }

                    // MARK: - Other Serves (UNCHANGED)
                    if analyzedVideos.count > 1 {
                        Section(
                            header: Text(
                                NSLocalizedString("feed_other_serves", tableName: "general", comment: "")
                            )
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(nil)
                        ) {

                            ForEach(analyzedVideos.filter { $0 != getFeaturedVideoURL() }.reversed(), id: \.self) { videoURL in
                                let speed = fastestSpeeds[videoURL] ?? 0
                                let servecount = serveCounts[videoURL] ?? 0

                                HStack(spacing: 0) {
                                    if let thumbnail = videoThumbnails[videoURL] {
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

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(Int(speed)) km/h")
                                            .font(.headline)
                                            .fontWeight(.bold)

                                        HStack(spacing: 6) {
                                            Image(systemName: "tennisball")
                                            Text(
                                                String(
                                                    format: NSLocalizedString(
                                                        "feed_serve_recorded_format",
                                                        tableName: "general",
                                                        comment: ""
                                                    ),
                                                    servecount
                                                )
                                            )
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.leading, 12)

                                    Spacer()
                                }
                                .frame(height: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.blue.opacity(0.15))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onVideoSelected(videoURL)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        }
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
                            ForEach(feedItems.sorted(by: { $0.date > $1.date })) { item in
                                if item.type == .quizResult {
                                    quizResultRow(item)
                                }
                            }
                        }
                    }
                }

                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.bottom, 4)
                .environment(\.defaultMinListRowHeight, 0)
                .onAppear {
                    loadAnalyzedVideos()
                    loadFeaturedThumbnail()
                    loadFeedItems()
                }
                .onReceive(NotificationCenter.default.publisher(for: .feedItemCreated)) { notification in
                    if let feedItem = notification.object as? FeedItem {
                        feedItems.append(feedItem)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }

    // MARK: - Helper Methods

    private func loadFeedItems() {
        guard let data = UserDefaults.standard.data(forKey: "FeedItems"),
              let items = try? JSONDecoder().decode([FeedItem].self, from: data) else {
            feedItems = []
            return
        }
        feedItems = items
    }
    
    private func getFeaturedVideoURL() -> URL? {
        analyzedVideos.last
    }

    private func loadFeaturedThumbnail() {
        guard let featuredVideoURL = getFeaturedVideoURL() else {
            featuredThumbnail = nil
            return
        }

        let asset = AVAsset(url: featuredVideoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            featuredThumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            featuredThumbnail = nil
        }
    }

    private func deleteVideo(_ videoURL: URL) {
        guard var savedIds = UserDefaults.standard.stringArray(forKey: "AnalyzedAssetIDs") else { return }

        if let (id, _) = assetURLMap.first(where: { $0.value == videoURL }) {
            savedIds.removeAll { $0 == id }
            UserDefaults.standard.set(savedIds, forKey: "AnalyzedAssetIDs")
            assetURLMap.removeValue(forKey: id)
        }

        analyzedVideos.removeAll { $0 == videoURL }
        fastestSpeeds.removeValue(forKey: videoURL)
        serveCounts.removeValue(forKey: videoURL)
        videoThumbnails.removeValue(forKey: videoURL)

        if analyzedVideos.isEmpty {
            featuredThumbnail = nil
        } else {
            loadFeaturedThumbnail()
        }
    }

    private func loadAnalyzedVideos() {
        analyzedVideos.removeAll()
        assetURLMap.removeAll()
        guard let savedIds = UserDefaults.standard.stringArray(forKey: "AnalyzedAssetIDs") else { return }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: savedIds, options: nil)
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic

        let group = DispatchGroup()

        assets.enumerateObjects { asset, _, _ in
            group.enter()
            manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    DispatchQueue.main.async {
                        assetURLMap[asset.localIdentifier] = urlAsset.url
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.analyzedVideos = savedIds.compactMap { self.assetURLMap[$0] }
            self.loadFastestSpeeds()
            self.loadThumbnails()
            self.loadFeaturedThumbnail()
            self.loadServeCounts()
        }
    }

    private func loadServeCounts() {
        for url in analyzedVideos {
            let key = "ServeCount_\(url.absoluteString)"
            serveCounts[url] = UserDefaults.standard.integer(forKey: key)
        }
    }

    private func loadFastestSpeeds() {
        for url in analyzedVideos {
            let key = "FastestSpeed_\(url.absoluteString)"
            fastestSpeeds[url] = UserDefaults.standard.double(forKey: key)
        }
    }

    private func loadThumbnails() {
        for url in analyzedVideos {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
                videoThumbnails[url] = UIImage(cgImage: cgImage)
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

struct FeedItem: Identifiable, Codable {
    let id: UUID
    let type: FeedItemType
    let date: Date

    // Shared visuals
    let thumbnailURL: URL?

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

        title: String,
        subtitle: String? = nil,

        primaryMetricText: String? = nil,
        secondaryMetricText: String? = nil,

        fastestSpeedKmh: Double? = nil,
        serveCount: Int? = nil,

        aiTipCount: Int? = nil,

        quizTopicKey: String? = nil,
        quizDifficulty: FeedDifficulty? = nil,
        quizCorrectAnswers: Int? = nil,
        quizTotalQuestions: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.thumbnailURL = thumbnailURL
        self.title = title
        self.subtitle = subtitle
        self.primaryMetricText = primaryMetricText
        self.secondaryMetricText = secondaryMetricText
        self.fastestSpeedKmh = fastestSpeedKmh
        self.serveCount = serveCount
        self.aiTipCount = aiTipCount
        self.quizTopicKey = quizTopicKey
        self.quizDifficulty = quizDifficulty
        self.quizCorrectAnswers = quizCorrectAnswers
        self.quizTotalQuestions = quizTotalQuestions
    }
}

