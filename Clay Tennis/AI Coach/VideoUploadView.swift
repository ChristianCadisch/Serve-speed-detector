//
//  VideoUploadView.swift
//  Clay Tennis
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import UniformTypeIdentifiers
import AVFoundation

struct VideoUploadView: View {

    let initialVideoURL: URL?

    @Environment(\.dismiss) private var dismiss

    @State private var localVideoURL: URL?

    @State private var fullName = ""
    @State private var contactInfo = ""
    @State private var focusNotes = ""

    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?

    @State private var showCelebration: Bool = false

    /// Stable ID for this submission (used for Storage + Firestore)
    @State private var submissionId = UUID().uuidString

    private enum FlowStep {
        case info
        case form
    }

    @State private var step: FlowStep = .info

    init(initialVideoURL: URL? = nil) {
        self.initialVideoURL = initialVideoURL
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    switch step {
                    case .info:
                        infoStep
                    case .form:
                        formStep
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 44)
            }
            .navigationTitle(
                NSLocalizedString("video_review_nav_title", tableName: "general", comment: "")
            )
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.25), value: step)
            .onAppear {
                print("👀 [VIEW] onAppear")
                guard localVideoURL == nil else { return }
                guard let initialVideoURL,
                      FileManager.default.fileExists(atPath: initialVideoURL.path),
                      !initialVideoURL.hasDirectoryPath
                else { return }

                print("🎥 [VIDEO] Using initial video URL")
                localVideoURL = initialVideoURL
            }
            .onChange(of: showCelebration) { value in
                print("🎬 [STATE] showCelebration =", value)
            }

            if showCelebration {
                SubmissionCelebrationOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
    }
    
    private func isVideoSizeValid(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize else {
            print("❌ [SIZE] Could not determine video size")
            return false
        }

        let maxSizeBytes = 250 * 1024 * 1024 // 250 MB
        let sizeMB = Double(fileSize) / (1024 * 1024)

        print("📏 [SIZE] Video size: \(String(format: "%.1f", sizeMB)) MB")

        return fileSize <= maxSizeBytes
    }


    // MARK: - Step 1

    private var infoStep: some View {
        VStack(spacing: 28) {

            Text(
                NSLocalizedString("video_review_step1_title", tableName: "general", comment: "")
            )
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                Label(
                    NSLocalizedString("video_review_bullet_licensed", tableName: "general", comment: ""),
                    systemImage: "person.fill.checkmark"
                )
                Label(
                    NSLocalizedString("video_review_bullet_pricing", tableName: "general", comment: ""),
                    systemImage: "tag.fill"
                )
                Label(
                    NSLocalizedString("video_review_bullet_confirmation", tableName: "general", comment: ""),
                    systemImage: "checkmark.circle.fill"
                )
                Label(
                    NSLocalizedString("video_review_bullet_payment_outside", tableName: "general", comment: ""),
                    systemImage: "arrow.up.right.square"
                )
                Label(
                    NSLocalizedString("video_review_bullet_privacy", tableName: "general", comment: ""),
                    systemImage: "lock.fill"
                )
            }
            .foregroundStyle(.secondary)

            Button {
                print("➡️ [FLOW] Proceed to form")
                step = .form
            } label: {
                Text(
                    NSLocalizedString("video_review_proceed", tableName: "general", comment: "")
                )
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal)
    }

    // MARK: - Step 2

    private var formStep: some View {
        VStack(spacing: 28) {

            if let url = localVideoURL {
                videoPreview(url: url)
            }

            formSection

            if isUploading {
                ProgressView(value: uploadProgress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            submitButton
        }
    }

    // MARK: - Video Preview

    private func videoPreview(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                NSLocalizedString("video_review_preview_title", tableName: "general", comment: "")
            )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VideoThumbnailView(videoURL: url)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(.horizontal)
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 18) {
            TextField(
                NSLocalizedString("video_review_full_name_placeholder", tableName: "general", comment: ""),
                text: $fullName
            )
                .textFieldStyle(.roundedBorder)

            TextField(
                NSLocalizedString("video_review_contact_placeholder", tableName: "general", comment: ""),
                text: $contactInfo
            )
                .textFieldStyle(.roundedBorder)

            TextField(
                NSLocalizedString("video_review_focus_placeholder", tableName: "general", comment: ""),
                text: $focusNotes,
                axis: .vertical
            )
            .lineLimit(3...5)
            .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            guard let url = localVideoURL else { return }
            print("⬆️ [UPLOAD] Submit tapped")
            
            guard isVideoSizeValid(url) else {
                    errorMessage = """
                    This video is larger than 250 MB.

                    Tip: Short serve clips (5–8 seconds around contact) upload fastest and work best for coach review.
                    """
                    print("❌ [SIZE] Video too large — upload blocked")
                    return
                }
            
            uploadVideo(at: url)
        } label: {
            Text(
                isUploading
                    ? NSLocalizedString("video_review_submitting", tableName: "general", comment: "")
                    : NSLocalizedString("video_review_submit", tableName: "general", comment: "")
            )
                .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .disabled(isUploading || fullName.isEmpty || contactInfo.isEmpty)
        .padding(.horizontal)
    }

    // MARK: - Google Forms

    private func notifyCoachViaGoogleForm() {
        print("📨 [FORMS] Sending Google Form")

        guard let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeaUDXD_pr1T-3wmLqXidubKfQ7f8Wn9nOP-KVreLGdvy-vBA/formResponse") else {
            print("❌ [FORMS] Invalid URL")
            return
        }

        let body = [
            "entry.1911828782=\(fullName)",
            "entry.883454228=\(contactInfo)",
            "entry.617357663=Video review sent"
        ]
        .joined(separator: "&")
        .data(using: .utf8)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error {
                print("❌ [FORMS] Error:", error.localizedDescription)
            } else {
                print("✅ [FORMS] Submitted")
            }
        }.resume()
    }

    // MARK: - Firestore

    private func createCoachRequest(videoPath: String) async throws {
        print("📄 [FIRESTORE] Creating coach request")
        let db = Firestore.firestore()

        try await db.collection("coachRequests").addDocument(data: [
            "fullName": fullName,
            "contactInfo": contactInfo,
            "focusNotes": focusNotes,
            "videoPath": videoPath,
            "createdAt": Timestamp(date: Date()),
            "status": "submitted"
        ])
    }

    // MARK: - Upload Logic

    private func uploadVideo(at url: URL) {
        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        let storagePath = "coachReviews/\(submissionId).mov"
        let ref = Storage.storage().reference(withPath: storagePath)

        print("📦 [UPLOAD] Starting:", storagePath)

        let uploadTask = ref.putFile(from: url)

        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            uploadProgress = progress.fractionCompleted
            print("📊 [UPLOAD] Progress:", uploadProgress)
        }

        uploadTask.observe(.failure) { snapshot in
            print("❌ [UPLOAD] Failed")
            isUploading = false
            errorMessage = snapshot.error?.localizedDescription
        }

        uploadTask.observe(.success) { _ in
            print("✅ [UPLOAD] Completed")

            Task {
                do {
                    try await createCoachRequest(videoPath: storagePath)
                    notifyCoachViaGoogleForm()

                    await MainActor.run {
                        print("🎉 [UI] Showing celebration")
                        showCelebration = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        print("🚪 [UI] Dismissing view")
                        dismiss()
                    }

                } catch {
                    print("❌ [ERROR] Submission failed:", error.localizedDescription)
                    await MainActor.run {
                        isUploading = false
                        errorMessage = NSLocalizedString(
                            "video_review_submission_failed",
                            tableName: "general",
                            comment: ""
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            if let cgImage = try? generator.copyCGImage(at: .init(seconds: 0.5, preferredTimescale: 600), actualTime: nil) {
                thumbnail = UIImage(cgImage: cgImage)
            }
        }
    }
}

// MARK: - Celebration Overlay

private struct SubmissionCelebrationOverlay: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                Text(
                    NSLocalizedString("video_review_celebration_title", tableName: "general", comment: "")
                )
                    .font(.system(size: 30, weight: .heavy))
                Text(
                    NSLocalizedString("video_review_celebration_subtitle", tableName: "general", comment: "")
                )
            }
            .foregroundStyle(.white)
            .scaleEffect(animate ? 1 : 0.8)
            .opacity(animate ? 1 : 0)
            .onAppear {
                print("✨ [ANIMATION] Celebration started")
                withAnimation(.spring()) {
                    animate = true
                }
            }
        }
    }
}




#Preview {
    NavigationStack {
        VideoUploadView()
    }
}
