//
//  thebitbinderApp.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData

@main
struct thebitbinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var startup = AppStartupCoordinator()
    @StateObject private var userPreferences = UserPreferences()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Joke.self,
            JokeFolder.self,
            Recording.self,
            SetList.self,
            NotebookPhotoRecord.self,
            RoastTarget.self,
            RoastJoke.self,
            BrainstormIdea.self,
            ImportBatch.self,
            ImportedJokeMetadata.self,
            UnresolvedImportFragment.self,
            ChatMessage.self,
        ])

        // One store file. All fallbacks use this same URL — never switch to a
        // different file, which would silently lose all user data.
        // IMPORTANT: SwiftData's default store name is "default.store".
        // Changing this to anything else creates a NEW empty store and makes
        // all existing user data invisible. Always use "default.store".
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")

        // 1️⃣ Persistent + CloudKit (single container, full schema)
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .private("iCloud.666bit")
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            print("✅ [ModelContainer] Persistent + CloudKit ready")
            return container
        } catch {
            print("⚠️ [ModelContainer] CloudKit failed (\(error)) — local-only fallback (same file, data preserved)")
        }

        // 2️⃣ Same file, no CloudKit — all data preserved, just no sync
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            print("✅ [ModelContainer] Persistent local-only ready")
            return container
        } catch {
            // Back up corrupted store before wiping
            let backupURL = URL.applicationSupportDirectory
                .appending(path: "default.store.bak-\(Int(Date().timeIntervalSince1970))")
            try? FileManager.default.copyItem(at: storeURL, to: backupURL)
            print("❌ [ModelContainer] Store unreadable — backed up. Error: \(error)")
        }

        // 3️⃣ Last resort: wipe corrupted files at same URL (backup already saved above)
        for ext in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(
                at: URL.applicationSupportDirectory.appending(path: "default.store\(ext)")
            )
        }
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            print("⚠️ [ModelContainer] Fresh store at same URL (corrupted store was backed up)")
            return container
        } catch {
            fatalError("❌ [ModelContainer] Cannot create any persistent store: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                if startup.isReady {
                    ContentView()
                } else {
                    LaunchScreenView(statusText: startup.statusText, userName: userPreferences.userName)
                }
            }
            .task {
                // Wire the main context into the sync service so remote change
                // notifications can call refreshAllObjects() on the right context
                iCloudSyncService.shared.modelContext = sharedModelContainer.mainContext
                
                // Register for remote push notifications — CloudKit uses silent
                // pushes to tell the app "new data available, please fetch"
                // Without this, sync only happens when the app is foregrounded
                UIApplication.shared.registerForRemoteNotifications()
                
                await startup.start()
            }
            .environmentObject(userPreferences)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                try? sharedModelContainer.mainContext.save()
                iCloudKeyValueStore.shared.pushToCloud()
            } else if scenePhase == .active {
                // Save triggers SwiftData to merge any pending remote changes into the UI
                try? sharedModelContainer.mainContext.save()
                iCloudKeyValueStore.shared.pullFromCloud()
                NotificationManager.shared.scheduleIfNeeded()
            }
        }
    }
}
