//
//  VideoUploadView.swift
//  Clay Tennis
//
//  Video selection + Firebase Storage upload
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import UniformTypeIdentifiers
import FirebaseAuth

struct VideoUploadView: View {
    
    let initialVideoURL: URL?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var localVideoURL: URL?
    
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?
    
    init(initialVideoURL: URL? = nil) {
        self.initialVideoURL = initialVideoURL
    }
    
    
    var body: some View {
        VStack(spacing: 24) {
            
            header
            
            if let url = localVideoURL {
                selectedVideoCard(url: url)
            } else {
                pickerButton
            }
            
            if isUploading {
                ProgressView(value: uploadProgress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal, 32)
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Upload Video")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            loadVideo(from: newItem)
        }
        .onAppear {
            guard localVideoURL == nil else { return }
            
            guard let initialVideoURL else {
                print("ℹ️ [UPLOAD] No initialVideoURL provided → showing picker")
                return
            }
            
            let exists = FileManager.default.fileExists(atPath: initialVideoURL.path)
            print("🎥 [UPLOAD] initialVideoURL:", initialVideoURL.absoluteString, "| exists:", exists)
            
            guard exists, !initialVideoURL.hasDirectoryPath else {
                self.errorMessage = "Could not find the video file for this session. Please choose a video."
                return
            }
            
            self.localVideoURL = initialVideoURL
            print("✅ [UPLOAD] Preloaded:", initialVideoURL.lastPathComponent)
        }
        
        
        
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("Upload a New Video")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            
            Text("Select a serve video to upload securely")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Picker Button
    
    private var pickerButton: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .videos,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 14) {
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 42))
                Text("Choose Video")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Selected Video Card
    
    private func selectedVideoCard(url: URL) -> some View {
        VStack(spacing: 16) {
            
            HStack {
                Image(systemName: "film.fill")
                Text(url.lastPathComponent)
                    .lineLimit(1)
                Spacer()
            }
            .font(.subheadline.weight(.semibold))
            
            Button {
                uploadVideo(at: url)
            } label: {
                HStack {
                    Spacer()
                    Text(isUploading ? "Uploading…" : "Upload to Cloud")
                        .font(.headline.weight(.semibold))
                    Spacer()
                }
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(isUploading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Load & Stage Video
    
    private func loadVideo(from item: PhotosPickerItem) {
        errorMessage = nil
        
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        self.errorMessage = "Could not read the selected video."
                    }
                    return
                }
                
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = docs.appendingPathComponent("upload_\(UUID().uuidString).mov")
                
                try data.write(to: destinationURL, options: [.atomic])
                
                await MainActor.run {
                    print("📦 [UPLOAD] Video staged at:", destinationURL.lastPathComponent)
                    self.localVideoURL = destinationURL
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    
    // MARK: - Firebase Upload
    private func uploadVideo(at url: URL) {
        
        guard !url.hasDirectoryPath else {
            isUploading = false
            errorMessage = "Invalid video file. Please select a valid video."
            print("❌ [UPLOAD] Attempted to upload a directory:", url)
            return
        }
        
        isUploading = true
        uploadProgress = 0
        errorMessage = nil
        
        guard let uid = Auth.auth().currentUser?.uid else {
            isUploading = false
            errorMessage = "User not authenticated."
            return
        }
        
        let filename = url.lastPathComponent
        
        let ref = Storage.storage()
            .reference()
            .child("users")
            .child(uid)
            .child("videos")
            .child(filename)
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        let task = ref.putFile(from: url, metadata: metadata)
        
        task.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                uploadProgress = progress.fractionCompleted
            }
        }
        
        task.observe(.success) { _ in
            print("✅ [UPLOAD] Completed:", ref.fullPath)
            DispatchQueue.main.async {
                isUploading = false
                dismiss()
            }
        }
        
        task.observe(.failure) { snapshot in
            DispatchQueue.main.async {
                isUploading = false
                errorMessage = snapshot.error?.localizedDescription
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        VideoUploadView()
    }
}
