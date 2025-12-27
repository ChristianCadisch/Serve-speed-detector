//
//  FindCoach.swift
//  Clay Tennis
//
//  Premium entry point to connect users with a real tennis coach
//

import SwiftUI
import UIKit

struct FindCoach: View {

    // MARK: - Required
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var location: String = ""
    @State private var price: Double = 90
    @State private var selectedLevel: PlayerLevel? = nil

    @State private var didSubmit: Bool = false
    @State private var showCelebration: Bool = false
    @State private var errorMessage: String? = nil


    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }

        let ns = trimmed as NSString
        let fullRange = NSRange(location: 0, length: ns.length)

        guard let match = detector.firstMatch(in: trimmed, options: [], range: fullRange) else {
            return false
        }

        // Must match the entire string
        guard match.range.location == 0, match.range.length == fullRange.length else {
            return false
        }

        // Must be a mailto: link
        return match.url?.scheme == "mailto"
    }


    

    var body: some View {
        ZStack {

            ScrollView {
                VStack(spacing: 32) {

                    header

                    VStack(spacing: 28) {
                        requiredSection
                        budgetSection
                        levelSection
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }

                        submitButton
                    }

                    Spacer(minLength: 24)
                }
                .padding()
            }

            if showCelebration {
                CelebrationOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("find_coach_header_caps", tableName: "general", comment: ""))
                .font(.caption.bold())
                .tracking(1.4)
                .foregroundStyle(.secondary)

            Text(NSLocalizedString("find_coach_header_title", tableName: "general", comment: ""))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Required Info

    private var requiredSection: some View {
        VStack(alignment: .leading, spacing: 18) {

            sectionTitle(NSLocalizedString("find_coach_section_details", tableName: "general", comment: ""))

            inputField(
                title: NSLocalizedString("find_coach_name_title", tableName: "general", comment: ""),
                placeholder: NSLocalizedString("find_coach_name_placeholder", tableName: "general", comment: ""),
                text: $name
            )

            inputField(
                title: NSLocalizedString("find_coach_email_title", tableName: "general", comment: ""),
                placeholder: NSLocalizedString("find_coach_email_placeholder", tableName: "general", comment: ""),
                text: $email,
                keyboard: .emailAddress
            )


            inputField(
                title: NSLocalizedString("find_coach_location_title", tableName: "general", comment: ""),
                placeholder: NSLocalizedString("find_coach_location_placeholder", tableName: "general", comment: ""),
                text: $location
            )

        }
    }

    // MARK: - Budget

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            sectionTitle(NSLocalizedString("find_coach_budget_title", tableName: "general", comment: ""))

            VStack(alignment: .leading, spacing: 12) {
                Slider(value: $price, in: 60...150, step: 5)

                HStack {
                    Text("CHF 60")
                    Spacer()
                    Text("CHF \(Int(price))")
                        .font(.headline)
                    Spacer()
                    Text("CHF 150")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Player Level

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            sectionTitle(NSLocalizedString("find_coach_level_title", tableName: "general", comment: ""))

            HStack(spacing: 12) {
                levelButton(.beginner)
                levelButton(.intermediate)
                levelButton(.advanced)
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            errorMessage = nil

            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = NSLocalizedString("find_coach_error_name", tableName: "general", comment: "")
                return
            }

            guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = NSLocalizedString("find_coach_error_email", tableName: "general", comment: "")
                return
            }

            guard isValidEmail(email) else {
                errorMessage = NSLocalizedString("find_coach_error_email_invalid", tableName: "general", comment: "")
                return
            }

            guard !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = NSLocalizedString("find_coach_error_location", tableName: "general", comment: "")
                return
            }

            CoachRequestService.submit(
                name: name,
                email: email,
                location: location,
                price: Int(price),
                level: selectedLevel?.rawValue
            )

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            withAnimation(.easeOut(duration: 0.3)) {
                didSubmit = true
                showCelebration = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation {
                    showCelebration = false
                }
            }

        } label: {

            Text(
                didSubmit
                    ? NSLocalizedString("find_coach_submit_done", tableName: "general", comment: "")
                    : NSLocalizedString("find_coach_submit", tableName: "general", comment: "")
            )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(didSubmit ? Color.gray : Color.accentColor)
                )
                .foregroundStyle(.white)
        }
        .disabled(didSubmit)
        .padding(.top, 8)
    }

    // MARK: - Components

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.bold())
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }

    private func inputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }

    private func levelButton(_ level: PlayerLevel) -> some View {
        Button {
            selectedLevel = level
        } label: {
            Text(level.title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selectedLevel == level
                              ? Color.accentColor.opacity(0.2)
                              : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Celebration Overlay
private struct CelebrationOverlay: View {

    private struct Ball: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let size: CGFloat
    }

    private let balls: [Ball] = (0..<10).map { _ in
        Ball(
            x: CGFloat.random(in: -160...160),
            delay: Double.random(in: 0.0...0.4),
            duration: Double.random(in: 1.4...2.0),
            size: CGFloat.random(in: 18...26)
        )
    }

    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            // 🎾 Tennis balls
            ForEach(balls) { ball in
                Image(systemName: "tennisball.fill")
                    .font(.system(size: ball.size))
                    .foregroundStyle(.yellow)
                    .offset(
                        x: ball.x,
                        y: animate ? -420 : 420
                    )
                    .rotationEffect(.degrees(animate ? 180 : 0))
                    .opacity(animate ? 0.9 : 0)
                    .animation(
                        .easeOut(duration: ball.duration)
                            .delay(ball.delay),
                        value: animate
                    )
            }

            // ✅ Success text
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1 : 0.6)
                    .opacity(animate ? 1 : 0)

                Text(NSLocalizedString("find_coach_submit_done", tableName: "general", comment: ""))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1 : 0.9)
                    .opacity(animate ? 1 : 0)
            }
            .animation(
                .spring(response: 0.55, dampingFraction: 0.7),
                value: animate
            )
        }
        .onAppear {
            animate = true
        }
    }
}


// MARK: - Player Level

enum PlayerLevel: String {
    case beginner
    case intermediate
    case advanced

    var title: String {
        switch self {
        case .beginner:
            return NSLocalizedString("find_coach_level_beginner", tableName: "general", comment: "")
        case .intermediate:
            return NSLocalizedString("find_coach_level_intermediate", tableName: "general", comment: "")
        case .advanced:
            return NSLocalizedString("find_coach_level_advanced", tableName: "general", comment: "")
        }
    }
}


#Preview {
    NavigationStack {
        FindCoach()
    }
}




enum CoachRequestService {

    // MARK: - New Google Form endpoint
    private static let formURL =
        URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeaUDXD_pr1T-3wmLqXidubKfQ7f8Wn9nOP-KVreLGdvy-vBA/formResponse")!

    // MARK: - Google Form Field IDs (confirmed)
    private static let nameFieldKey     = "entry.1911828782"
    private static let emailFieldKey    = "entry.883454228"
    private static let locationFieldKey = "entry.617357663"
    private static let priceFieldKey    = "entry.1360663907"
    private static let levelFieldKey    = "entry.44000714"

    static func submit(
        name: String,
        email: String,
        location: String,
        price: Int,
        level: String?
    ) {
        var request = URLRequest(url: formURL)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }

        var components: [String] = [
            "\(nameFieldKey)=\(encode(name))",
            "\(emailFieldKey)=\(encode(email))",
            "\(locationFieldKey)=\(encode(location))",
            "\(priceFieldKey)=\(price)"
        ]

        if let level, !level.isEmpty {
            components.append("\(levelFieldKey)=\(encode(level))")
        }

        request.httpBody = components
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request).resume()
    }
}



#Preview {
    NavigationStack {
        FindCoach()
    }
}


