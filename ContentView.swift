//
//  ContentView.swift
//  JuiceBox
//
//  Enhanced ride-sharing app with iOS 16 features
//  Capabilities: Apple Pay, Wallet Passes, Live Activities, MapKit, Passkeys
//

import SwiftUI
import MapKit
import AuthenticationServices
import PassKit
import ActivityKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var rideManager: RideManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedTab = 0
    @State private var showingLoginSheet = false
    @State private var showingProfile = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Ride Tab
            RideView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Ride")
                }
                .tag(0)
            
            // MARK: - Activity Tab
            ActivityView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Activity")
                }
                .tag(1)
            
            // MARK: - Account Tab
            AccountView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Account")
                }
                .tag(2)
        }
        .accentColor(.orange)
        .sheet(isPresented: $showingLoginSheet) {
            if !userManager.isAuthenticated {
                PasskeyLoginView()
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
        .onChange(of: locationManager.currentLocation) { location in
            if let location = location {
                updateMapRegion(for: location.coordinate)
            }
        }
    }
    
    private func checkAuthenticationStatus() {
        if !userManager.isAuthenticated {
            showingLoginSheet = true
        }
    }
    
    private func updateMapRegion(for coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

// MARK: - Ride View

struct RideView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var rideManager: RideManager
    
    @State private var destination = ""
    @State private var showingDestinationPicker = false
    @State private var selectedRideType: RideType = .standard
    @State private var estimatedPrice = "$0.00"
    @State private var estimatedTime = "0 min"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Map View
                MapViewRepresentable(
                    region: $locationManager.mapRegion,
                    userLocation: locationManager.currentLocation,
                    availableDrivers: rideManager.nearbyDrivers,
                    currentRide: rideManager.currentRide
                )
                .ignoresSafeArea(.all, edges: .top)
                
                // MARK: - Ride Controls Overlay
                VStack {
                    Spacer()
                    
                    RideControlsCard(
                        destination: $destination,
                        selectedRideType: $selectedRideType,
                        estimatedPrice: estimatedPrice,
                        estimatedTime: estimatedTime,
                        showingDestinationPicker: $showingDestinationPicker
                    )
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .searchable(text: $destination, placement: .navigationBarDrawer(displayMode: .always))
            .onSubmit(of: .search) {
                searchDestination()
            }
        }
    }
    
    private func searchDestination() {
        Task {
            await rideManager.searchDestination(destination)
            updatePriceEstimate()
        }
    }
    
    private func updatePriceEstimate() {
        // Calculate estimated price and time
        if let currentLocation = locationManager.currentLocation,
           let destinationCoordinate = rideManager.destinationCoordinate {
            
            let distance = currentLocation.distance(from: CLLocation(
                latitude: destinationCoordinate.latitude,
                longitude: destinationCoordinate.longitude
            ))
            
            let basePrice = selectedRideType.basePrice
            let pricePerMile = selectedRideType.pricePerMile
            let totalPrice = basePrice + (distance / 1609.34 * pricePerMile) // Convert meters to miles
            
            estimatedPrice = String(format: "$%.2f", totalPrice)
            estimatedTime = "\(Int(distance / 1609.34 * 2)) min" // Rough estimate
        }
    }
}

// MARK: - Ride Controls Card

struct RideControlsCard: View {
    @Binding var destination: String
    @Binding var selectedRideType: RideType
    let estimatedPrice: String
    let estimatedTime: String
    @Binding var showingDestinationPicker: Bool
    
    @EnvironmentObject var rideManager: RideManager
    @State private var showingPaymentSheet = false
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Destination Input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Where to?", text: $destination)
                    .textFieldStyle(.plain)
                
                if !destination.isEmpty {
                    Button("Clear") {
                        destination = ""
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // MARK: - Ride Type Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RideType.allCases, id: \.self) { rideType in
                        RideTypeCard(
                            rideType: rideType,
                            isSelected: selectedRideType == rideType,
                            estimatedPrice: estimatedPrice,
                            estimatedTime: estimatedTime
                        )
                        .onTapGesture {
                            selectedRideType = rideType
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // MARK: - Request Ride Button
            Button {
                requestRide()
            } label: {
                HStack {
                    Text("Request \(selectedRideType.displayName)")
                    Spacer()
                    Text(estimatedPrice)
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(destination.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
    
    private func requestRide() {
        Task {
            await rideManager.requestRide(
                destination: destination,
                rideType: selectedRideType
            )
            showingPaymentSheet = true
        }
    }
}

// MARK: - Ride Type Card

struct RideTypeCard: View {
    let rideType: RideType
    let isSelected: Bool
    let estimatedPrice: String
    let estimatedTime: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: rideType.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            Text(rideType.displayName)
                .font(.headline)
                .foregroundColor(isSelected ? .orange : .primary)
            
            Text(estimatedTime)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(estimatedPrice)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .orange : .primary)
        }
        .padding()
        .frame(width: 120, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? .orange.opacity(0.1) : .regularMaterial)
                .stroke(isSelected ? .orange : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(RideManager())
        .environmentObject(UserManager())
}