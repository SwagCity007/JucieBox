//
//  MapViewRepresentable.swift
//  JuiceBox
//
//  MapKit integration with iOS 16 features
//

import SwiftUI
import MapKit
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let userLocation: CLLocation?
    let availableDrivers: [Driver]
    let currentRide: Ride?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // iOS 16 features
        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration()
            mapView.showsUserTrackingButton = false
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        updateAnnotations(mapView)
        
        // Update route overlay
        updateRouteOverlay(mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        // Remove existing annotations (except user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add driver annotations
        for driver in availableDrivers {
            let annotation = DriverAnnotation(driver: driver)
            mapView.addAnnotation(annotation)
        }
        
        // Add ride destination annotation
        if let ride = currentRide {
            let destinationAnnotation = DestinationAnnotation(
                coordinate: ride.destination.coordinate,
                title: "Destination",
                subtitle: ride.destination.address
            )
            mapView.addAnnotation(destinationAnnotation)
        }
    }
    
    private func updateRouteOverlay(_ mapView: MKMapView) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add route overlay if available
        if let ride = currentRide,
           let route = ride.route {
            
            // Create polyline from route
            let polyline = MKPolyline(encodedPolyline: route.polyline)
            if let polyline = polyline {
                mapView.addOverlay(polyline)
            }
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Use default user location view
            }
            
            if let driverAnnotation = annotation as? DriverAnnotation {
                return createDriverAnnotationView(for: driverAnnotation, in: mapView)
            }
            
            if let destinationAnnotation = annotation as? DestinationAnnotation {
                return createDestinationAnnotationView(for: destinationAnnotation, in: mapView)
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemOrange
                renderer.lineWidth = 5
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        private func createDriverAnnotationView(
            for annotation: DriverAnnotation,
            in mapView: MKMapView
        ) -> MKAnnotationView {
            let identifier = "DriverAnnotation"
            
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
            
            annotationView.annotation = annotation
            annotationView.markerTintColor = .systemOrange
            annotationView.glyphImage = UIImage(systemName: annotation.driver.vehicleInfo.rideType.iconName)
            annotationView.displayPriority = .required
            
            return annotationView
        }
        
        private func createDestinationAnnotationView(
            for annotation: DestinationAnnotation,
            in mapView: MKMapView
        ) -> MKAnnotationView {
            let identifier = "DestinationAnnotation"
            
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
            
            annotationView.annotation = annotation
            annotationView.markerTintColor = .systemRed
            annotationView.glyphImage = UIImage(systemName: "mappin")
            annotationView.displayPriority = .required
            
            return annotationView
        }
    }
}

// MARK: - Custom Annotations

class DriverAnnotation: NSObject, MKAnnotation {
    let driver: Driver
    var coordinate: CLLocationCoordinate2D {
        return driver.currentLocation
    }
    
    var title: String? {
        return driver.name
    }
    
    var subtitle: String? {
        return driver.vehicleInfo.displayName
    }
    
    init(driver: Driver) {
        self.driver = driver
    }
}

class DestinationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - MKPolyline Extension for Encoded Polylines

extension MKPolyline {
    convenience init?(encodedPolyline: String) {
        // Simple polyline decoding - in a real app, use a proper polyline decoder
        // This is a simplified version for demonstration
        let coordinates = MapViewRepresentable.decodePolyline(encodedPolyline)
        guard !coordinates.isEmpty else { return nil }
        
        self.init(coordinates: coordinates, count: coordinates.count)
    }
    
    static func decodePolyline(_ encodedPolyline: String) -> [CLLocationCoordinate2D] {
        // Simplified polyline decoding
        // In a real app, implement proper Google polyline algorithm
        // For demo purposes, return a simple path
        return [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994)
        ]
    }
}