//
//  FullAccessRequiredView.swift
//  Clay Tennis
//
//  Created by Christian on 10.12.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import PhotosUI

struct FullAccessRequiredView: View {
    
    var body: some View {
        VStack(spacing: 24) {
            
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
            
            Text("Full Photo Access Needed")
                .font(.title.bold())
                .padding(.top, 8)
            
            Text(
                """
                Clay processes all videos locally on your device.
                To correctly analyze the, we need access to the original video files.
                
                These videos never leave your device and are never uploaded.
                """
            )
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Grant Full Photo Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
}
