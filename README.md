# JuiceBox - Advanced Ride-Sharing App

A cutting-edge ride-sharing application built with iOS 16+ features, showcasing modern SwiftUI design patterns, passkey authentication, Live Activities, and MapKit integration.

## 🚀 Features

### Core Features
- **🔐 Advanced Authentication**: Passkey support, Sign in with Apple, and email authentication
- **🗺️ Interactive Maps**: Real-time driver tracking with custom annotations
- **⚡ Live Activities**: Dynamic Island and Lock Screen integration for ride tracking
- **💳 Apple Pay Integration**: Seamless payment processing with multiple payment methods
- **📱 iOS 16+ Design**: Modern UI with materials, gradients, and fluid animations

### Ride-Sharing Features
- Multiple ride types (Economy, Standard, Premium, XL, Electric)
- Real-time driver location updates
- Route planning and navigation
- Price estimation and surge pricing
- Ride history and activity tracking
- Driver rating and communication

### Technical Features
- **SwiftUI with iOS 16 APIs**: NavigationStack, searchable, materials
- **Combine Framework**: Reactive programming for real-time updates
- **Core Location**: GPS tracking and geocoding
- **MapKit**: Custom annotations and route overlays
- **ActivityKit**: Live Activities for ride status
- **Background Tasks**: Location updates during rides

## 📱 Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## 🏗️ Architecture

The app follows MVVM architecture with the following structure:

```
JuiceBox/
├── JuiceBoxApp.swift          # Main app entry point
├── ContentView.swift          # Primary navigation
├── PasskeyLoginView.swift     # Authentication
├── Models/
│   └── RideModels.swift       # Data models
├── Managers/
│   ├── LocationManager.swift  # Location services
│   ├── RideManager.swift      # Ride management
│   └── UserManager.swift      # User authentication
└── Views/
    ├── MapViewRepresentable.swift  # MapKit integration
    ├── ActivityView.swift          # Ride activity & history
    └── AccountView.swift           # User profile & settings
```

## 🎯 Key iOS 16 Features Implemented

### Authentication & Privacy
- **Passkeys**: FIDO2 WebAuthn passwordless authentication
- **Sign in with Apple**: Privacy-focused social login
- **Privacy Manifest**: App tracking transparency

### MapKit & Location
- **Modern MapKit**: iOS 16 map configurations
- **Place Descriptors**: Enhanced location search
- **Real-time Tracking**: Background location updates

### Live Activities
- **Dynamic Island**: Real-time ride status
- **Lock Screen Widgets**: Glanceable ride information
- **Push Notifications**: Remote activity updates

### Design System
- **Materials**: Ultra-thin, thin, regular materials
- **SF Symbols 4**: Latest icon set with variable colors
- **Accessibility**: VoiceOver, Dynamic Type support

## 🚗 Ride Flow

1. **Authentication**: User signs in with Passkey/Apple ID
2. **Location**: App requests location permissions
3. **Destination Search**: MapKit-powered place search
4. **Ride Selection**: Choose ride type and see price estimate
5. **Driver Matching**: Real-time driver assignment
6. **Live Tracking**: Live Activity with ride progress
7. **Payment**: Apple Pay integration for seamless payment
8. **Completion**: Ride history and rating

## 💻 Getting Started

### For Swift Playgrounds (iPad/Mac)
1. Download the project files
2. Open Swift Playgrounds
3. Create a new "App" project
4. Replace the default files with the JuiceBox files
5. Build and run

### For Xcode
1. Clone the repository
2. Open `JuiceBoxApp.swift` in Xcode
3. Configure signing & capabilities:
   - Apple Pay (merchant ID required)
   - Background Modes (Location updates)
   - Push Notifications
4. Build and run on iOS 16+ device/simulator

## 🔧 Configuration

### Required Entitlements
```xml
<!-- Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required to find nearby drivers and navigate to your destination.</string>

<key>NSSupportsLiveActivities</key>
<true/>

<!-- Entitlements -->
com.apple.developer.authentication-services.autofill-credential-provider
com.apple.developer.passkit.pass-type-identifiers
```

### Apple Pay Setup
1. Create merchant ID in Apple Developer Portal
2. Configure payment processing (Stripe, Square, etc.)
3. Update `merchant.com.juicebox.pay` identifier

## 🎨 Design Highlights

- **Liquid Glass Materials**: iOS 16 design language
- **Dynamic Gradients**: Orange to red brand colors
- **Spatial Design**: Depth and layering
- **Micro-interactions**: Smooth animations and transitions
- **Accessibility First**: VoiceOver and accessibility labels

## 🧪 Testing

The app includes mock data services for testing:
- Simulated driver locations around San Francisco
- Mock ride history with various destinations
- Dummy payment methods for development

## 🚀 Advanced Features

### Live Activities Implementation
```swift
@available(iOS 16.1, *)
struct RideAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: RideStatus
        var driverName: String?
        var estimatedArrival: Date?
    }
}
```

### Passkey Authentication
```swift
let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: "juicebox.app"
)
let request = provider.createCredentialAssertionRequest(
    challenge: generateChallenge()
)
```

### MapKit Integration
```swift
struct MapViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration()
        }
        return mapView
    }
}
```

## 📚 Learning Resources

This project demonstrates:
- Modern iOS app architecture
- SwiftUI best practices
- iOS 16 API adoption
- Real-world ride-sharing features
- Advanced authentication flows
- Location-based services

## 🤝 Contributing

This is an educational project showcasing iOS 16 capabilities. Feel free to:
- Explore the code structure
- Experiment with features
- Adapt for your own projects
- Submit improvements

## 📄 License

This project is provided for educational purposes. Please ensure you comply with all relevant terms when using location services, authentication providers, and payment processing.

---

**Built with ❤️ and iOS 16**

*JuiceBox - Where every ride is supercharged.*