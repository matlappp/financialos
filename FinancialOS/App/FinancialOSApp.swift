// FinancialOSApp.swift
import SwiftUI

@main
struct FinancialOSApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        ZStack {
            switch appState.screen {
            case .landing: LandingView().transition(.opacity.combined(with: .move(edge: .bottom)))
            case .onboarding: OnboardingView().transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .main: MainTabView().transition(.opacity)
            }
        }.animation(.easeInOut(duration: 0.45), value: appState.screen == .main)
         .animation(.easeInOut(duration: 0.45), value: appState.screen == .landing)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var workVM = WorkplaceVM()
    @StateObject private var agendaVM = AgendaVM()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack { DashboardView() }.tabItem { Label(L10n.roadmap, systemImage: "square.grid.2x2.fill") }.tag(AppTab.roadmap)
            NavigationStack { WorkplaceView() }.tabItem { Label(L10n.workplace, systemImage: "bolt.fill") }.tag(AppTab.workplace).environmentObject(workVM)
            NavigationStack { AgendaView() }.tabItem { Label(L10n.agenda, systemImage: "calendar") }.tag(AppTab.agenda).environmentObject(agendaVM)
            NavigationStack { SafeSpaceView().environmentObject(workVM).environmentObject(agendaVM) }
                .tabItem { Label(L10n.safeSpace, systemImage: "shield.fill") }.tag(AppTab.safeSpace)
            NavigationStack { MoreView() }.tabItem { Label(L10n.more, systemImage: "ellipsis.circle.fill") }.tag(AppTab.more)
        }
        .tint(Color.theme.accent)
        .onAppear { NotificationService.shared.requestPermission() }
    }
}
