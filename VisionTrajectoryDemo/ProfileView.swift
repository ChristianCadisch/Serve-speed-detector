//
//  RootView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 06.10.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import FirebaseAuth
import SwiftUI

struct ProfileView: View {
    @State private var username: String = Auth.auth().currentUser?.email ?? "Guest"
    @State private var isLoggedOut = false
    
    var onLoginSuccess: () -> Void // Add this closure to handle login success
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Username: \(username)")
                .font(.headline)
            
            Button(action: logout) {
                Text("Logout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Spacer() // Push the content up
        }
        .padding()
        .navigationTitle("Profile")
        .fullScreenCover(isPresented: $isLoggedOut, content: {
            // Present LoginView when logged out, pass the onLoginSuccess closure
            LoginView(isLoggedIn: $isLoggedOut, onLoginSuccess: onLoginSuccess)
        })
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true // Navigate to login after logout
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
