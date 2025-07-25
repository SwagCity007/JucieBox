//
//  AccountView.swift
//  JuiceBox
//
//  User account and profile management with iOS 16 design
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingEditProfile = false
    @State private var showingPaymentMethods = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                profileSection
                
                // MARK: - Payment Section
                paymentSection
                
                // MARK: - Preferences Section
                preferencesSection
                
                // MARK: - Support Section
                supportSection
                
                // MARK: - Sign Out Section
                signOutSection
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingPaymentMethods) {
                PaymentMethodsView()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack {
                // Profile Image
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        if let user = userManager.currentUser {
                            Text(String(user.name.prefix(1)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let user = userManager.currentUser {
                        Text(user.name)
                            .font(.headline)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text("Verified with \(user.authMethod.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    showingEditProfile = true
                } label: {
                    Text("Edit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Payment Section
    
    private var paymentSection: some View {
        Section("Payment") {
            ForEach(userManager.paymentMethods) { method in
                HStack {
                    Image(systemName: method.type.iconName)
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(method.displayName)
                            .font(.subheadline)
                        
                        if method.isDefault {
                            Text("Default")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Button {
                userManager.addPaymentMethod()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("Add Payment Method")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink(destination: NotificationSettingsView()) {
                Label("Notifications", systemImage: "bell")
            }
            
            NavigationLink(destination: PrivacySettingsView()) {
                Label("Privacy & Safety", systemImage: "lock.shield")
            }
            
            NavigationLink(destination: AccessibilitySettingsView()) {
                Label("Accessibility", systemImage: "accessibility")
            }
            
            NavigationLink(destination: RidePreferencesView()) {
                Label("Ride Preferences", systemImage: "car")
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section("Support") {
            NavigationLink(destination: HelpCenterView()) {
                Label("Help Center", systemImage: "questionmark.circle")
            }
            
            NavigationLink(destination: ContactSupportView()) {
                Label("Contact Support", systemImage: "headphones")
            }
            
            Link(destination: URL(string: "https://juicebox.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            
            Link(destination: URL(string: "https://juicebox.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
        }
    }
    
    // MARK: - Sign Out Section
    
    private var signOutSection: some View {
        Section {
            Button("Sign Out") {
                userManager.signOut()
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if let user = userManager.currentUser {
                    name = user.name
                    phoneNumber = user.phoneNumber ?? ""
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            await userManager.updateProfile(
                name: name.isEmpty ? nil : name,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}

// MARK: - Payment Methods View

struct PaymentMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(userManager.paymentMethods) { method in
                    HStack {
                        Image(systemName: method.type.iconName)
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(method.displayName)
                                .font(.subheadline)
                            
                            if method.isDefault {
                                Text("Default")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Remove") {
                            userManager.removePaymentMethod(method)
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                
                Button {
                    userManager.addPaymentMethod()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Add Payment Method")
                    }
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Settings Views (Placeholder implementations)

struct NotificationSettingsView: View {
    var body: some View {
        List {
            Section("Ride Updates") {
                Toggle("Driver Assigned", isOn: .constant(true))
                Toggle("Driver Arrived", isOn: .constant(true))
                Toggle("Trip Started", isOn: .constant(true))
            }
            
            Section("Promotions") {
                Toggle("Special Offers", isOn: .constant(false))
                Toggle("Price Drops", isOn: .constant(true))
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        List {
            Section("Location") {
                Toggle("Share Location", isOn: .constant(true))
                Toggle("Location History", isOn: .constant(false))
            }
            
            Section("Data") {
                Toggle("Usage Analytics", isOn: .constant(true))
                Toggle("Crash Reports", isOn: .constant(true))
            }
        }
        .navigationTitle("Privacy & Safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccessibilitySettingsView: View {
    var body: some View {
        List {
            Section("Display") {
                Toggle("Large Text", isOn: .constant(false))
                Toggle("High Contrast", isOn: .constant(false))
            }
            
            Section("Audio") {
                Toggle("Voice Announcements", isOn: .constant(true))
                Toggle("Sound Effects", isOn: .constant(true))
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RidePreferencesView: View {
    var body: some View {
        List {
            Section("Default Settings") {
                Picker("Preferred Ride Type", selection: .constant(RideType.standard)) {
                    ForEach(RideType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }
            
            Section("Comfort") {
                Toggle("Quiet Mode", isOn: .constant(false))
                Toggle("Temperature Preference", isOn: .constant(false))
            }
        }
        .navigationTitle("Ride Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Common Issues") {
                NavigationLink("Can't find my driver") {
                    Text("Help content here")
                }
                NavigationLink("Payment problems") {
                    Text("Help content here")
                }
                NavigationLink("App not working") {
                    Text("Help content here")
                }
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactSupportView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Need Help?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Our support team is available 24/7 to assist you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Call Support") {
                    // Implement call functionality
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button("Send Message") {
                    // Implement messaging functionality
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.1))
                .foregroundColor(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AccountView()
        .environmentObject(UserManager())
}