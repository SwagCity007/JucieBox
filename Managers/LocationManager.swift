//
//  LocationManager.swift
//  JuiceBox
//
//  Enhanced location management with iOS 16 features
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var currentAddress: String = ""
    @Published var locationError: LocationError?
    @Published var isUpdatingLocation = false
    
    private var cancellables = Set<AnyCancellable>()
    
    enum LocationError: LocalizedError {
        case unauthorized
        case unavailable
        case denied
        case restricted
        case geocodingFailed
        
        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Location access not authorized"
            case .unavailable:
                return "Location services unavailable"
            case .denied:
                return "Location access denied"
            case .restricted:
                return "Location access restricted"
            case .geocodingFailed:
                return "Failed to get address"
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
        setupBindings()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func setupBindings() {
        // Update map region when location changes
        $currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateMapRegion(for: location.coordinate)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .denied
        case .authorizedWhenInUse:
            startLocationUpdates()
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = .unauthorized
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = .unavailable
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentAddress() async {
        guard let location = currentLocation else { return }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                currentAddress = formatAddress(from: placemark)
            }
        } catch {
            locationError = .geocodingFailed
        }
    }
    
    func searchPlaces(query: String) async -> [PlaceSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = mapRegion
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            return response.mapItems.compactMap { mapItem -> PlaceSearchResult? in
                guard let location = mapItem.placemark.location else { return nil }
                
                return PlaceSearchResult(
                    name: mapItem.name ?? "Unknown",
                    address: formatAddress(from: mapItem.placemark),
                    coordinate: location.coordinate,
                    placeId: mapItem.identifier?.rawValue,
                    category: categorizePlace(mapItem)
                )
            }
        } catch {
            return []
        }
    }
    
    func getDirections(to destination: CLLocationCoordinate2D) async -> MKRoute? {
        guard let currentLocation = currentLocation else { return nil }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func updateMapRegion(for coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        
        if let streetName = placemark.thoroughfare {
            addressComponents.append(streetName)
        }
        
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        
        return addressComponents.joined(separator: " ")
    }
    
    private func categorizePlace(_ mapItem: MKMapItem) -> PlaceCategory {
        // Simple categorization based on point of interest category
        if let category = mapItem.pointOfInterestCategory {
            switch category {
            case .airport:
                return .airport
            case .restaurant, .cafe, .bakery:
                return .restaurant
            case .hotel:
                return .hotel
            case .store, .gasStation:
                return .shopping
            case .hospital:
                return .hospital
            case .school, .university:
                return .school
            default:
                return .other
            }
        }
        return .other
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Get address for current location
        Task {
            await getCurrentAddress()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isUpdatingLocation = false
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .denied
            case .locationUnknown:
                locationError = .unavailable
            default:
                locationError = .unavailable
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
            locationError = nil
        case .denied, .restricted:
            stopLocationUpdates()
            locationError = .denied
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - MapKit Extensions

extension MKCoordinateRegion {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return centerLocation.distance(from: targetLocation)
    }
}