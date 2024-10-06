//
//  LoginView.swift
//  VisionTrajectoryDemo
//
//  Created by Christian on 06.10.2024.
//  Copyright © 2024 Apple. All rights reserved.
//
import SwiftUI
import FirebaseAuth

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showCreateAccount = false

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .padding()

            // TextField for either Email or Username
            TextField("Email or Username", text: $emailOrUsername)
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
            
            Button(action: {
                showCreateAccount = true
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
        if isValidEmail(emailOrUsername) {
            // Log in using email
            Auth.auth().signIn(withEmail: emailOrUsername, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.isLoggedIn = true
            }
        } else {
            // Log in using username (query Firestore to get the email)
            let db = Firestore.firestore()
            let usersRef = db.collection("users")
            usersRef.whereField("username", isEqualTo: emailOrUsername).getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents, let document = documents.first else {
                    self.errorMessage = "Username not found."
                    return
                }
                
                // Get the email associated with the username
                if let email = document.data()["email"] as? String {
                    // Log in with the email
                    Auth.auth().signIn(withEmail: email, password: self.password) { result, error in
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            return
                        }
                        self.isLoggedIn = true
                    }
                } else {
                    self.errorMessage = "Error retrieving email for username."
                }
            }
        }
    }

    // Helper function to validate if the input is an email
    func isValidEmail(_ input: String) -> Bool {
        // Simple email validation using a regular expression
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: input)
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
