// AgendaView.swift
// Financial.OS — Agenda: Calendar + Bills + Subscriptions + Notifications

import SwiftUI

struct AgendaView: View {
    @EnvironmentObject var vm: AgendaVM
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                monthlySummary
                calendarGrid
                upcomingBillsSection
                allBillsList
            }
            .padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle("Agenda")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.showAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(Color.theme.accent)
                }
            }
        }
        .sheet(isPresented: $vm.showAddSheet) { addBillSheet }
    }
    
    // MARK: - Monthly Summary
    private var monthlySummary: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MONTHLY BILLS").sectionLabel()
                Text(vm.monthlyTotal.asCurrency).font(AppFont.currency(28)).foregroundStyle(Color.theme.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("UPCOMING").sectionLabel()
                Text("\(vm.upcomingBills.count) bills").font(AppFont.heading()).foregroundStyle(Color.theme.accent)
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 14) {
            // Month navigation
            HStack {
                Button { vm.goToPrevMonth() } label: {
                    Image(systemName: "chevron.left").foregroundStyle(Color.theme.textSecondary)
                }
                Spacer()
                Text(vm.currentMonth.monthYear).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                Spacer()
                Button { vm.goToNextMonth() } label: {
                    Image(systemName: "chevron.right").foregroundStyle(Color.theme.textSecondary)
                }
            }
            
            // Day headers
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            let days = calendarDays
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { date in
                    if let d = date {
                        calendarDayCell(d)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    private func calendarDayCell(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let hasBill = vm.datesWithBills.contains(f.string(from: date))
        
        return Button {
            withAnimation(.spring(response: 0.3)) { vm.selectedDate = date }
        } label: {
            VStack(spacing: 4) {
                Text(date.dayNumber)
                    .font(AppFont.body(14))
                    .foregroundStyle(isSelected ? .white : isToday ? Color.theme.accent : Color.theme.textPrimary)
                
                if hasBill {
                    Circle().fill(isSelected ? .white : Color.theme.accent).frame(width: 5, height: 5)
                } else {
                    Circle().fill(Color.clear).frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.theme.accent : isToday ? Color.theme.accentSoft : Color.clear)
            )
        }
    }
    
    private var calendarDays: [Date?] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: vm.currentMonth)!
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: vm.currentMonth))!
        let startWeekday = cal.component(.weekday, from: firstDay) - 1
        
        var days: [Date?] = Array(repeating: nil, count: startWeekday)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
    
    // MARK: - Selected Day Bills
    private var upcomingBillsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("COMING UP").sectionLabel()
                Spacer()
                Text("Next 30 days").font(AppFont.caption(12)).foregroundStyle(Color.theme.textTertiary)
            }
            
            let upcoming = vm.upcomingBills.filter { $0.nextDueDate.daysFromNow <= 30 }
            
            if upcoming.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.theme.success)
                    Text("All clear! No bills due soon.").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary)
                }.padding(.vertical, 16)
            } else {
                ForEach(upcoming) { bill in
                    billRow(bill, showUrgency: true)
                }
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    // MARK: - All Bills
    private var allBillsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ALL BILLS & SUBSCRIPTIONS").sectionLabel()
            
            ForEach(vm.bills.sorted { $0.nextDueDate < $1.nextDueDate }) { bill in
                billRow(bill, showUrgency: false)
            }
        }
        .padding(20).card().padding(.horizontal, 20)
    }
    
    private func billRow(_ bill: CalendarBill, showUrgency: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(billCategoryColor(bill.category).opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: bill.iconName ?? bill.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(billCategoryColor(bill.category))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.title).font(AppFont.subhead(15)).foregroundStyle(Color.theme.textPrimary)
                HStack(spacing: 6) {
                    Text(bill.nextDueDate.dayMonth).font(AppFont.caption(12)).foregroundStyle(Color.theme.textTertiary)
                    Text("•").foregroundStyle(Color.theme.textTertiary)
                    Text(bill.recurrence.rawValue).font(AppFont.caption(12)).foregroundStyle(Color.theme.textTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(bill.amount.asCurrency).font(AppFont.subhead(15)).foregroundStyle(Color.theme.textPrimary)
                if showUrgency {
                    urgencyBadge(bill)
                }
            }
            
            Button { withAnimation { vm.togglePaid(bill) } } label: {
                Image(systemName: bill.isPaid ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(bill.isPaid ? Color.theme.success : Color.theme.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { vm.delete(bill) } label: { Label("Delete", systemImage: "trash") }
        }
    }
    
    private func urgencyBadge(_ bill: CalendarBill) -> some View {
        let days = bill.nextDueDate.daysFromNow
        let text: String
        let color: Color
        
        switch bill.urgencyLevel {
        case .overdue: text = "Overdue"; color = Color.theme.danger
        case .urgent: text = days == 0 ? "Today" : "\(days)d left"; color = Color.theme.danger
        case .soon: text = "\(days)d left"; color = Color.theme.warning
        case .normal: text = "\(days)d"; color = Color.theme.textTertiary
        }
        
        return Text(text)
            .font(AppFont.caption(10))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.1)))
    }
    
    private func billCategoryColor(_ cat: BillCategory) -> Color {
        switch cat {
        case .subscription: return Color.theme.subscription
        case .creditCard: return Color.theme.danger
        case .rent: return Color.theme.housing
        case .insurance: return Color.theme.info
        case .utility: return Color.theme.utilities
        case .loan: return Color.theme.debt
        case .phone: return Color.theme.transport
        case .internet: return Color.theme.info
        case .other: return Color.theme.textTertiary
        }
    }
    
    // MARK: - Add Bill Sheet
    private var addBillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bill Name").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        TextField("e.g. Netflix, Visa Card...", text: $vm.newTitle)
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
                    
                    DatePicker("Due Date", selection: $vm.newDate, displayedComponents: .date).font(AppFont.body())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recurrence").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(BillRecurrence.allCases, id: \.self) { r in
                                    Button { vm.newRecurrence = r } label: {
                                        Text(r.rawValue).font(AppFont.caption(12))
                                            .foregroundStyle(vm.newRecurrence == r ? .white : Color.theme.textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(Capsule().fill(vm.newRecurrence == r ? Color.theme.accent : Color.theme.surfaceAlt))
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], spacing: 6) {
                            ForEach(BillCategory.allCases, id: \.self) { c in
                                Button { vm.newCategory = c } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: c.icon).font(.system(size: 11))
                                        Text(c.rawValue).font(AppFont.caption(11))
                                    }
                                    .foregroundStyle(vm.newCategory == c ? .white : Color.theme.textSecondary)
                                    .padding(.horizontal, 10).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(vm.newCategory == c ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Remind me \(vm.newReminder) day(s) before").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        Stepper("", value: $vm.newReminder, in: 1...14)
                            .labelsHidden()
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.addBill()
                    } label: { Text("Add Bill").primaryButton() }
                }
                .padding(24)
            }
            .background(Color.theme.background)
            .navigationTitle("Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { vm.showAddSheet = false }
                }
            }
        }
    }
}
