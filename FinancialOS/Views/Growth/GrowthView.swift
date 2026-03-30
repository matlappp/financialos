// GrowthView.swift — Progress, projections, AI month comparison
import SwiftUI
struct GrowthView: View {
    @EnvironmentObject var appState: AppState
    private var fr: Bool { ThemeManager.shared.language == .fr }
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 18) { if let p = appState.plan { progressRing(p); savingsChart(p); milestonesTimeline(p); monthlyBreakdown(p) } else { empty } }.padding(.bottom, 40) }
        .background(Color.theme.background).navigationTitle(L10n.growth)
    }
    private func progressRing(_ p: FinancialPlan) -> some View {
        VStack(spacing: 18) {
            ZStack { Circle().stroke(Color.theme.surfaceAlt, lineWidth: 14).frame(width: 150, height: 150)
                Circle().trim(from: 0, to: p.progressPercent).stroke(Color.theme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round)).frame(width: 150, height: 150).rotationEffect(.degrees(-90))
                VStack(spacing: 3) { Text("\(String(format: "%.0f", p.progressPercent*100))%").font(AppFont.currency(34)).foregroundStyle(Color.theme.textPrimary)
                    Text(fr ? "Complété" : "Complete").font(AppFont.caption()).foregroundStyle(Color.theme.textTertiary) } }
            HStack(spacing: 20) {
                st(fr ? "Objectif" : "Goal", p.goalAmount.asCurrencyShort, Color.theme.accent)
                st(fr ? "Épargné" : "Saved", (p.goalAmount*p.progressPercent).asCurrencyShort, Color.theme.success)
                st(fr ? "Restant" : "Remaining", (p.goalAmount*(1-p.progressPercent)).asCurrencyShort, Color.theme.warning)
            }
        }.padding(22).card().padding(.horizontal, 20)
    }
    private func st(_ l: String, _ v: String, _ c: Color) -> some View { VStack(spacing: 3) { Text(l).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary); Text(v).font(AppFont.subhead()).foregroundStyle(c) }.frame(maxWidth: .infinity) }
    private func savingsChart(_ p: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(fr ? "PROJECTION D'ÉPARGNE" : "SAVINGS PROJECTION").sectionLabel()
            GeometryReader { g in let mx = p.projections.map{$0.cumulativeSavings}.max() ?? 1
                HStack(alignment: .bottom, spacing: 5) { ForEach(p.projections) { pr in VStack(spacing: 3) {
                    if pr.month % 2 == 0 || p.projections.count <= 6 { Text(pr.cumulativeSavings.asCurrencyShort).font(AppFont.caption(8)).foregroundStyle(Color.theme.textTertiary) }
                    RoundedRectangle(cornerRadius: 3).fill(Color.theme.accent.opacity(0.3 + (Double(pr.month)/Double(p.projections.count))*0.7)).frame(height: max(4, (pr.cumulativeSavings/mx)*150))
                    Text("M\(pr.month)").font(AppFont.caption(8)).foregroundStyle(Color.theme.textTertiary)
                }.frame(maxWidth: .infinity) } }
            }.frame(height: 190)
            HStack(spacing: 5) { Rectangle().fill(Color.theme.success).frame(width: 14, height: 2)
                Text(fr ? "Objectif: \(p.goalAmount.asCurrencyShort)" : "Goal: \(p.goalAmount.asCurrencyShort)").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary) }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private func milestonesTimeline(_ p: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(fr ? "JALONS" : "MILESTONES").sectionLabel()
            ForEach(Array(p.milestones.enumerated()), id: \.element.id) { i, m in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) { ZStack { Circle().fill(m.isCompleted ? Color.theme.success : Color.theme.accent).frame(width: 26, height: 26)
                        Image(systemName: m.isCompleted ? "checkmark" : "\(i+1).circle.fill").font(.system(size: m.isCompleted ? 11 : 14)).foregroundStyle(.white) }
                        if i < p.milestones.count-1 { Rectangle().fill(Color.theme.surfaceAlt).frame(width: 2, height: 40) } }
                    VStack(alignment: .leading, spacing: 4) { Text(m.title).font(AppFont.subhead(14))
                        HStack(spacing: 10) { Label(m.targetDate.dayMonth, systemImage: "calendar").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                            Label(m.targetAmount.asCurrencyShort, systemImage: "target").font(AppFont.caption(11)).foregroundStyle(Color.theme.accent) } }.padding(.bottom, 12); Spacer()
                }
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private func monthlyBreakdown(_ p: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(fr ? "DÉTAIL MENSUEL" : "MONTHLY DETAIL").sectionLabel()
            ForEach(p.projections.prefix(6)) { pr in
                HStack { Text(fr ? "Mois \(pr.month)" : "Month \(pr.month)").font(AppFont.body(14)); Spacer()
                    VStack(alignment: .trailing, spacing: 1) { Text(pr.projectedSavings.asCurrency).font(AppFont.subhead(13)).foregroundStyle(Color.theme.success)
                        Text(fr ? "Cumulatif: \(pr.cumulativeSavings.asCurrencyShort)" : "Cumulative: \(pr.cumulativeSavings.asCurrencyShort)").font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary) } }.padding(.vertical, 6)
                if pr.month < (p.projections.prefix(6).last?.month ?? 6) { Divider() }
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private var empty: some View { VStack(spacing: 14) { Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 44)).foregroundStyle(Color.theme.textTertiary); Text(fr ? "Aucun plan" : "No Plan Yet").font(AppFont.heading()); Text(fr ? "Complète l'onboarding pour voir tes projections." : "Complete onboarding to see projections.").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary) }.padding(50) }
}
