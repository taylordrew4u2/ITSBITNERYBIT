import UIKit
import AVFoundation
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize memory manager early
        _ = MemoryManager.shared
        
        // Configure Firebase synchronously on main thread.
        // Must happen before any Firebase service is accessed.
        FirebaseApp.configure()
        
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        // Additional memory warning handling
        MemoryManager.shared.handleMemoryWarning()
    }
}
