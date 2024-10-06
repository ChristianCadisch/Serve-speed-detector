//
//  LoginView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 06.10.2024.
//  Copyright © 2024 Apple. All rights reserved.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showCreateAccount = false // To track if user wants to create an account

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .padding()

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }
            
            Button(action: {
                login()
            }) {
                Text("Login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10.0)
            }
            .padding(.bottom, 10)
            
            // Create Account Button
            Button(action: {
                showCreateAccount = true // Navigate to CreateAccountView
            }) {
                Text("Create Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10.0)
            }
        }
        .padding()
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(isLoggedIn: $isLoggedIn)
        }
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.isLoggedIn = true
        }
    }
}

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateAccountView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = "" // Email is now editable
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            Text("Create Account")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $username)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Email", text: $email) // Now the email is editable
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }
            
            Button(action: {
                createAccount()
            }) {
                Text("Create Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10.0)
            }
        }
        .padding()
    }

    func createAccount() {
        // Check if passwords match
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match."
            return
        }
        
        // Check if username is provided
        guard !username.isEmpty else {
            self.errorMessage = "Please enter a username."
            return
        }

        // Create a new user account
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            // Account created successfully, now add username to Firestore
            guard let user = result?.user else { return }
            
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "username": username,
                "email": email
            ]) { error in
                if let error = error {
                    print("Error adding username to Firestore: \(error)")
                } else {
                    print("Username added to Firestore successfully")
                }
            }
            
            // Log the user in and dismiss the view
            self.isLoggedIn = true
        }
    }
}
