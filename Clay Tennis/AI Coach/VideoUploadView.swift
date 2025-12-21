//
//  VideoUploadView.swift
//  Clay Tennis
//
//  Two-step coach review flow:
//  1) Information & trust-building
//  2) Submission form + video
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import UniformTypeIdentifiers
import FirebaseAuth
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

    private enum FlowStep {
        case info
        case form
    }

    @State private var step: FlowStep = .info

    init(initialVideoURL: URL? = nil) {
        self.initialVideoURL = initialVideoURL
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                switch step {
                case .info:
                    infoStep
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                case .form:
                    formStep
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 44)
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: step)
        .onAppear {
            guard localVideoURL == nil else { return }
            guard let initialVideoURL,
                  FileManager.default.fileExists(atPath: initialVideoURL.path),
                  !initialVideoURL.hasDirectoryPath
            else { return }

            localVideoURL = initialVideoURL
        }
    }

    // MARK: - Step 1: Info

    private var infoStep: some View {
        VStack(spacing: 28) {

            Text("Human Coach Review")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {

                Label {
                    Text("Your serve is assigned to a licensed tennis coach. You’ll see their profile before confirming.")
                } icon: {
                    Image(systemName: "person.fill.checkmark")
                }

                Label {
                    Text("You receive clear pricing before anything is charged.")
                } icon: {
                    Image(systemName: "tag.fill")
                }

                Label {
                    Text("Nothing happens unless you explicitly confirm.")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }

                Label {
                    Text("Payment and feedback delivery happen outside the app.")
                } icon: {
                    Image(systemName: "arrow.up.right.square")
                }

                Label {
                    Text("Your video is shared only with your assigned coach.")
                } icon: {
                    Image(systemName: "lock.fill")
                }
            }
            .font(.body)
            .foregroundStyle(.secondary)

            Button {
                step = .form
            } label: {
                Text("Proceed")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        LinearGradient(
                            colors: [.orange, Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .orange.opacity(0.3), radius: 14, y: 8)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Step 2: Form

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
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            submitButton
        }
    }


    // MARK: - Video Preview

    private func videoPreview(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Video to be reviewed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VideoThumbnailView(videoURL: url)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 18) {

            TextField("Your full name", text: $fullName)
                .textContentType(.name)
                .textFieldStyle(.roundedBorder)

            TextField("Email or phone number", text: $contactInfo)
                .textContentType(.emailAddress)
                .textFieldStyle(.roundedBorder)

            TextField(
                "What should the coach focus on? (optional)",
                text: $focusNotes,
                axis: .vertical
            )
            .lineLimit(3...5)
            .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }


    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            guard let url = localVideoURL else { return }
            uploadVideo(at: url)
        } label: {
            HStack {
                Spacer()
                Text(isUploading ? "Submitting…" : "Submit for Coach Review")
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: [.orange, Color.orange.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .orange.opacity(0.3), radius: 14, y: 8)
        }
        .disabled(isUploading || fullName.isEmpty || contactInfo.isEmpty)
        .padding(.horizontal)
    }

    // MARK: - Upload Logic

    private func uploadVideo(at url: URL) {
        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        // keep your existing Firebase upload logic here
    }
}

// MARK: - Video Thumbnail

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
                Color(.secondarySystemBackground)
                ProgressView()
            }
        }
        .clipped()
        .onAppear {
            generateThumbnailIfNeeded()
        }
    }

    private func generateThumbnailIfNeeded() {
        guard thumbnail == nil else { return }

        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 800)

        let time = CMTime(seconds: 0.5, preferredTimescale: 600)

        DispatchQueue.global(qos: .userInitiated).async {
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self.thumbnail = uiImage
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
