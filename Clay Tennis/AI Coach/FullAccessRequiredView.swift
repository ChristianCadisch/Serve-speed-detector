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
            
            Text(
                NSLocalizedString(
                    "photo_access_required_title",
                    tableName: "general",
                    comment: ""
                )
            )
            .font(.title.bold())
            .padding(.top, 8)

            
            Text(
                NSLocalizedString(
                    "photo_access_required_description",
                    tableName: "general",
                    comment: ""
                )
            )
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)

            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(
                    NSLocalizedString(
                        "photo_access_required_button",
                        tableName: "general",
                        comment: ""
                    )
                )
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
