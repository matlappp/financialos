// DashboardView.swift — AI Roadmap
import SwiftUI
struct DashboardView: View {
    @EnvironmentObject var appState: AppState; @StateObject private var vm = DashboardVM()
    private var fr: Bool { ThemeManager.shared.language == .fr }
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 18) { if let p = appState.plan { setupCard; heroCard(p); savingsTimeline(p); budgetBreakdown(p); recs(p) } }.padding(.bottom, 40) }
        .background(Color.theme.background).navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { HStack(spacing: 6) { Image(systemName: "chart.line.uptrend.xyaxis.circle.fill").foregroundStyle(Color.theme.accent); Text("Financial").font(AppFont.subhead(17)).foregroundStyle(Color.theme.textPrimary) + Text(".OS").font(AppFont.subhead(17)).foregroundStyle(Color.theme.accent) } }
            ToolbarItem(placement: .navigationBarTrailing) { Menu { Button { withAnimation { appState.logout() } } label: { Label(L10n.signOut, systemImage: "arrow.right.square") } } label: { if let u = appState.user { ZStack { Circle().fill(Color.theme.accent).frame(width: 32, height: 32); Text(u.initials).font(AppFont.caption(11)).foregroundStyle(.white).bold() } } } }
        }
    }
    private var setupCard: some View {
        VStack(spacing: 8) { HStack { Text("SETUP PROGRESS").sectionLabel(); Spacer(); Text("100%").font(AppFont.subhead()).foregroundStyle(Color.theme.accent) }
            GeometryReader { g in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 3).fill(Color.theme.surfaceAlt).frame(height: 6); RoundedRectangle(cornerRadius: 3).fill(Color.theme.primaryGradient).frame(width: g.size.width, height: 6) } }.frame(height: 6) }.padding(18).card().padding(.horizontal, 20)
    }
    private func heroCard(_ p: FinancialPlan) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) { VStack(alignment: .leading, spacing: 6) { Text("TIMELINE").font(AppFont.label()).foregroundStyle(.white.opacity(0.5)); Text(p.title).font(AppFont.title(20)).foregroundStyle(.white).lineLimit(2) }; Spacer()
                VStack(alignment: .trailing, spacing: 4) { Text("TARGET").font(AppFont.label()).foregroundStyle(.white.opacity(0.5)); Text(p.goalAmount.asCurrency).font(AppFont.currency(24)).foregroundStyle(Color.theme.accentLight) } }
            Divider().background(.white.opacity(0.15))
            HStack { VStack(alignment: .leading) { Text("\(String(format: "%.0f", p.progressPercent*100))%").font(AppFont.currency(32)).foregroundStyle(.white) }; Spacer()
                Text("\(p.timeFrameMonths) \(fr ? "Mois" : "Mo")").font(AppFont.heading()).foregroundStyle(.white) }
            GeometryReader { g in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.15)).frame(height: 6); RoundedRectangle(cornerRadius: 3).fill(Color.theme.accentLight).frame(width: max(g.size.width*p.progressPercent,4), height: 6) } }.frame(height: 6)
        }.padding(20).background(RoundedRectangle(cornerRadius: 18).fill(Color.theme.cardGradient)).shadow(color: .black.opacity(0.12), radius: 14, y: 5).padding(.horizontal, 20)
    }
    private func savingsTimeline(_ p: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(fr ? "FEUILLE DE ROUTE" : "SAVINGS ROADMAP").sectionLabel()
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { ForEach(p.projections.prefix(6)) { pr in
                VStack(spacing: 6) { Circle().fill(pr.month==1 ? Color.theme.accent : Color.theme.surfaceAlt).frame(width: 10, height: 10)
                    Text(fr ? "MOIS \(pr.month)" : "M\(pr.month)").font(AppFont.label()).foregroundStyle(Color.theme.textTertiary)
                    Text(pr.projectedSavings.asCurrency).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                    Text(pr.cumulativeSavings.asCurrencyShort).font(AppFont.caption(11)).foregroundStyle(Color.theme.accent)
                }.frame(width: 110).padding(.vertical, 8)
            }}.padding(.horizontal, 4) } }.padding(18).card().padding(.horizontal, 20)
    }
    private func budgetBreakdown(_ p: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) { HStack { Text(fr ? "BUDGET MENSUEL" : "MONTHLY BUDGET").sectionLabel(); Spacer(); Text(p.monthlyBudget.income.asCurrencyShort).font(AppFont.subhead()) }
            let items: [(String,Double,Color)] = [(fr ? "Logement":"Housing", p.monthlyBudget.housing, .theme.housing),(fr ? "Alimentation":"Food", p.monthlyBudget.food, .theme.food),("Transport", p.monthlyBudget.transport, .theme.transport),(fr ? "Épargne":"Savings", p.monthlyBudget.savings, .theme.savings),(fr ? "Dettes":"Debt", p.monthlyBudget.debtPayment, .theme.debt),(fr ? "Assurance":"Insurance", p.monthlyBudget.insurance, .theme.info),(fr ? "Abonnements":"Subs", p.monthlyBudget.subscriptions, .theme.subscription)]
            ForEach(items.filter{$0.1>0}, id:\.0) { i in
                HStack(spacing: 8) { Circle().fill(i.2).frame(width: 8, height: 8); Text(i.0).font(AppFont.body(13)); Spacer(); Text(i.1.asCurrency).font(AppFont.subhead(13)); Text("\(String(format:"%.0f",(i.1/max(p.monthlyBudget.income,1))*100))%").font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary).frame(width:28,alignment:.trailing) }
                GeometryReader{g in ZStack(alignment:.leading){RoundedRectangle(cornerRadius:2).fill(i.2.opacity(0.15)).frame(height:3);RoundedRectangle(cornerRadius:2).fill(i.2).frame(width:g.size.width*(i.1/max(p.monthlyBudget.income,1)),height:3)}}.frame(height:3)
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private func recs(_ p: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(fr ? "RECOMMANDATIONS" : "RECOMMENDATIONS").sectionLabel()
            ForEach(p.recommendations) { r in
                VStack(alignment: .leading, spacing: 5) {
                    HStack { Text(r.title).font(AppFont.subhead(13)); Spacer(); Text(r.priority).font(AppFont.caption(9)).foregroundStyle(r.priority=="High" ? Color.theme.danger : Color.theme.warning).padding(.horizontal,5).padding(.vertical,2).background(Capsule().fill((r.priority=="High" ? Color.theme.danger : Color.theme.warning).opacity(0.1))) }
                    if vm.expandedRec==r.id { Text(r.description).font(AppFont.body(12)).foregroundStyle(Color.theme.textSecondary).lineSpacing(2) }
                }.padding(12).background(RoundedRectangle(cornerRadius:10).fill(Color.theme.surfaceAlt)).onTapGesture{withAnimation(.spring(response:0.3)){vm.expandedRec=vm.expandedRec==r.id ? nil : r.id}}
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
}
