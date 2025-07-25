import SwiftUI
import ActivityKit
import UserNotifications
import MapKit
import BackgroundTasks

@main
struct JuiceBoxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var locationManager = LocationManager()
    @StateObject private var rideManager = RideManager()
    @StateObject private var userManager = UserManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(rideManager)
                .environmentObject(userManager)
                .onAppear {
                    configureApp()
                }
        }
    }
    
    private func configureApp() {
        // Request permissions
        requestNotificationPermission()
        requestLocationPermission()
        
        // Configure Live Activities
        configureLiveActivities()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    private func configureLiveActivities() {
        // Live Activities configuration for ride tracking
        Task {
            for await activity in Activity<RideAttributes>.activityUpdates {
                print("Live Activity update: \(activity.id)")
            }
        }
    }
}

class AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register background tasks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.juicebox.background-location",
            using: nil
        ) { task in
            self.handleBackgroundLocationTask(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Send device token to server
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
    }
    
    private func handleBackgroundLocationTask(task: BGAppRefreshTask) {
        // Handle background location updates for active rides
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform background work
        Task {
            // Update location and ride status
            await MainActor.run {
                task.setTaskCompleted(success: true)
            }
        }
    }
}