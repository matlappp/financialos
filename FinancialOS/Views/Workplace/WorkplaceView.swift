// WorkplaceView.swift
// Financial.OS — Workplace: Transaction Tracking + Spending Graphics

import SwiftUI

struct WorkplaceView: View {
    @EnvironmentObject var vm: WorkplaceVM
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summaryCards
                periodSelector
                categoryChart
                categoryBreakdownList
                transactionsList
            }
            .padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle("Workplace")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.showAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(Color.theme.accent)
                }
            }
        }
        .sheet(isPresented: $vm.showAddSheet) { addTransactionSheet }
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard("Income", vm.totalIncome, Color.theme.success, "arrow.down.circle.fill")
            summaryCard("Expenses", vm.totalExpenses, Color.theme.danger, "arrow.up.circle.fill")
            summaryCard("Balance", vm.balance, vm.balance >= 0 ? Color.theme.success : Color.theme.danger, "dollarsign.circle.fill")
        }
        .padding(.horizontal, 20)
    }
    
    private func summaryCard(_ title: String, _ amount: Double, _ color: Color, _ icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            Text(title).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
            Text(amount.asCurrencyShort).font(AppFont.subhead(16)).foregroundStyle(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .card()
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 6) {
            ForEach(WorkplaceVM.TimePeriod.allCases, id: \.self) { p in
                Button { withAnimation { vm.selectedPeriod = p } } label: {
                    Text(p.rawValue).font(AppFont.caption(13))
                        .foregroundStyle(vm.selectedPeriod == p ? .white : Color.theme.textSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(vm.selectedPeriod == p ? Color.theme.accent : Color.theme.surfaceAlt))
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Category Donut Chart
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SPENDING BY CATEGORY").sectionLabel()
            
            if vm.categoryBreakdown.isEmpty {
                Text("No expenses yet").font(AppFont.body()).foregroundStyle(Color.theme.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                HStack(spacing: 20) {
                    // Donut chart
                    ZStack {
                        ForEach(Array(donutSegments.enumerated()), id: \.offset) { i, seg in
                            Circle()
                                .trim(from: seg.start, to: seg.end)
                                .stroke(seg.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        
                        VStack(spacing: 2) {
                            Text(vm.totalExpenses.asCurrencyShort).font(AppFont.subhead(16)).foregroundStyle(Color.theme.textPrimary)
                            Text("Total").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                        }
                    }
                    .frame(width: 130, height: 130)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.categoryBreakdown.prefix(5), id: \.0) { cat, amount in
                            HStack(spacing: 8) {
                                Circle().fill(Color.theme.categoryColor(for: cat)).frame(width: 8, height: 8)
                                Text(cat.rawValue).font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary)
                                Spacer()
                                Text(amount.asCurrencyShort).font(AppFont.caption(12)).foregroundStyle(Color.theme.textPrimary).bold()
                            }
                        }
                    }
                }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    private var donutSegments: [(start: CGFloat, end: CGFloat, color: Color)] {
        guard vm.totalExpenses > 0 else { return [] }
        var segs: [(CGFloat, CGFloat, Color)] = []
        var current: CGFloat = 0
        for (cat, amount) in vm.categoryBreakdown {
            let fraction = CGFloat(amount / vm.totalExpenses)
            segs.append((current, current + fraction - 0.005, Color.theme.categoryColor(for: cat)))
            current += fraction
        }
        return segs
    }
    
    // MARK: - Category Breakdown Bar Chart
    private var categoryBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY DETAILS").sectionLabel()
            
            ForEach(vm.categoryBreakdown, id: \.0) { cat, amount in
                Button {
                    withAnimation { vm.selectedCategory = vm.selectedCategory == cat ? nil : cat }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color.theme.categoryColor(for: cat).opacity(0.12)).frame(width: 36, height: 36)
                            Image(systemName: cat.icon).font(.system(size: 14)).foregroundStyle(Color.theme.categoryColor(for: cat))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(cat.rawValue).font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 2).fill(Color.theme.categoryColor(for: cat).opacity(0.15)).frame(height: 4)
                                RoundedRectangle(cornerRadius: 2).fill(Color.theme.categoryColor(for: cat))
                                    .frame(width: geo.size.width * (amount / vm.totalExpenses), height: 4)
                            }.frame(height: 4)
                        }
                        
                        Text(amount.asCurrency).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                        Text("\(String(format: "%.0f", (amount / vm.totalExpenses) * 100))%")
                            .font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(vm.selectedCategory == cat ? Color.theme.accent.opacity(0.06) : Color.clear)
                    )
                }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Transactions List
    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("RECENT TRANSACTIONS").sectionLabel()
                Spacer()
                if vm.selectedCategory != nil {
                    Button { withAnimation { vm.selectedCategory = nil } } label: {
                        HStack(spacing: 4) {
                            Text("Clear Filter").font(AppFont.caption(11))
                            Image(systemName: "xmark.circle.fill").font(.system(size: 12))
                        }.foregroundStyle(Color.theme.accent)
                    }
                }
            }
            
            ForEach(vm.filteredTransactions.prefix(20)) { t in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(
                            t.type == .income ? Color.theme.success.opacity(0.12) : Color.theme.categoryColor(for: t.category).opacity(0.12)
                        ).frame(width: 40, height: 40)
                        Image(systemName: t.type == .income ? "arrow.down.left" : t.category.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(t.type == .income ? Color.theme.success : Color.theme.categoryColor(for: t.category))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t.title).font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary)
                        Text(t.date.dayMonth).font(AppFont.caption(12)).foregroundStyle(Color.theme.textTertiary)
                    }
                    
                    Spacer()
                    
                    Text("\(t.type == .income ? "+" : "-")\(t.amount.asCurrency)")
                        .font(AppFont.subhead(15))
                        .foregroundStyle(t.type == .income ? Color.theme.success : Color.theme.textPrimary)
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { vm.delete(t) } label: { Label("Delete", systemImage: "trash") }
                }
                
                if t.id != vm.filteredTransactions.prefix(20).last?.id {
                    Divider()
                }
            }
            
            if vm.filteredTransactions.isEmpty {
                Text("No transactions for this period").font(AppFont.body()).foregroundStyle(Color.theme.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Add Transaction Sheet
    private var addTransactionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Type toggle
                    HStack(spacing: 0) {
                        typeTab("Expense", .expense)
                        typeTab("Income", .income)
                    }
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        TextField("e.g. Grocery Store", text: $vm.newTitle)
                            .font(AppFont.body()).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amount").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack {
                            Text("$").foregroundStyle(Color.theme.textTertiary)
                            TextField("0.00", text: $vm.newAmount).keyboardType(.decimalPad)
                        }
                        .font(AppFont.body()).padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
                    }
                    
                    if vm.newType == .expense {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(SpendingCategory.allCases, id: \.self) { cat in
                                    Button { vm.newCategory = cat } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon).font(.system(size: 11))
                                            Text(cat.rawValue).font(AppFont.caption(11))
                                        }
                                        .foregroundStyle(vm.newCategory == cat ? .white : Color.theme.textSecondary)
                                        .padding(.horizontal, 10).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(vm.newCategory == cat ? Color.theme.categoryColor(for: cat) : Color.theme.surfaceAlt))
                                    }
                                }
                            }
                        }
                    }
                    
                    DatePicker("Date", selection: $vm.newDate, displayedComponents: .date)
                        .font(AppFont.body())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note (optional)").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        TextField("Add a note...", text: $vm.newNote)
                            .font(AppFont.body()).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.addTransaction()
                    } label: {
                        Text("Add \(vm.newType.rawValue)").primaryButton()
                    }
                }
                .padding(24)
            }
            .background(Color.theme.background)
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { vm.showAddSheet = false }
                }
            }
        }
    }
    
    private func typeTab(_ label: String, _ type: TransactionType) -> some View {
        Button { withAnimation { vm.newType = type } } label: {
            Text(label).font(AppFont.subhead(14))
                .foregroundStyle(vm.newType == type ? .white : Color.theme.textSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(vm.newType == type ? Color.theme.accent : .clear))
        }
    }
}
