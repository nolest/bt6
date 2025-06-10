//
//  ContentView.swift
//  bt6
//
//  Created by nolestMac on 2025/6/10.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Group {
            if appState.isFirstLaunch || babyManager.babies.isEmpty {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            // 检查配额重置
            settingsManager.checkQuotaReset()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 今日页面
            TodayView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("今日")
                }
                .tag(0)
            
            // 记录页面
            RecordsView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("記錄")
                }
                .tag(1)
            
            // 统计页面
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
                .tag(2)
            
            // 照片与影片页面
            MediaView()
                .tabItem {
                    Image(systemName: "photo.fill")
                    Text("照片")
                }
                .tag(3)
            
            // 更多页面
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis.circle.fill")
                    Text("更多")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { oldValue, newValue in
            appState.currentTab = newValue
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(BabyManager())
        .environmentObject(ActivityManager())
        .environmentObject(MediaManager())
        .environmentObject(SettingsManager())
        .environmentObject(GAIAnalysisManager())
        .environmentObject(SmartAssistantManager())
        .environmentObject(SocialManager())
}
