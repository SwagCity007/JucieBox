//
//  RideManager.swift
//  JuiceBox
//
//  Advanced ride management with Live Activities and real-time tracking
//

import Foundation
import CoreLocation
import MapKit
import ActivityKit
import Combine

@MainActor
class RideManager: ObservableObject {
    @Published var currentRide: Ride?
    @Published var nearbyDrivers: [Driver] = []
    @Published var rideHistory: [Ride] = []
    @Published var isRequestingRide = false
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var searchResults: [PlaceSearchResult] = []
    @Published var rideError: RideError?
    
    private var liveActivity: Activity<RideAttributes>?
    private var cancellables = Set<AnyCancellable>()
    private let mockDataService = MockDataService()
    
    enum RideError: LocalizedError {
        case noDriversAvailable
        case requestFailed
        case locationUnavailable
        case paymentFailed
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .noDriversAvailable:
                return "No drivers available in your area"
            case .requestFailed:
                return "Failed to request ride"
            case .locationUnavailable:
                return "Location services required"
            case .paymentFailed:
                return "Payment processing failed"
            case .cancelled:
                return "Ride was cancelled"
            }
        }
    }
    
    init() {
        setupMockData()
        startDriverTracking()
    }
    
    // MARK: - Public Methods
    
    func searchDestination(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Use LocationManager for place search
        // This would be injected in a real app
        let locationManager = LocationManager()
        searchResults = await locationManager.searchPlaces(query: query)
        
        // Set destination coordinate if we have results
        if let firstResult = searchResults.first {
            destinationCoordinate = firstResult.coordinate
        }
    }
    
    func requestRide(destination: String, rideType: RideType) async {
        guard let destinationCoord = destinationCoordinate else {
            rideError = .locationUnavailable
            return
        }
        
        isRequestingRide = true
        
        do {
            // Simulate ride request
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let ride = await createRide(
                destination: destination,
                destinationCoordinate: destinationCoord,
                rideType: rideType
            )
            
            currentRide = ride
            
            // Start Live Activity
            await startLiveActivity(for: ride)
            
            // Simulate driver assignment
            await simulateDriverAssignment()
            
            isRequestingRide = false
            
        } catch {
            isRequestingRide = false
            rideError = .requestFailed
        }
    }
    
    func cancelRide() async {
        guard var ride = currentRide else { return }
        
        ride.status = .cancelled
        currentRide = ride
        
        // End Live Activity
        await endLiveActivity()
        
        // Add to history
        rideHistory.append(ride)
        currentRide = nil
    }
    
    func completeRide() async {
        guard var ride = currentRide else { return }
        
        ride.status = .completed
        ride.completedAt = Date()
        currentRide = ride
        
        // End Live Activity
        await endLiveActivity()
        
        // Add to history
        rideHistory.append(ride)
        currentRide = nil
    }
    
    // MARK: - Live Activities
    
    @available(iOS 16.1, *)
    private func startLiveActivity(for ride: Ride) async {
        let attributes = RideAttributes(
            rideId: ride.id.uuidString,
            pickupAddress: ride.pickupLocation.address,
            destinationAddress: ride.destination.address,
            rideType: ride.rideType
        )
        
        let contentState = RideAttributes.ContentState(
            status: ride.status,
            driverName: ride.driver?.name,
            vehicleInfo: ride.driver?.vehicleInfo.displayName,
            estimatedArrival: ride.estimatedArrival,
            currentLocation: ride.driver?.currentLocation
        )
        
        do {
            liveActivity = try Activity<RideAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: .token
            )
            print("Live Activity started: \(liveActivity?.id ?? "unknown")")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivity() async {
        guard let liveActivity = liveActivity,
              let ride = currentRide else { return }
        
        let contentState = RideAttributes.ContentState(
            status: ride.status,
            driverName: ride.driver?.name,
            vehicleInfo: ride.driver?.vehicleInfo.displayName,
            estimatedArrival: ride.estimatedArrival,
            currentLocation: ride.driver?.currentLocation
        )
        
        await liveActivity.update(using: contentState)
    }
    
    @available(iOS 16.1, *)
    private func endLiveActivity() async {
        guard let liveActivity = liveActivity else { return }
        
        await liveActivity.end(dismissalPolicy: .immediate)
        self.liveActivity = nil
    }
    
    // MARK: - Private Methods
    
    private func setupMockData() {
        nearbyDrivers = mockDataService.generateMockDrivers()
        rideHistory = mockDataService.generateMockRideHistory()
    }
    
    private func startDriverTracking() {
        // Simulate driver location updates
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDriverLocations()
            }
            .store(in: &cancellables)
    }
    
    private func updateDriverLocations() {
        // Simulate driver movement
        for i in 0..<nearbyDrivers.count {
            let randomOffset = 0.001 * Double.random(in: -1...1)
            nearbyDrivers[i].currentLocation.latitude += randomOffset
            nearbyDrivers[i].currentLocation.longitude += randomOffset
        }
    }
    
    private func createRide(
        destination: String,
        destinationCoordinate: CLLocationCoordinate2D,
        rideType: RideType
    ) async -> Ride {
        // Mock current location (would come from LocationManager)
        let currentLocation = CLLocationCoordinate2D(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        let pickupLocation = Location(
            coordinate: currentLocation,
            address: "Current Location"
        )
        
        let destinationLocation = Location(
            coordinate: destinationCoordinate,
            address: destination
        )
        
        // Calculate pricing
        let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            .distance(from: CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude))
        
        let pricing = RidePricing(
            basePrice: rideType.basePrice,
            distancePrice: (distance / 1609.34) * rideType.pricePerMile // Convert meters to miles
        )
        
        return Ride(
            userId: "current-user",
            rideType: rideType,
            pickupLocation: pickupLocation,
            destination: destinationLocation,
            pricing: pricing
        )
    }
    
    private func simulateDriverAssignment() async {
        guard var ride = currentRide,
              let driver = nearbyDrivers.first else { return }
        
        // Simulate driver acceptance
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        ride.status = .accepted
        ride.driver = driver
        ride.acceptedAt = Date()
        ride.estimatedArrival = Date().addingTimeInterval(300) // 5 minutes
        currentRide = ride
        
        // Update Live Activity
        if #available(iOS 16.1, *) {
            await updateLiveActivity()
        }
        
        // Simulate driver en route
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        ride.status = .driverEnRoute
        currentRide = ride
        
        if #available(iOS 16.1, *) {
            await updateLiveActivity()
        }
    }
}

// MARK: - Mock Data Service

class MockDataService {
    func generateMockDrivers() -> [Driver] {
        let sanFranciscoCoords = [
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
            CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994),
            CLLocationCoordinate2D(latitude: 37.7549, longitude: -122.4394),
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4094)
        ]
        
        let driverNames = ["Alex Chen", "Maria Garcia", "James Wilson", "Sarah Kim", "David Brown"]
        let vehicles = [
            VehicleInfo(make: "Toyota", model: "Prius", year: 2022, color: "Silver", licensePlate: "ABC123", rideType: .standard),
            VehicleInfo(make: "Tesla", model: "Model 3", year: 2023, color: "White", licensePlate: "XYZ789", rideType: .electric),
            VehicleInfo(make: "Honda", model: "Accord", year: 2021, color: "Black", licensePlate: "DEF456", rideType: .premium),
            VehicleInfo(make: "Chevrolet", model: "Suburban", year: 2022, color: "Blue", licensePlate: "GHI789", rideType: .xl),
            VehicleInfo(make: "Nissan", model: "Versa", year: 2020, color: "Red", licensePlate: "JKL012", rideType: .economy)
        ]
        
        return zip(zip(driverNames, vehicles), sanFranciscoCoords).enumerated().map { index, data in
            let ((name, vehicle), coordinate) = data
            return Driver(
                id: "driver-\(index)",
                name: name,
                rating: Double.random(in: 4.2...4.9),
                totalRides: Int.random(in: 100...2000),
                vehicleInfo: vehicle,
                currentLocation: coordinate,
                phoneNumber: "+1-555-000-\(String(format: "%04d", index))"
            )
        }
    }
    
    func generateMockRideHistory() -> [Ride] {
        let pastDestinations = [
            ("SFO Airport", CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)),
            ("Union Square", CLLocationCoordinate2D(latitude: 37.7880, longitude: -122.4075)),
            ("Golden Gate Park", CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)),
            ("Fisherman's Wharf", CLLocationCoordinate2D(latitude: 37.8080, longitude: -122.4177))
        ]
        
        let currentLocation = Location(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "Current Location"
        )
        
        return pastDestinations.enumerated().map { index, (name, coordinate) in
            let destination = Location(coordinate: coordinate, address: name)
            let pricing = RidePricing(basePrice: 3.0, distancePrice: Double.random(in: 8...25))
            
            var ride = Ride(
                userId: "current-user",
                rideType: RideType.allCases.randomElement() ?? .standard,
                pickupLocation: currentLocation,
                destination: destination,
                pricing: pricing
            )
            
            ride.status = .completed
            ride.completedAt = Date().addingTimeInterval(-Double(index + 1) * 86400) // Past days
            
            return ride
        }
    }
}