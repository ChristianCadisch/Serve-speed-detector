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
                    switch mode {
                    case .shorts:
                        quickTipsGrid
                    case .longs:
                        deepLessonsList
                    }
                }
            }
            .navigationTitle("Lessons")
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
                        subtitle: "\(video.duration)-second technique tip"
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
        case .shorts: return "Quick Tips"
        case .longs: return "Deep Lessons"
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

                    Text("Coach lesson · \(video.durationText)")
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

                        Text("Completed")
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
