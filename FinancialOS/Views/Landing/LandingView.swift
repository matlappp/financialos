// LandingView.swift
import SwiftUI

struct LandingView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear = false; @State private var pulse: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.theme.primary.ignoresSafeArea()
            Circle().fill(Color.theme.accent.opacity(0.2)).frame(width: 350).blur(radius: 80).offset(x: -80, y: -260 + pulse * 15)
            Circle().fill(Color.theme.accent.opacity(0.12)).frame(width: 280).blur(radius: 60).offset(x: 120, y: 180 - pulse * 10)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 80)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill").font(.system(size: 28, weight: .bold)).foregroundStyle(Color.theme.accentLight)
                        Text("Financial").font(AppFont.title(26)).foregroundStyle(.white) + Text(".OS").font(AppFont.title(26)).foregroundStyle(Color.theme.accentLight)
                    }.opacity(appear ? 1 : 0)
                    
                    VStack(spacing: 12) {
                        Text(L10n.heroTitle1).font(AppFont.hero(36)).foregroundStyle(.white)
                        Text(L10n.heroTitle2).font(AppFont.hero(36)).foregroundStyle(Color.theme.accentLight)
                    }.multilineTextAlignment(.center).opacity(appear ? 1 : 0).offset(y: appear ? 0 : 30)
                    
                    Text(L10n.heroSubtitle).font(AppFont.body(15)).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 32).opacity(appear ? 1 : 0)
                    
                    Button { UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.5)) { appState.screen = .onboarding }
                    } label: {
                        HStack(spacing: 10) { Text(L10n.getStarted).font(AppFont.subhead()); Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)) }
                            .foregroundStyle(Color.theme.primary).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.white)).shadow(color: .white.opacity(0.2), radius: 20, y: 6)
                    }.padding(.horizontal, 48).opacity(appear ? 1 : 0).scaleEffect(appear ? 1 : 0.9)
                    
                    // V2 Teaser
                    v2Teaser
                    
                    features
                    
                    HStack(spacing: 12) { metricBadge("AI", "Powered"); metricBadge("24/7", "Advisor"); metricBadge("100%", "Personal") }.padding(.horizontal, 24)
                    
                    Button { withAnimation { appState.screen = .onboarding } } label: {
                        Text(L10n.getStarted).font(AppFont.subhead()).foregroundStyle(Color.theme.primary).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                    }.padding(.horizontal, 48)
                    
                    Text(L10n.freeToStart).font(AppFont.caption(12)).foregroundStyle(.white.opacity(0.4))
                    Spacer().frame(height: 60)
                }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1)) { appear = true }; withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) { pulse = 1 } }
    }
    
    private var v2Teaser: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill").font(.system(size: 20)).foregroundStyle(Color.theme.accentLight)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(L10n.teamProjectTitle).font(AppFont.subhead(14)).foregroundStyle(.white)
                    Text("V2").font(AppFont.label(9)).foregroundStyle(Color.theme.accentLight).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.theme.accentLight.opacity(0.2)))
                }
                Text(L10n.comingSoonV2).font(AppFont.caption(12)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "lock.fill").font(.system(size: 14)).foregroundStyle(.white.opacity(0.3))
        }
        .padding(14).background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1)))
        .padding(.horizontal, 24).opacity(appear ? 1 : 0)
    }
    
    private var features: some View {
        VStack(spacing: 14) {
            featureRow(icon: "dollarsign.circle.fill", title: ThemeManager.shared.language == .fr ? "Analyse Intelligente des Revenus" : "Smart Income Analysis",
                      desc: ThemeManager.shared.language == .fr ? "Estimation auto des taxes et du net mensuel" : "Auto-estimate taxes & net monthly pay", num: "01")
            featureRow(icon: "doc.text.fill", title: ThemeManager.shared.language == .fr ? "Questionnaire IA Complet" : "Complete AI Questionnaire",
                      desc: ThemeManager.shared.language == .fr ? "Profil financier de niveau conseiller" : "Advisor-level financial profiling", num: "02")
            featureRow(icon: "brain.head.profile", title: ThemeManager.shared.language == .fr ? "Moteur de Stratégie" : "Strategy Engine",
                      desc: ThemeManager.shared.language == .fr ? "Budget personnalisé, jalons et actions" : "Personalized budget, milestones & actions", num: "03")
            featureRow(icon: "chart.bar.xaxis", title: ThemeManager.shared.language == .fr ? "Suivi & Optimisation" : "Track & Optimize",
                      desc: ThemeManager.shared.language == .fr ? "Analytics, factures et coaching IA" : "Spending analytics, bills & AI coaching", num: "04")
        }.padding(.horizontal, 24).opacity(appear ? 1 : 0)
    }
    
    private func featureRow(icon: String, title: String, desc: String, num: String) -> some View {
        HStack(spacing: 14) {
            Text(num).font(AppFont.mono(11)).foregroundStyle(Color.theme.accentLight.opacity(0.5)).frame(width: 22)
            ZStack { Circle().fill(Color.white.opacity(0.1)).frame(width: 42, height: 42); Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color.theme.accentLight) }
            VStack(alignment: .leading, spacing: 3) { Text(title).font(AppFont.subhead(15)).foregroundStyle(.white); Text(desc).font(AppFont.caption(13)).foregroundStyle(.white.opacity(0.55)) }
            Spacer()
        }.padding(14).background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1)))
    }
    
    private func metricBadge(_ v: String, _ l: String) -> some View {
        VStack(spacing: 4) { Text(v).font(AppFont.title(20)).foregroundStyle(Color.theme.accentLight); Text(l).font(AppFont.caption(11)).foregroundStyle(.white.opacity(0.5)) }
            .frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
    }
}
