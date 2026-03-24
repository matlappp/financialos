// GrowthView.swift
// Financial.OS — Growth: Progress visualization & projections

import SwiftUI

struct GrowthView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let plan = appState.plan {
                    progressOverview(plan)
                    savingsChart(plan)
                    milestonesTimeline(plan)
                    monthlyBreakdown(plan)
                } else {
                    emptyState
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle("Growth")
    }
    
    // MARK: - Progress Overview
    private func progressOverview(_ plan: FinancialPlan) -> some View {
        VStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.theme.surfaceAlt, lineWidth: 14)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: plan.progressPercent)
                    .stroke(Color.theme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(String(format: "%.0f", plan.progressPercent * 100))%")
                        .font(AppFont.currency(36))
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("Complete")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.theme.textTertiary)
                }
            }
            
            HStack(spacing: 24) {
                statColumn("Goal", plan.goalAmount.asCurrencyShort, Color.theme.accent)
                statColumn("Saved", (plan.goalAmount * plan.progressPercent).asCurrencyShort, Color.theme.success)
                statColumn("Remaining", (plan.goalAmount * (1 - plan.progressPercent)).asCurrencyShort, Color.theme.warning)
            }
        }
        .padding(24).card().padding(.horizontal, 20)
    }
    
    private func statColumn(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
            Text(value).font(AppFont.subhead()).foregroundStyle(color)
        }.frame(maxWidth: .infinity)
    }
    
    // MARK: - Savings Chart (bar chart)
    private func savingsChart(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SAVINGS PROJECTION").sectionLabel()
            
            GeometryReader { geo in
                let maxVal = plan.projections.map { $0.cumulativeSavings }.max() ?? 1
                let barWidth = max(8, (geo.size.width - CGFloat(plan.projections.count) * 6) / CGFloat(plan.projections.count))
                
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(plan.projections) { p in
                        VStack(spacing: 4) {
                            if p.month % 2 == 0 || plan.projections.count <= 6 {
                                Text(p.cumulativeSavings.asCurrencyShort)
                                    .font(AppFont.caption(9))
                                    .foregroundStyle(Color.theme.textTertiary)
                            }
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    p.month <= 1
                                    ? Color.theme.accent
                                    : Color.theme.accent.opacity(0.3 + (Double(p.month) / Double(plan.projections.count)) * 0.7)
                                )
                                .frame(width: barWidth, height: max(4, (p.cumulativeSavings / maxVal) * 160))
                            
                            Text("M\(p.month)")
                                .font(AppFont.caption(9))
                                .foregroundStyle(Color.theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 200)
            
            // Goal line indicator
            HStack(spacing: 6) {
                Rectangle().fill(Color.theme.success).frame(width: 16, height: 2)
                Text("Goal: \(plan.goalAmount.asCurrencyShort)").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Milestones Timeline
    private func milestonesTimeline(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MILESTONES").sectionLabel()
            
            ForEach(Array(plan.milestones.enumerated()), id: \.element.id) { i, m in
                HStack(alignment: .top, spacing: 14) {
                    // Timeline indicator
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(m.isCompleted ? Color.theme.success : Color.theme.accent)
                                .frame(width: 28, height: 28)
                            Image(systemName: m.isCompleted ? "checkmark" : "\(i + 1).circle.fill")
                                .font(.system(size: m.isCompleted ? 12 : 16))
                                .foregroundStyle(.white)
                        }
                        if i < plan.milestones.count - 1 {
                            Rectangle()
                                .fill(Color.theme.surfaceAlt)
                                .frame(width: 2, height: 50)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(m.title).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                        HStack(spacing: 12) {
                            Label(m.targetDate.dayMonth, systemImage: "calendar")
                                .font(AppFont.caption(12)).foregroundStyle(Color.theme.textTertiary)
                            Label(m.targetAmount.asCurrencyShort, systemImage: "target")
                                .font(AppFont.caption(12)).foregroundStyle(Color.theme.accent)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    Spacer()
                }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Monthly Breakdown
    private func monthlyBreakdown(_ plan: FinancialPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MONTHLY BREAKDOWN").sectionLabel()
            
            ForEach(plan.projections.prefix(6)) { p in
                HStack {
                    Text("Month \(p.month)").font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(p.projectedSavings.asCurrency).font(AppFont.subhead(14)).foregroundStyle(Color.theme.success)
                        Text("Cumulative: \(p.cumulativeSavings.asCurrencyShort)").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                    }
                }
                .padding(.vertical, 8)
                if p.month < (plan.projections.prefix(6).last?.month ?? 6) { Divider() }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 48)).foregroundStyle(Color.theme.textTertiary)
            Text("No Plan Yet").font(AppFont.heading()).foregroundStyle(Color.theme.textPrimary)
            Text("Complete onboarding to see your growth projections.").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary)
        }.padding(60)
    }
}
