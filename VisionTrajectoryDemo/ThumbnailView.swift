//
//  ThumbnailView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 16.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation



struct ThumbnailView: View {
    let videoURL: URL
    let fastestSpeed: Double
    @State private var thumbnail: UIImage?
    @State private var profileImage: UIImage?
    let username: String
    let rank: Int
    @State private var showingOptions = false
    var onDelete: () -> Void
    var onThumbnailTap: () -> Void
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var comments: [String] = []
    @State private var newComment: String = ""
    @State private var isCommentingEnabled = false
    @State private var isSharePresented = false
    
    let shareLink = "https://github.com/ChristianCadisch"
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(uiImage: profileImage ?? UIImage(systemName: "person.circle.fill")!)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(username)
                            .font(.headline)
                        Text("EVGR Tennis Courts")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        print("Ellipsis button tapped")
                        showingOptions = true
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
                
                
                // Speed and Rank
                HStack {
                    Text("Speed")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(Int(fastestSpeed)) km/h")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Rank")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(rank)th")
                        .font(.headline)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Video Thumbnail
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .onTapGesture(count: 2) {
                                            likePost()
                                        }
                    .onTapGesture {
                        onThumbnailTap()
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .onTapGesture(count: 2) {
                                            likePost()
                                        }
                    .onTapGesture {
                        onThumbnailTap()
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Action Buttons
                HStack {
                    Button(action: {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                    }
                    Button(action: {
                        isCommentingEnabled.toggle()
                    }) {
                        Image(systemName: "message")
                            .foregroundColor(.primary)
                    }
                    Button(action: {
                        isSharePresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                
                if likeCount > 0 {
                                    Text("\(likeCount) like\(likeCount == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                
                Text("19 hours ago")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Comments Section
                if !comments.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(comments, id: \.self) { comment in
                            Text(comment)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if isCommentingEnabled {
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addComment) {
                            Text("Post")
                                .foregroundColor(.blue)
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .onAppear(perform: loadThumbnail)

        .confirmationDialog("Options", isPresented: $showingOptions) {
            Button("Delete", role: .destructive, action: onDelete)
        }
        .actionSheet(isPresented: $isSharePresented) {
                    ActionSheet(
                        title: Text("Share"),
                        message: Text("Share this post: \(shareLink)"),
                        buttons: [
                            .default(Text("Copy Link")) {
                                UIPasteboard.general.string = shareLink
                            },
                            .cancel()
                        ]
                    )
                }
    }
    
    private func likePost() {
            if !isLiked {
                isLiked = true
                likeCount += 1
            }
        }
    
    private func addComment() {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            comments.append(trimmedComment)
            newComment = ""
        }
    }
    
    private func loadThumbnail() {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        profileImage = UIImage(systemName: "person.circle.fill")
    }
    
   
}
