//
//  ActivityView.swift
//  JuiceBox
//
//  Ride activity and history with iOS 16 design patterns
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var rideManager: RideManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Custom Segmented Control
                customSegmentedControl
                
                // MARK: - Content
                TabView(selection: $selectedTab) {
                    CurrentRideView()
                        .tag(0)
                    
                    RideHistoryView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(["Current", "History"], id: \.self) { tab in
                let index = tab == "Current" ? 0 : 1
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tab)
                        .font(.headline)
                        .fontWeight(selectedTab == index ? .semibold : .regular)
                        .foregroundColor(selectedTab == index ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index ?
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : nil
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

// MARK: - Current Ride View

struct CurrentRideView: View {
    @EnvironmentObject var rideManager: RideManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let currentRide = rideManager.currentRide {
                    CurrentRideCard(ride: currentRide)
                        .padding(.horizontal)
                } else {
                    EmptyRideStateView()
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Current Ride Card

struct CurrentRideCard: View {
    let ride: Ride
    @EnvironmentObject var rideManager: RideManager
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Status Header
            HStack {
                Image(systemName: ride.status.systemImage)
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading) {
                    Text(ride.status.displayName)
                        .font(.headline)
                    
                    if let estimatedArrival = ride.estimatedArrival {
                        Text("ETA: \(estimatedArrival, style: .time)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(String(format: "$%.2f", ride.pricing.estimatedTotal))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Divider()
            
            // MARK: - Route Information
            VStack(spacing: 12) {
                RouteLocationRow(
                    icon: "circle.fill",
                    iconColor: .green,
                    title: "Pickup",
                    address: ride.pickupLocation.address
                )
                
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                RouteLocationRow(
                    icon: "mappin.circle.fill",
                    iconColor: .red,
                    title: "Destination",
                    address: ride.destination.address
                )
            }
            
            // MARK: - Driver Information (if assigned)
            if let driver = ride.driver {
                Divider()
                
                DriverInfoCard(driver: driver)
            }
            
            // MARK: - Action Buttons
            actionButtons
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch ride.status {
        case .requesting, .accepted, .driverEnRoute:
            Button("Cancel Ride") {
                Task {
                    await rideManager.cancelRide()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
        case .arrived, .inProgress:
            HStack(spacing: 12) {
                Button("Contact Driver") {
                    // Implement contact functionality
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button("Emergency") {
                    // Implement emergency functionality
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
        default:
            EmptyView()
        }
    }
}

// MARK: - Route Location Row

struct RouteLocationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let address: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(address)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Driver Info Card

struct DriverInfoCard: View {
    let driver: Driver
    
    var body: some View {
        HStack {
            // Driver avatar placeholder
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(driver.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text(String(format: "%.1f", driver.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(driver.totalRides) rides")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(driver.vehicleInfo.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Button {
                    // Call driver
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.green)
                        .clipShape(Circle())
                }
                
                Button {
                    // Message driver
                } label: {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.blue)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Empty Ride State

struct EmptyRideStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.circle")
                .font(.system(size: 80))
                .foregroundColor(.orange.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Active Ride")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Request a ride to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Ride History View

struct RideHistoryView: View {
    @EnvironmentObject var rideManager: RideManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(rideManager.rideHistory) { ride in
                    RideHistoryCard(ride: ride)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Ride History Card

struct RideHistoryCard: View {
    let ride: Ride
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.destination.name ?? ride.destination.address)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let completedAt = ride.completedAt {
                        Text(completedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", ride.pricing.estimatedTotal))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(ride.rideType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: ride.rideType.iconName)
                    .foregroundColor(.orange)
                
                Text("\(ride.pickupLocation.address) → \(ride.destination.address)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ActivityView()
        .environmentObject(RideManager())
        .environmentObject(UserManager())
}