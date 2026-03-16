import UIKit
import AVFoundation
import UserNotifications
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize memory manager early
        _ = MemoryManager.shared
        
        // Initialize iCloud key-value sync (pulls remote values into UserDefaults)
        _ = iCloudKeyValueStore.shared
        
        // Set up daily notification manager as the UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        NotificationManager.shared.scheduleIfNeeded()
        
        // Register for remote notifications — required for CloudKit sync between devices
        application.registerForRemoteNotifications()
        
        // Verify iCloud account status
        Task {
            do {
                let status = try await CKContainer(identifier: "iCloud.10Bit").accountStatus()
                switch status {
                case .available:
                    print("✅ [CloudKit] iCloud account available — sync enabled")
                case .noAccount:
                    print("⚠️ [CloudKit] No iCloud account signed in — sync disabled")
                case .restricted:
                    print("⚠️ [CloudKit] iCloud restricted — sync disabled")
                case .couldNotDetermine:
                    print("⚠️ [CloudKit] Could not determine iCloud status")
                case .temporarilyUnavailable:
                    print("⚠️ [CloudKit] iCloud temporarily unavailable")
                @unknown default:
                    print("⚠️ [CloudKit] Unknown iCloud status: \(status.rawValue)")
                }
            } catch {
                print("❌ [CloudKit] Error checking account: \(error)")
            }
        }
        
        return true
    }
    
    // MARK: - Remote Notification Handling (CloudKit Sync)
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ [CloudKit] Registered for remote notifications — sync will push/pull automatically")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("⚠️ [CloudKit] Failed to register for remote notifications: \(error.localizedDescription)")
        print("⚠️ [CloudKit] CloudKit sync may not trigger automatically between devices")
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        MemoryManager.shared.handleMemoryWarning()
    }
}
