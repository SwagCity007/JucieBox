//
//  UserManager.swift
//  JuiceBox
//
//  User authentication and profile management with iOS 16 features
//

import Foundation
import AuthenticationServices
import PassKit
import Combine

@MainActor
class UserManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var isGuestMode = false
    @Published var authError: AuthError?
    
    private var cancellables = Set<AnyCancellable>()
    
    enum AuthError: LocalizedError {
        case authenticationFailed
        case networkError
        case invalidCredentials
        case passkeyUnavailable
        
        var errorDescription: String? {
            switch self {
            case .authenticationFailed:
                return "Authentication failed"
            case .networkError:
                return "Network connection error"
            case .invalidCredentials:
                return "Invalid credentials"
            case .passkeyUnavailable:
                return "Passkey not available"
            }
        }
    }
    
    init() {
        loadUserData()
        setupPaymentMethods()
    }
    
    // MARK: - Authentication Methods
    
    func authenticate(with assertion: ASAuthorizationPlatformPublicKeyCredentialAssertion) async throws {
        // Simulate server verification
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // In a real app, send assertion.rawRepresentation to your server
        let userID = String(data: assertion.userID, encoding: .utf8) ?? "unknown"
        
        let user = User(
            id: userID,
            email: "\(userID)@example.com",
            name: "Passkey User",
            phoneNumber: "+1-555-0123",
            profileImageURL: nil,
            authMethod: .passkey
        )
        
        currentUser = user
        isAuthenticated = true
        isGuestMode = false
        
        // Save authentication state
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(userID, forKey: "userId")
    }
    
    func authenticate(with authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.authenticationFailed
        }
        
        // Simulate server verification
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email ?? "\(userID)@privaterelay.appleid.com"
        let fullName = appleIDCredential.fullName
        
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let user = User(
            id: userID,
            email: email,
            name: displayName.isEmpty ? "Apple ID User" : displayName,
            phoneNumber: nil,
            profileImageURL: nil,
            authMethod: .appleID
        )
        
        currentUser = user
        isAuthenticated = true
        isGuestMode = false
        
        // Save authentication state
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(userID, forKey: "userId")
    }
    
    func authenticate(with email: String) async throws {
        // Simulate email verification process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let userID = UUID().uuidString
        let user = User(
            id: userID,
            email: email,
            name: "Email User",
            phoneNumber: nil,
            profileImageURL: nil,
            authMethod: .email
        )
        
        currentUser = user
        isAuthenticated = true
        isGuestMode = false
        
        // Save authentication state
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(userID, forKey: "userId")
    }
    
    func setGuestMode(_ enabled: Bool) {
        isGuestMode = enabled
        if enabled {
            currentUser = User(
                id: "guest",
                email: "guest@example.com",
                name: "Guest User",
                phoneNumber: nil,
                profileImageURL: nil,
                authMethod: .guest
            )
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        isGuestMode = false
        
        // Clear saved authentication state
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    // MARK: - Payment Methods
    
    func addPaymentMethod() {
        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("Apple Pay not available")
            return
        }
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.juicebox.pay"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Add a dummy payment item for setup
        let setupItem = PKPaymentSummaryItem(
            label: "Setup Payment Method",
            amount: NSDecimalNumber(decimal: 0.00)
        )
        request.paymentSummaryItems = [setupItem]
        
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller?.delegate = self
        controller?.present()
    }
    
    func removePaymentMethod(_ method: PaymentMethod) {
        paymentMethods.removeAll { $0.id == method.id }
    }
    
    // MARK: - Profile Management
    
    func updateProfile(name: String?, phoneNumber: String?) async {
        guard var user = currentUser else { return }
        
        if let name = name, !name.isEmpty {
            user.name = name
        }
        
        if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            user.phoneNumber = phoneNumber
        }
        
        currentUser = user
        
        // Simulate server update
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    // MARK: - Private Methods
    
    private func loadUserData() {
        if UserDefaults.standard.bool(forKey: "isAuthenticated"),
           let userId = UserDefaults.standard.string(forKey: "userId") {
            
            // Load saved user data
            currentUser = User(
                id: userId,
                email: "user@example.com",
                name: "Saved User",
                phoneNumber: nil,
                profileImageURL: nil,
                authMethod: .passkey
            )
            isAuthenticated = true
        }
    }
    
    private func setupPaymentMethods() {
        // Mock payment methods
        paymentMethods = [
            PaymentMethod(
                id: UUID().uuidString,
                type: .applePay,
                displayName: "Apple Pay",
                isDefault: true
            ),
            PaymentMethod(
                id: UUID().uuidString,
                type: .creditCard,
                displayName: "**** 1234",
                isDefault: false
            )
        ]
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension UserManager: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Process payment token
        // In a real app, send payment.token to your payment processor
        
        // Add new payment method
        let newMethod = PaymentMethod(
            id: UUID().uuidString,
            type: .applePay,
            displayName: "Apple Pay",
            isDefault: paymentMethods.isEmpty
        )
        
        paymentMethods.append(newMethod)
        
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}

// MARK: - User Model

struct User: Identifiable, Codable {
    let id: String
    let email: String
    var name: String
    var phoneNumber: String?
    var profileImageURL: String?
    let authMethod: AuthenticationMethod
    var createdAt: Date = Date()
    
    enum AuthenticationMethod: String, Codable {
        case passkey = "passkey"
        case appleID = "apple_id"
        case email = "email"
        case guest = "guest"
        
        var displayName: String {
            switch self {
            case .passkey: return "Passkey"
            case .appleID: return "Apple ID"
            case .email: return "Email"
            case .guest: return "Guest"
            }
        }
    }
}

// MARK: - Payment Method Model

struct PaymentMethod: Identifiable, Codable {
    let id: String
    let type: PaymentType
    let displayName: String
    var isDefault: Bool
    
    enum PaymentType: String, Codable {
        case applePay = "apple_pay"
        case creditCard = "credit_card"
        case debitCard = "debit_card"
        case digitalWallet = "digital_wallet"
        
        var iconName: String {
            switch self {
            case .applePay: return "apple.logo"
            case .creditCard: return "creditcard.fill"
            case .debitCard: return "creditcard"
            case .digitalWallet: return "wallet.pass.fill"
            }
        }
    }
}