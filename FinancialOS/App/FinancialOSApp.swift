// FinancialOSApp.swift
// Financial.OS — Main App Entry

import SwiftUI

@main
struct FinancialOSApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Root Navigation
struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            switch appState.screen {
            case .landing:
                LandingView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: appState.screen == .main)
        .animation(.easeInOut(duration: 0.45), value: appState.screen == .landing)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var workplaceVM = WorkplaceVM()
    @StateObject private var agendaVM = AgendaVM()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack { DashboardView() }
                .tabItem { Label(AppTab.roadmap.title, systemImage: AppTab.roadmap.icon) }
                .tag(AppTab.roadmap)
            
            NavigationStack { WorkplaceView() }
                .tabItem { Label(AppTab.workplace.title, systemImage: AppTab.workplace.icon) }
                .tag(AppTab.workplace)
                .environmentObject(workplaceVM)
            
            NavigationStack { AgendaView() }
                .tabItem { Label(AppTab.agenda.title, systemImage: AppTab.agenda.icon) }
                .tag(AppTab.agenda)
                .environmentObject(agendaVM)
            
            NavigationStack { GrowthView() }
                .tabItem { Label(AppTab.growth.title, systemImage: AppTab.growth.icon) }
                .tag(AppTab.growth)
            
            NavigationStack { SafeSpaceView() }
                .tabItem { Label(AppTab.safeSpace.title, systemImage: AppTab.safeSpace.icon) }
                .tag(AppTab.safeSpace)
        }
        .tint(Color.theme.accent)
        .onAppear { NotificationService.shared.requestPermission() }
    }
}
