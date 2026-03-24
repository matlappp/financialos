// DashboardView.swift
// Financial.OS — AI Roadmap Dashboard (matches screenshot design)

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = DashboardVM()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Setup Progress Bar
                if let plan = appState.plan {
                    setupProgressCard
                    timelineHeroCard(plan)
                    savingsTargetTimeline(plan)
                    budgetBreakdown(plan)
                    recommendationsSection(plan)
                    weeklyActionsSection(plan)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .foregroundStyle(Color.theme.accent)
                    Text("Financial").font(AppFont.subhead(18)).foregroundStyle(Color.theme.textPrimary)
                    + Text(".OS").font(AppFont.subhead(18)).foregroundStyle(Color.theme.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { withAnimation { appState.logout() } } label: { Label("Sign Out", systemImage: "arrow.right.square") }
                } label: {
                    if let u = appState.user {
                        ZStack {
                            Circle().fill(Color.theme.accent).frame(width: 34, height: 34)
                            Text(u.initials).font(AppFont.caption(12)).foregroundStyle(.white).bold()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Setup Progress (matches screenshot)
    private var setupProgressCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("SETUP PROGRESS").sectionLabel()
                Spacer()
                Text("100%").font(AppFont.subhead()).foregroundStyle(Color.theme.accent)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.theme.surfaceAlt).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(Color.theme.primaryGradient).frame(width: geo.size.width, height: 6)
                }
            }.frame(height: 6)
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Timeline Hero Card (matches screenshot dark card)
    private func timelineHeroCard(_ plan: FinancialPlan) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TIMELINE").font(AppFont.label()).foregroundStyle(.white.opacity(0.5)).tracking(1.5)
                    Text(plan.title).font(AppFont.title(24)).foregroundStyle(.white).lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("TARGET DESTINATION").font(AppFont.label()).foregroundStyle(.white.opacity(0.5)).tracking(1)
                    Text(plan.goalAmount.asCurrency)
                        .font(AppFont.currency(28))
                        .foregroundStyle(Color.theme.accentLight)
                }
            }
            
            Divider().background(.white.opacity(0.15))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROGRESS").font(AppFont.label()).foregroundStyle(.white.opacity(0.4))
                    Text("\(String(format: "%.0f", plan.progressPercent * 100))%")
                        .font(AppFont.currency(36))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TIMEFRAME").font(AppFont.label()).foregroundStyle(.white.opacity(0.4))
                    Text("\(plan.timeFrameMonths) Months").font(AppFont.heading()).foregroundStyle(.white)
                }
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(Color.theme.accentLight)
                        .frame(width: max(geo.size.width * plan.progressPercent, 4), height: 6)
                }
            }.frame(height: 6)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.theme.cardGradient))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Monthly Savings Timeline (matches screenshot)
    private func savingsTargetTimeline(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SAVINGS ROADMAP").sectionLabel()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(plan.projections.prefix(6)) { p in
                        VStack(spacing: 10) {
                            // Dot + line
                            ZStack {
                                Circle().fill(p.month == 1 ? Color.theme.accent : Color.theme.surfaceAlt).frame(width: 12, height: 12)
                                if p.month == 1 { Circle().fill(.white).frame(width: 5, height: 5) }
                            }
                            
                            VStack(spacing: 4) {
                                Text("MONTH \(p.month)").font(AppFont.label()).foregroundStyle(Color.theme.textTertiary).tracking(0.8)
                                Text("SAVINGS TARGET").font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary)
                                Text(p.projectedSavings.asCurrency).font(AppFont.subhead(16)).foregroundStyle(Color.theme.textPrimary)
                            }
                            
                            Text("CUMULATIVE").font(AppFont.caption(9)).foregroundStyle(Color.theme.textTertiary)
                            Text(p.cumulativeSavings.asCurrencyShort).font(AppFont.caption(13)).foregroundStyle(Color.theme.accent)
                        }
                        .frame(width: 130)
                        .padding(.vertical, 12)
                        
                        if p.month < (plan.projections.prefix(6).last?.month ?? 6) {
                            Rectangle().fill(Color.theme.surfaceAlt).frame(width: 30, height: 2)
                                .offset(y: -60)
                        }
                    }
                }.padding(.horizontal, 8)
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Budget Breakdown
    private func budgetBreakdown(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MONTHLY BUDGET").sectionLabel()
                Spacer()
                Text(plan.monthlyBudget.income.asCurrencyShort).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
            }
            
            let items: [(String, Double, Color)] = [
                ("Housing", plan.monthlyBudget.housing, Color.theme.housing),
                ("Food", plan.monthlyBudget.food, Color.theme.food),
                ("Transport", plan.monthlyBudget.transport, Color.theme.transport),
                ("Utilities", plan.monthlyBudget.utilities, Color.theme.utilities),
                ("Entertainment", plan.monthlyBudget.entertainment, Color.theme.entertainment),
                ("Savings", plan.monthlyBudget.savings, Color.theme.savings),
                ("Debt", plan.monthlyBudget.debtPayment, Color.theme.debt),
            ]
            
            ForEach(items.filter { $0.1 > 0 }, id: \.0) { item in
                HStack(spacing: 12) {
                    Circle().fill(item.2).frame(width: 10, height: 10)
                    Text(item.0).font(AppFont.body()).foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    Text(item.1.asCurrency).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                    Text("\(String(format: "%.0f", (item.1 / plan.monthlyBudget.income) * 100))%")
                        .font(AppFont.caption()).foregroundStyle(Color.theme.textTertiary).frame(width: 35, alignment: .trailing)
                }
                
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.2.opacity(0.2)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.2)
                        .frame(width: geo.size.width * (item.1 / plan.monthlyBudget.income), height: 4)
                }.frame(height: 4)
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Recommendations
    private func recommendationsSection(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI RECOMMENDATIONS").sectionLabel()
            
            ForEach(plan.recommendations) { rec in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(rec.title).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        if rec.potentialSavings > 0 {
                            Text("+\(rec.potentialSavings.asCurrencyShort)/mo")
                                .font(AppFont.caption(11)).foregroundStyle(Color.theme.success)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(Color.theme.success.opacity(0.1)))
                        }
                        Text(rec.priority)
                            .font(AppFont.caption(10))
                            .foregroundStyle(rec.priority == "High" ? Color.theme.danger : rec.priority == "Medium" ? Color.theme.warning : Color.theme.textTertiary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(rec.priority == "High" ? Color.theme.danger.opacity(0.1) : rec.priority == "Medium" ? Color.theme.warning.opacity(0.1) : Color.theme.surfaceAlt))
                    }
                    
                    if vm.expandedRecommendation == rec.id {
                        Text(rec.description).font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary).lineSpacing(2)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        vm.expandedRecommendation = vm.expandedRecommendation == rec.id ? nil : rec.id
                    }
                }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Weekly Actions
    private func weeklyActionsSection(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WEEKLY ACTION PLAN").sectionLabel()
            
            ForEach(plan.weeklyActions.prefix(4)) { week in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week \(week.weekNumber)").font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        Image(systemName: week.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(week.isCompleted ? Color.theme.success : Color.theme.textTertiary)
                    }
                    ForEach(week.tasks, id: \.self) { task in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Color.theme.accent.opacity(0.3)).frame(width: 6, height: 6).offset(y: 6)
                            Text(task).font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary)
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
}
