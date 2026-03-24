// LandingView.swift
// Financial.OS — Premium Landing Page (Blue & White)

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear = false
    @State private var pulse: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Deep blue background
            Color.theme.primary.ignoresSafeArea()
            
            // Decorative elements
            Circle()
                .fill(Color.theme.accent.opacity(0.2))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: -80, y: -260 + pulse * 15)
            
            Circle()
                .fill(Color.theme.accentLight.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 120, y: 180 - pulse * 10)
            
            // Grid pattern
            GeometryReader { geo in
                Path { p in
                    for x in stride(from: 0, to: geo.size.width, by: 50) {
                        p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: 50) {
                        p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: geo.size.width, y: y))
                    }
                }.stroke(Color.white.opacity(0.03), lineWidth: 0.5)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 80)
                    
                    // Logo
                    HStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.theme.accentLight)
                        Text("Financial")
                            .font(AppFont.title(26))
                            .foregroundStyle(.white)
                        + Text(".OS")
                            .font(AppFont.title(26))
                            .foregroundStyle(Color.theme.accentLight)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    
                    // Hero
                    VStack(spacing: 14) {
                        Text("Your Financial")
                            .font(AppFont.hero(38))
                            .foregroundStyle(.white)
                        Text("Operating System")
                            .font(AppFont.hero(38))
                            .foregroundStyle(Color.theme.accentLight)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 30)
                    
                    Text("AI-powered financial planning that\ntransforms your income into a strategic\nroadmap for success.")
                        .font(AppFont.body(16))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .opacity(appear ? 1 : 0)
                    
                    // CTA
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            appState.screen = .onboarding
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("Get Started")
                                .font(AppFont.subhead(17))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white)
                        )
                        .shadow(color: .white.opacity(0.2), radius: 20, y: 6)
                    }
                    .padding(.horizontal, 48)
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    
                    Spacer().frame(height: 20)
                    
                    // Features
                    VStack(spacing: 16) {
                        featureRow(icon: "dollarsign.circle.fill", title: "Smart Income Analysis", desc: "Auto-estimate taxes & net monthly pay", num: "01")
                        featureRow(icon: "doc.text.fill", title: "AI Questionnaire", desc: "Advisor-level financial profiling", num: "02")
                        featureRow(icon: "brain.head.profile", title: "Strategy Engine", desc: "Personalized budget, milestones & actions", num: "03")
                        featureRow(icon: "chart.bar.xaxis", title: "Track & Optimize", desc: "Spending analytics, bills & AI coaching", num: "04")
                    }
                    .padding(.horizontal, 24)
                    .opacity(appear ? 1 : 0)
                    
                    // Metrics
                    HStack(spacing: 12) {
                        metricBadge("AI", "Powered")
                        metricBadge("24/7", "Advisor")
                        metricBadge("100%", "Personal")
                    }
                    .padding(.horizontal, 24)
                    
                    // Bottom CTA
                    VStack(spacing: 12) {
                        Button {
                            withAnimation { appState.screen = .onboarding }
                        } label: {
                            Text("Start Your Financial Plan")
                                .font(AppFont.subhead())
                                .foregroundStyle(Color.theme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                        }
                        .padding(.horizontal, 48)
                        
                        Text("Free to start • No credit card required")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.top, 20)
                    
                    Spacer().frame(height: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1)) { appear = true }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) { pulse = 1 }
        }
    }
    
    // MARK: - Subviews
    private func featureRow(icon: String, title: String, desc: String, num: String) -> some View {
        HStack(spacing: 14) {
            Text(num)
                .font(AppFont.mono(11))
                .foregroundStyle(Color.theme.accentLight.opacity(0.5))
                .frame(width: 22)
            
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color.theme.accentLight)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.subhead(15)).foregroundStyle(.white)
                Text(desc).font(AppFont.caption(13)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1)))
    }
    
    private func metricBadge(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.title(20)).foregroundStyle(Color.theme.accentLight)
            Text(label).font(AppFont.caption(11)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
    }
}
