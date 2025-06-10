//
//  bt6App.swift
//  bt6
//
//  Created by nolestMac on 2025/6/10.
//

import SwiftUI
import CoreData

@main
struct bt6App: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(AppState())
                .environmentObject(BabyManager())
                .environmentObject(ActivityManager())
                .environmentObject(MediaManager())
                .environmentObject(SettingsManager())
                .environmentObject(GAIAnalysisManager())
                .environmentObject(SmartAssistantManager())
                .environmentObject(SocialManager())
                .environmentObject(NotificationManager.shared)
        }
    }
}

// 应用状态管理
class AppState: ObservableObject {
    @Published var isFirstLaunch = true
    @Published var hasSetupBaby = false
    @Published var selectedBaby: Baby?
    @Published var currentTab = 0
    
    init() {
        checkFirstLaunch()
        checkBabySetup()
    }
    
    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    private func checkBabySetup() {
        hasSetupBaby = UserDefaults.standard.bool(forKey: "hasSetupBaby")
    }
    
    func markBabySetup() {
        hasSetupBaby = true
        UserDefaults.standard.set(true, forKey: "hasSetupBaby")
    }
}
