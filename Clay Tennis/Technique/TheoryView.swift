//
//  TheoryView.swift
//  Clay Tennis
//
//  Unified, Editorial Learning Hub
//

import SwiftUI

struct TheoryView: View {

    // MARK: - Navigation
    weak var navigationDelegate: HomeNavigationDelegate?

    // MARK: - State
    @State private var selectedTopic: QuizIdentifier = .serve
    @State private var highScores: [LessonQuizID: Int] = [:]

    private let passThreshold: Double = 0.7
    @State private var allVideos: [TrainingVideo] = []
    @State private var selectedVideo: TrainingVideo?
    @State private var showLessons = false


    // MARK: - Body
    var body: some View {
        NavigationStack {
            content
                .navigationDestination(item: $selectedVideo) { video in
                    if video.filetype == "long" {
                        LongPlayer(
                            videoId: video.id, 
                            youtubeId: video.youtubeId,
                            title: video.title,
                            subtitle: "\(video.category.uppercased()) · \(video.level.uppercased())",
                            durationText: video.durationText,
                            learningPoints: video.learningPoints ?? []
                        )
                        .navigationTitle(video.title)
                        .navigationBarTitleDisplayMode(.inline)
                    } else {
                        ShortsPlayer(
                            videoId: video.id,
                            youtubeId: video.youtubeId,
                            title: video.title,
                            subtitle: "\(video.duration)-second technique tip"
                        )
                        .navigationTitle(video.title)
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .navigationDestination(isPresented: $showLessons) {
                    LessonsView(
                        topic: selectedTopic,
                        videos: allVideos
                    )
                }

        }
    }
    
    // MARK: - More Lessons Card (FIXED: stronger CTA)

    // MARK: - More Lessons Card (Balanced, Confident CTA)

    fileprivate struct MoreLessonsCard: View {

        private let accentGreen = Color.green
        private let cardWidth: CGFloat = 220
        private let aspectRatio: CGFloat = 3.0 / 4.0

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {

                HStack {
                    Text("MORE LESSONS")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .textCase(.uppercase)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Text("Explore full library")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)

                Text("All short tips and in-depth lessons for this topic.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineLimit(2)

                Spacer(minLength: 0)

                // Grounded CTA row
                HStack(spacing: 6) {
                    Text("Continue learning")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Color.black.opacity(0.18),
                    in: Capsule()
                )
            }
            .padding(18)
            .frame(
                width: cardWidth,
                height: cardWidth / aspectRatio,
                alignment: .leading
            )
            .background(
                LinearGradient(
                    colors: [
                        accentGreen.opacity(0.78),
                        accentGreen.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
            )
        }
    }




    private var content: some View {
        ScrollView {
            VStack(spacing: 32) {
                topicFilter
                unifiedLearnSection
                validateSection
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .onAppear {
            loadHighScores()
            loadVideos()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemGray6).opacity(0.35),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Topic Filter
    private var topicFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(QuizIdentifier.progression, id: \.self) { topic in
                    TopicFilterPill(
                        title: topic.title,
                        isSelected: selectedTopic == topic
                    ) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            selectedTopic = topic
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Unified Learn Section (Shorts + Long)

    
    private var unifiedLearnSection: some View {
        let videos = unifiedVideos

        return VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learn")
                        .font(.headline)

                    Text("Tips and video tutorials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showLessons = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Explore all")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {

                    ForEach(videos) { video in
                        Button {
                            selectedVideo = video
                        } label: {
                            UnifiedVideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showLessons = true
                    } label: {
                        MoreLessonsCard()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }




    // MARK: - Validate Section (Quizzes)

    private var validateSection: some View {
        let next = nextActionDifficulty(for: selectedTopic)

        return VStack(alignment: .leading, spacing: 14) {

            Text("Check your understanding")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                    let state = quizState(for: selectedTopic, difficulty: difficulty)
                    let isNext = (difficulty == next) && state == .unlocked

                    QuizRow(
                        title: "\(difficulty.localizedAdjective) Quiz",
                        subtitle: quizSubtitle(
                            for: selectedTopic,
                            difficulty: difficulty,
                            state: state
                        ),
                        progress: quizProgress(
                            for: selectedTopic,
                            difficulty: difficulty
                        ),
                        state: state,
                        isPrimary: isNext
                    ) {
                        navigationDelegate?.showQuiz(
                            topic: selectedTopic,
                            difficulty: difficulty
                        )
                    }
                }
            }
        }
    }

    // MARK: - Video Filtering

    private var unifiedVideos: [TrainingVideo] {
        let longs = allVideos
            .filter {
                $0.category == selectedTopic.shortsCategory &&
                $0.filetype == "long"
            }
            .sorted { $0.duration < $1.duration }

        let shorts = allVideos
            .filter {
                $0.category == selectedTopic.shortsCategory &&
                $0.filetype == "shorts"
            }
            .sorted { $0.duration < $1.duration }

        var result: [TrainingVideo] = []

        if let firstLong = longs.first {
            result.append(firstLong)
        }

        result.append(contentsOf: shorts.prefix(2))

        return result
    }



    // MARK: - Data Loading

    private func loadVideos() {
        guard let url = Bundle.main.url(forResource: "videos", withExtension: "json") else {
            print("❌ [TheoryView] videos.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            allVideos = try JSONDecoder().decode([TrainingVideo].self, from: data)
            print("✅ [TheoryView] Loaded \(allVideos.count) videos")
        } catch {
            print("❌ [TheoryView] Failed to decode videos.json")
            print(error)
            allVideos = []
        }
    }

    // MARK: - Quiz Logic

    private func highScore(for topic: QuizIdentifier, difficulty: QuizDifficulty) -> Int {
        highScores[LessonQuizID(topic: topic, difficulty: difficulty), default: 0]
    }

    private func quizProgress(for topic: QuizIdentifier, difficulty: QuizDifficulty) -> Double {
        let score = highScore(for: topic, difficulty: difficulty)
        let total = topic.totalQuestions(for: difficulty)
        return total == 0 ? 0 : Double(score) / Double(total)
    }

    private func quizState(for topic: QuizIdentifier, difficulty: QuizDifficulty) -> DifficultyState {
        let progress = quizProgress(for: topic, difficulty: difficulty)
        if progress >= passThreshold { return .completed }

        switch difficulty {
        case .easy:
            return .unlocked
        case .medium:
            return quizState(for: topic, difficulty: .easy) == .completed ? .unlocked : .locked
        case .hard:
            return quizState(for: topic, difficulty: .medium) == .completed ? .unlocked : .locked
        }
    }

    private func nextActionDifficulty(for topic: QuizIdentifier) -> QuizDifficulty? {
        QuizDifficulty.allCases.first {
            quizState(for: topic, difficulty: $0) == .unlocked
        }
    }

    private func quizSubtitle(
        for topic: QuizIdentifier,
        difficulty: QuizDifficulty,
        state: DifficultyState
    ) -> String {
        let score = highScore(for: topic, difficulty: difficulty)
        let total = topic.totalQuestions(for: difficulty)

        switch state {
        case .completed:
            return "Completed"
        case .locked:
            return "Complete previous quiz to unlock"
        case .unlocked:
            return "\(score)/\(total) questions solved"
        }
    }

    private func loadHighScores() {
        var loaded: [LessonQuizID: Int] = [:]
        for topic in QuizIdentifier.allCases {
            for difficulty in QuizDifficulty.allCases {
                let id = LessonQuizID(topic: topic, difficulty: difficulty)
                loaded[id] = UserDefaults.standard.integer(forKey: id.userDefaultsKey)
            }
        }
        highScores = loaded
    }
}


// MARK: - Unified Video Card (FIXED)

fileprivate struct UnifiedVideoCard: View {
    let video: TrainingVideo

    private let cardWidth: CGFloat = 220
    private let aspectRatio: CGFloat = 3.0 / 4.0
    private let accentGreen = Color.green
    
    private var cardHeight: CGFloat {
        cardWidth / aspectRatio
    }

    private var longThumbHeight: CGFloat {
        cardHeight * 0.52
    }


    var body: some View {
        Group {
            if video.isLongForm {
                longCard
            } else {
                shortCard
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Shorts

    private var shortCard: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: video.thumbnailURL) { phase in
                if case let .success(image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipped()

            // Bottom readability only (no full dark overlay)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.30),
                    .clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(video.durationText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.92))
            }
            .padding()
        }
    }

    // MARK: - Long Lessons

    private var longCard: some View {
        HStack(spacing: 0) {

            // Full-height accent stripe
            Rectangle()
                .fill(accentGreen)
                .frame(width: 4)
            
            
            

            VStack(alignment: .leading, spacing: 14) {
                
                
                // MARK: - Thumbnail (secondary)
                AsyncImage(url: video.thumbnailURL) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(height: 92)
                .clipped()
                .cornerRadius(12)

                // MARK: - Editorial Header
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("RECOMMENDED LESSON")
                        .font(.caption2.bold())
                        .tracking(0.8)
                }
                .foregroundStyle(.secondary)

                // MARK: - Core Content
                VStack(alignment: .leading, spacing: 6) {

                    Text(video.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.caption)

                        Text("Coach lesson · \(video.durationText)")
                            .font(.caption.weight(.semibold))

                    }

                    ProgressView(value: LongLessonProgressStore.shared.progress(for: video.id))
                        .progressViewStyle(.linear)
                        .tint(accentGreen.opacity(0.9))
                        .frame(height: 4)
                        .padding(.top, 4)
                }


            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }




}

extension TrainingVideo {
    var isCompleted: Bool {
        LongLessonProgressStore.shared.progress(for: id) >= 0.9
    }
}




// MARK: - Topic Filter Pill

fileprivate struct TopicFilterPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .secondary)
                .background(background)
                .shadow(
                    color: isSelected ? Color.green.opacity(0.25) : .clear,
                    radius: 6,
                    y: 2
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.9),
                            Color.mint.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        } else {
            Capsule()
                .fill(Color(.systemGray6))
        }
    }
}



//
// MARK: - Large Video Card (3:4 + Shade)
//

fileprivate struct LargeVideoCard: View {
    let video: TrainingVideo

    private let cardWidth: CGFloat = 220
    private let aspectRatio: CGFloat = 3.0 / 4.0   // width : height

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .saturation(isWatched ? 0.35 : 1.0)
                        .overlay {
                            if isWatched {
                                Color.black.opacity(0.15)
                            }
                        }
                default:
                    Color(.systemGray5)
                }
            }

            .frame(
                width: cardWidth,
                height: cardWidth / aspectRatio
            )
            .clipped()

            // Bottom readability shade
            LinearGradient(
                colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.35),
                    .clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 96)
            .frame(maxWidth: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if isWatched {
                    watchedBadge
                }


                Text(video.durationText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .cornerRadius(22)
    }
    
    private var isWatched: Bool {
        WatchedVideoStore.shared.isWatched(video.id)
    }

    private var watchedOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(8)
                }
                Spacer()
            }
        }
    }
    private var watchedBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))

            Text("Watched")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    
    
    
}

//
// MARK: - Quiz Row
//

fileprivate struct QuizRow: View {
    let title: String
    let subtitle: String
    let progress: Double
    let state: DifficultyState
    let isPrimary: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {

                HStack {
                    Text(title)
                        .font(.body.weight(.semibold))

                    Spacer()

                    Image(systemName: iconName)
                        .foregroundColor(.secondary)
                }

                if state == .unlocked {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray4))
                            Capsule()
                                .fill(Color.primary.opacity(isPrimary ? 0.45 : 0.28))
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 5)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .opacity(state == .unlocked ? 1.0 : 0.6)
            .padding(.horizontal)
        }
        .disabled(state == .locked)
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch state {
        case .completed: return "checkmark.circle.fill"
        case .locked: return "lock.fill"
        case .unlocked: return "chevron.right"
        }
    }
}

//
// MARK: - Video Model + Data
//

struct TrainingVideo: Identifiable, Decodable, Hashable {
    let id: String
    let youtubeId: String
    let category: String
    let title: String
    let duration: Int
    let type: String
    let level: String
    let filetype: String
    let learningPoints: [String]?

    var durationText: String {
        if filetype == "shorts" {
            return "\(duration) seconds"
        } else {
            return "\(duration) min"
        }
    }

    var thumbnailURL: URL {
        URL(string: "https://img.youtube.com/vi/\(youtubeId)/hqdefault.jpg")!
    }

    var isLongForm: Bool {
        filetype == "long"
    }

    var resolvedLearningPoints: [String] {
        learningPoints ?? []
    }
}


// NEW: per-difficulty state inside a topic
enum DifficultyState {
    case locked
    case unlocked
    case completed
}

extension QuizIdentifier {
    var tintColor: Color {
        switch self {
        case .serve: return .blue
        case .tactics: return .orange
        case .forehand: return .green
        case .backhand: return .purple
        case .volley: return .teal
        case .legwork: return .mint
        }
    }
    
    var thumbnailImageName: String {
            switch self {
            case .serve: return "serve"
            case .tactics: return "tactics"
            case .forehand: return "forehand"
            case .backhand: return "backhand"
            case .volley: return "volley"
            case .legwork: return "legworks"
            }
        }
}

extension QuizIdentifier {

    var titleKey: String {
        switch self {
        case .serve: return "topic_serve"
        case .tactics: return "topic_tactics"
        case .forehand: return "topic_forehand"
        case .backhand: return "topic_backhand"
        case .volley: return "topic_volley"
        case .legwork: return "topic_legwork"
        }
    }

    var localizedTitle: String {
        NSLocalizedString(self.titleKey, tableName: "general", comment: "")
    }
}

extension QuizIdentifier {
    var shortsCategory: String {
        switch self {
        case .serve: return "serve"
        case .forehand: return "forehand"
        case .backhand: return "backhand"
        case .volley: return "volley"
        case .tactics: return "mental"
        case .legwork: return "legwork"
        }
    }
}

extension QuizDifficulty {
    var localizedAdjective: String {
        NSLocalizedString(self.titleKeyAdjective, tableName: "general", comment: "")
    }
}



struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.26, dampingFraction: 0.85), value: configuration.isPressed)
    }
}




extension View {
    func mirroredHorizontally(_ shouldMirror: Bool) -> some View {
        self.scaleEffect(x: shouldMirror ? -1 : 1, y: 1, anchor: .center)
    }
}

#Preview {
    let mockTopic: QuizIdentifier = .serve

    let mockScores: [LessonQuizID: Int] = [
        LessonQuizID(topic: .serve, difficulty: .easy): 5,
        LessonQuizID(topic: .serve, difficulty: .medium): 2,
        LessonQuizID(topic: .serve, difficulty: .hard): 0,

        LessonQuizID(topic: .tactics, difficulty: .easy): 3,
        LessonQuizID(topic: .tactics, difficulty: .medium): 0,
        LessonQuizID(topic: .tactics, difficulty: .hard): 0
    ]

    return NavigationStack {
        TheoryView()
            .onAppear {
                // Inject mock data by writing to UserDefaults for Preview
                for (id, score) in mockScores {
                    UserDefaults.standard.set(score, forKey: id.userDefaultsKey)
                }
            }
    }
}
