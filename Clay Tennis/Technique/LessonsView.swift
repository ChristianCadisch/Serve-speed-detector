//
//  LessonsView.swift
//  Clay Tennis
//
//  Focused Lessons Browser
//  Distinct layouts for Quick Tips vs Deep Lessons
//

import SwiftUI

struct LessonsView: View {

    let topic: QuizIdentifier
    let videos: [TrainingVideo]
    @State private var selectedVideo: TrainingVideo?


    @State private var mode: LessonMode = .longs

    private let accentGreen = Color.green

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                
                modeToggle

                ScrollView {

                    LessonsProgressCard(
                        title: progressTitle,
                        completed: completedCount,
                        total: totalCount
                    )
                    .padding(.top, 4)

                    switch mode {
                    case .shorts:
                        quickTipsGrid
                    case .longs:
                        deepLessonsList
                    }
                }

            }
            .navigationTitle(
                NSLocalizedString("lessons_title", tableName: "general", comment: "")
            )
            .navigationBarTitleDisplayMode(.large)
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
                        subtitle: String(
                            format: NSLocalizedString("short_tip_subtitle", tableName: "general", comment: ""),
                            video.duration
                        )

                    )
                    .navigationTitle(video.title)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }


    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("Mode", selection: $mode) {
            ForEach(LessonMode.allCases, id: \.self) {
                Text($0.title)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Quick Tips (Grid)

    private var quickTipsGrid: some View {
        let shorts = filteredVideos
            .filter { $0.filetype == "shorts" }
            .sorted { lhs, rhs in
                lhs.isCompleted == false && rhs.isCompleted == true
            }

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 16
        ) {
            ForEach(shorts) { video in
                Button {
                    selectedVideo = video
                } label: {
                    QuickTipCard(video: video)
                }
                .buttonStyle(.plain)
            }

        }
        .padding()
    }

    // MARK: - Deep Lessons (List)

    private var deepLessonsList: some View {
        let longs = filteredVideos
            .filter { $0.filetype == "long" }
            .sorted { lhs, rhs in
                lhs.isCompleted == false && rhs.isCompleted == true
            }

        return LazyVStack(spacing: 20) {
            ForEach(longs) { video in
                Button {
                    selectedVideo = video
                } label: {
                    DeepLessonCard(video: video)
                }
                .buttonStyle(.plain)
            }

        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var progressVideos: [TrainingVideo] {
        filteredVideos.filter {
            mode == .longs ? $0.filetype == "long" : $0.filetype == "shorts"
        }
    }

    private var completedCount: Int {
        progressVideos.filter { $0.isCompleted }.count
    }

    private var totalCount: Int {
        progressVideos.count
    }

    private var progressTitle: String {
        mode == .longs
        ? NSLocalizedString("progress_deep_lessons", tableName: "general", comment: "")
        : NSLocalizedString("progress_quick_tips", tableName: "general", comment: "")
    }




    // MARK: - Filtering

    private var filteredVideos: [TrainingVideo] {
        videos.filter { $0.category == topic.shortsCategory }
    }
}

// MARK: - Lesson Mode

enum LessonMode: CaseIterable {
    case longs
    case shorts

    var title: String {
        switch self {
        case .shorts:
            return NSLocalizedString("lesson_mode_quick_tips", tableName: "general", comment: "")
        case .longs:
            return NSLocalizedString("lesson_mode_deep_lessons", tableName: "general", comment: "")
        }
    }
}


// MARK: - Quick Tip Card

fileprivate struct QuickTipCard: View {
    let video: TrainingVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            ZStack {
                AsyncImage(url: video.thumbnailURL) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .saturation(video.isCompleted ? 0.1 : 1.0)
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(height: 140)
                .clipped()
                .cornerRadius(14)


                if video.isCompleted {
                    CompletedOverlay()
                        .cornerRadius(14)
                }
            }

            Text(video.title)
                .font(.body.weight(.semibold))
                .lineLimit(2)

            Text(video.durationText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Deep Lesson Row

fileprivate struct DeepLessonCard: View {

    let video: TrainingVideo
    private let accentGreen = Color.green

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Thumbnail (Hero)
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: video.thumbnailURL) { phase in
                        if case let .success(image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .saturation(video.isCompleted ? 0.1 : 1.0)
                        } else {
                            Color(.systemGray5)
                        }
                    }
                    .frame(height: 180)
                    .clipped()


                    // Editorial fade
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.15),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 100)

                    if video.isCompleted {
                        CompletedOverlay()
                    }
                }


                // MARK: - Progress Bar (Commitment Signal)
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(accentGreen)
                    .frame(height: 4)
                    .background(Color(.systemGray4))
            }


            // MARK: - Metadata
            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 6) {
                    Image(systemName: "graduationcap.fill")
                        .font(.caption2)
                        .foregroundStyle(accentGreen)

                    Text(
                        String(
                            format: NSLocalizedString("coach_lesson_label", tableName: "general", comment: ""),
                            video.durationText
                        )
                    )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accentGreen)
                }

                Text(video.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let points = video.learningPoints {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(points.prefix(2), id: \.self) { point in
                            Text("• \(point)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var progress: Double {
        LongLessonProgressStore.shared.progress(for: video.id)
    }

}

fileprivate struct CompletedOverlay: View {

    private let accentGreen = Color.green

    var body: some View {
        ZStack {
            // Soft dim
            Color.black.opacity(0.22)

            VStack {
                HStack {
                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))

                        Text(
                            NSLocalizedString("completed_badge", tableName: "general", comment: "")
                        )
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentGreen)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    .padding(10)
                }

                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
}


fileprivate struct LessonsProgressCard: View {

    let title: String
    let completed: Int
    let total: Int

    private let gradient = LinearGradient(
        colors: [Color.green, Color.mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @State private var animatedProgress: Double = 0

    private var targetProgress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var motivationalLine: String {
        guard total > 0 else {
            return NSLocalizedString("motivation_start", tableName: "general", comment: "")
        }

        if completed >= total {
            return NSLocalizedString("motivation_all_done", tableName: "general", comment: "")
        }


        // Few-lesson tracks (≤ 10)
        if total <= 10 {
            switch completed {
            case 0:
                return NSLocalizedString("motivation_few_0", tableName: "general", comment: "")
            case 1:
                return NSLocalizedString("motivation_few_1", tableName: "general", comment: "")
            case 2:
                return NSLocalizedString("motivation_few_2", tableName: "general", comment: "")
            case 3:
                return NSLocalizedString("motivation_few_3", tableName: "general", comment: "")
            case 4:
                return NSLocalizedString("motivation_few_4", tableName: "general", comment: "")
            case 5:
                return NSLocalizedString("motivation_few_5", tableName: "general", comment: "")
            case 6:
                return NSLocalizedString("motivation_few_6", tableName: "general", comment: "")
            case 7:
                return NSLocalizedString("motivation_few_7", tableName: "general", comment: "")
            case 8:
                return NSLocalizedString("motivation_few_8", tableName: "general", comment: "")
            default:
                return NSLocalizedString("motivation_few_almost", tableName: "general", comment: "")
            }
        }

        // Longer tracks (> 10)
        let progress = Double(completed) / Double(total)

        switch progress {
        case ..<0.1:
            return NSLocalizedString("motivation_long_start", tableName: "general", comment: "")
        case ..<0.25:
            return NSLocalizedString("motivation_long_early", tableName: "general", comment: "")
        case ..<0.5:
            return NSLocalizedString("motivation_long_mid", tableName: "general", comment: "")
        case ..<0.75:
            return NSLocalizedString("motivation_long_late", tableName: "general", comment: "")
        case ..<0.95:
            return NSLocalizedString("motivation_long_finish", tableName: "general", comment: "")
        default:
            return NSLocalizedString("motivation_long_almost", tableName: "general", comment: "")
        }

    }


    var body: some View {
        HStack(spacing: 16) {

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        gradient,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8),
                        value: animatedProgress
                    )
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(
                    String(
                        format: NSLocalizedString("progress_count", tableName: "general", comment: ""),
                        completed,
                        total
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(motivationalLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.green.opacity(0.85))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
        .onAppear {
            animatedProgress = targetProgress
        }
        .onChange(of: targetProgress) { _, newValue in
            animatedProgress = newValue
        }
    }
}



// MARK: - Preview

#Preview {
    let url = Bundle.main.url(forResource: "videos", withExtension: "json")!
    let data = try! Data(contentsOf: url)
    let videos = try! JSONDecoder().decode([TrainingVideo].self, from: data)

    return NavigationStack {
        LessonsView(
            topic: .serve,
            videos: videos
        )
    }
}
