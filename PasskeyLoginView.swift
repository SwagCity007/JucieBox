//
//  PasskeyLoginView.swift
//  JuiceBox
//
//  Enhanced passkey authentication with iOS 16 features
//  Supports Sign in with Apple, Passkeys, and seamless onboarding
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct PasskeyLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var userID: String = ""
    @State private var showEmailField = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var authenticationPhase: AuthenticationPhase = .initial
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.1),
                        Color.red.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 60)
                        
                        // MARK: - Logo & Branding
                        logoSection
                        
                        // MARK: - Authentication Content
                        authenticationContent
                        
                        // MARK: - Alternative Options
                        alternativeOptionsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        // Allow limited access without authentication
                        userManager.setGuestMode(true)
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .interactiveDismissDisabled(authenticationPhase == .authenticating)
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 20) {
            // Enhanced logo with liquid glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("JuiceBox")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Your ride, supercharged.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Authentication Content
    
    @ViewBuilder
    private var authenticationContent: some View {
        VStack(spacing: 24) {
            switch authenticationPhase {
            case .initial:
                initialAuthenticationView
            case .authenticating:
                authenticatingView
            case .success:
                successView
            case .error:
                errorView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authenticationPhase)
    }
    
    private var initialAuthenticationView: some View {
        VStack(spacing: 20) {
            // MARK: - Passkey Button
            if #available(iOS 16.4, *) {
                SignInWithPasskeyButton(action: performPasskeySignIn)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            } else {
                Button {
                    performPasskeySignIn()
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Continue with Passkey")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
            
            // MARK: - Sign in with Apple
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: handleSignInWithApple
            )
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // MARK: - Email Field (if shown)
            if showEmailField {
                emailAuthenticationSection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    private var emailAuthenticationSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                TextField("Email address", text: $userID)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Button {
                    performEmailSignIn()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Continue with Email")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(userID.isEmpty || isLoading)
            }
        }
    }
    
    private var authenticatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Authenticating...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Welcome aboard!")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("You're all set to start your journey.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Authentication Failed")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                authenticationPhase = .initial
                showingError = false
                errorMessage = ""
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    // MARK: - Alternative Options
    
    private var alternativeOptionsSection: some View {
        VStack(spacing: 16) {
            // Divider with text
            HStack {
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Toggle email option
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showEmailField.toggle()
                }
            } label: {
                Text(showEmailField ? "Use Passkey instead" : "Use email address")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            
            // Privacy & Security Info
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Secure & Private")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                
                Text("Your biometric data never leaves your device. We use industry-standard encryption to protect your information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Authentication Methods

extension PasskeyLoginView {
    private func performPasskeySignIn() {
        authenticationPhase = .authenticating
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: "juicebox.app"
        )
        
        let request = provider.createCredentialAssertionRequest(
            challenge: generateChallenge()
        )
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = PasskeyDelegate { result in
            DispatchQueue.main.async {
                handlePasskeyResult(result)
            }
        }
        
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
    
    private func handlePasskeyResult(
        _ result: Result<ASAuthorizationPlatformPublicKeyCredentialAssertion, Error>
    ) {
        switch result {
        case .success(let assertion):
            Task {
                do {
                    await userManager.authenticate(with: assertion)
                    authenticationPhase = .success
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } catch {
                    authenticationPhase = .error
                    errorMessage = "Failed to complete authentication"
                }
            }
            
        case .failure(let error):
            authenticationPhase = .error
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            authenticationPhase = .authenticating
            
            Task {
                do {
                    await userManager.authenticate(with: authorization)
                    authenticationPhase = .success
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } catch {
                    authenticationPhase = .error
                    errorMessage = "Failed to sign in with Apple"
                }
            }
            
        case .failure(let error):
            authenticationPhase = .error
            errorMessage = error.localizedDescription
        }
    }
    
    private func performEmailSignIn() {
        guard !userID.isEmpty else { return }
        
        isLoading = true
        authenticationPhase = .authenticating
        
        Task {
            do {
                await userManager.authenticate(with: userID)
                authenticationPhase = .success
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } catch {
                authenticationPhase = .error
                errorMessage = "Failed to send verification email"
            }
            
            isLoading = false
        }
    }
    
    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}

// MARK: - Authentication Phase

enum AuthenticationPhase {
    case initial
    case authenticating
    case success
    case error
}

// MARK: - Enhanced Passkey Delegate

private class PasskeyDelegate: NSObject,
                              ASAuthorizationControllerDelegate,
                              ASAuthorizationControllerPresentationContextProviding {
    
    private let completion: (Result<ASAuthorizationPlatformPublicKeyCredentialAssertion, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationPlatformPublicKeyCredentialAssertion, Error>) -> Void) {
        self.completion = completion
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
    
    func authorizationController(
        _ controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            completion(.success(assertion))
        } else {
            completion(.failure(ASAuthorizationError(.unknown)))
        }
    }
    
    func authorizationController(
        _ controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        completion(.failure(error))
    }
}

// MARK: - Native Sign In With Passkey Button

@available(iOS 16.4, *)
struct SignInWithPasskeyButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationPlatformPublicKeyCredentialButton {
        let button = ASAuthorizationPlatformPublicKeyCredentialButton(
            type: .signIn,
            style: .automatic
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.buttonPressed),
            for: .touchUpInside
        )
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationPlatformPublicKeyCredentialButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonPressed() {
            action()
        }
    }
}

#Preview {
    PasskeyLoginView()
        .environmentObject(UserManager())
}