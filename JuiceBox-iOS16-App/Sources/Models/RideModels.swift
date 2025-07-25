//
//  RideModels.swift
//  JuiceBox
//
//  Data models for ride-sharing functionality
//

import Foundation
import MapKit
import CoreLocation
import ActivityKit

// MARK: - Ride Type

enum RideType: String, CaseIterable, Codable {
    case economy = "economy"
    case standard = "standard"
    case premium = "premium"
    case xl = "xl"
    case electric = "electric"
    
    var displayName: String {
        switch self {
        case .economy: return "Economy"
        case .standard: return "Standard"
        case .premium: return "Premium"
        case .xl: return "XL"
        case .electric: return "Electric"
        }
    }
    
    var iconName: String {
        switch self {
        case .economy: return "car.compact.fill"
        case .standard: return "car.fill"
        case .premium: return "car.side.fill"
        case .xl: return "car.rear.fill"
        case .electric: return "bolt.car.fill"
        }
    }
    
    var basePrice: Double {
        switch self {
        case .economy: return 2.50
        case .standard: return 3.00
        case .premium: return 4.50
        case .xl: return 5.00
        case .electric: return 3.25
        }
    }
    
    var pricePerMile: Double {
        switch self {
        case .economy: return 1.20
        case .standard: return 1.50
        case .premium: return 2.25
        case .xl: return 2.50
        case .electric: return 1.40
        }
    }
    
    var capacity: Int {
        switch self {
        case .economy: return 4
        case .standard: return 4
        case .premium: return 4
        case .xl: return 6
        case .electric: return 4
        }
    }
}

// MARK: - Ride Status

enum RideStatus: String, Codable {
    case requesting = "requesting"
    case accepted = "accepted"
    case driverEnRoute = "driver_en_route"
    case arrived = "arrived"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .requesting: return "Finding your driver..."
        case .accepted: return "Ride accepted"
        case .driverEnRoute: return "Driver on the way"
        case .arrived: return "Driver has arrived"
        case .inProgress: return "Ride in progress"
        case .completed: return "Ride completed"
        case .cancelled: return "Ride cancelled"
        }
    }
    
    var systemImage: String {
        switch self {
        case .requesting: return "magnifyingglass"
        case .accepted: return "checkmark.circle.fill"
        case .driverEnRoute: return "car.fill"
        case .arrived: return "location.fill"
        case .inProgress: return "road.lanes"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Ride Model

struct Ride: Identifiable, Codable {
    let id: UUID
    let userId: String
    let driverId: String?
    let rideType: RideType
    var status: RideStatus
    let pickupLocation: Location
    let destination: Location
    var driver: Driver?
    var route: RideRoute?
    var pricing: RidePricing
    let requestedAt: Date
    var acceptedAt: Date?
    var startedAt: Date?
    var completedAt: Date?
    var estimatedArrival: Date?
    
    init(
        userId: String,
        rideType: RideType,
        pickupLocation: Location,
        destination: Location,
        pricing: RidePricing
    ) {
        self.id = UUID()
        self.userId = userId
        self.driverId = nil
        self.rideType = rideType
        self.status = .requesting
        self.pickupLocation = pickupLocation
        self.destination = destination
        self.driver = nil
        self.route = nil
        self.pricing = pricing
        self.requestedAt = Date()
        self.acceptedAt = nil
        self.startedAt = nil
        self.completedAt = nil
        self.estimatedArrival = nil
    }
}

// MARK: - Location Model

struct Location: Codable, Equatable {
    let coordinate: CLLocationCoordinate2D
    let address: String
    let name: String?
    let placeId: String?
    
    init(coordinate: CLLocationCoordinate2D, address: String, name: String? = nil) {
        self.coordinate = coordinate
        self.address = address
        self.name = name
        self.placeId = nil
    }
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Driver Model

struct Driver: Identifiable, Codable {
    let id: String
    let name: String
    let photoURL: String?
    let rating: Double
    let totalRides: Int
    let vehicleInfo: VehicleInfo
    var currentLocation: CLLocationCoordinate2D
    let phoneNumber: String
    var isAvailable: Bool
    
    init(
        id: String,
        name: String,
        photoURL: String? = nil,
        rating: Double,
        totalRides: Int,
        vehicleInfo: VehicleInfo,
        currentLocation: CLLocationCoordinate2D,
        phoneNumber: String
    ) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.rating = rating
        self.totalRides = totalRides
        self.vehicleInfo = vehicleInfo
        self.currentLocation = currentLocation
        self.phoneNumber = phoneNumber
        self.isAvailable = true
    }
}

// MARK: - Vehicle Info

struct VehicleInfo: Codable {
    let make: String
    let model: String
    let year: Int
    let color: String
    let licensePlate: String
    let rideType: RideType
    
    var displayName: String {
        return "\(color) \(make) \(model)"
    }
}

// MARK: - Ride Route

struct RideRoute: Codable {
    let polyline: String
    let distance: CLLocationDistance
    let estimatedDuration: TimeInterval
    let steps: [RouteStep]
}

struct RouteStep: Codable {
    let instruction: String
    let distance: CLLocationDistance
    let duration: TimeInterval
}

// MARK: - Ride Pricing

struct RidePricing: Codable {
    let basePrice: Double
    let distancePrice: Double
    let timePrice: Double
    let surgeMultiplier: Double
    let estimatedTotal: Double
    let currency: String
    
    init(
        basePrice: Double,
        distancePrice: Double,
        timePrice: Double = 0,
        surgeMultiplier: Double = 1.0,
        currency: String = "USD"
    ) {
        self.basePrice = basePrice
        self.distancePrice = distancePrice
        self.timePrice = timePrice
        self.surgeMultiplier = surgeMultiplier
        self.estimatedTotal = (basePrice + distancePrice + timePrice) * surgeMultiplier
        self.currency = currency
    }
}

// MARK: - Live Activity Attributes (iOS 16.1+)

@available(iOS 16.1, *)
struct RideAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: RideStatus
        var driverName: String?
        var vehicleInfo: String?
        var estimatedArrival: Date?
        var currentLocation: CLLocationCoordinate2D?
    }
    
    var rideId: String
    var pickupAddress: String
    var destinationAddress: String
    var rideType: RideType
}

// MARK: - Search Result

struct PlaceSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let placeId: String?
    let category: PlaceCategory
}

enum PlaceCategory: String, CaseIterable {
    case airport = "airport"
    case restaurant = "restaurant"
    case hotel = "hotel"
    case shopping = "shopping"
    case hospital = "hospital"
    case school = "school"
    case business = "business"
    case residence = "residence"
    case other = "other"
    
    var systemImage: String {
        switch self {
        case .airport: return "airplane"
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double"
        case .shopping: return "bag"
        case .hospital: return "cross.case"
        case .school: return "graduationcap"
        case .business: return "building"
        case .residence: return "house"
        case .other: return "mappin"
        }
    }
}