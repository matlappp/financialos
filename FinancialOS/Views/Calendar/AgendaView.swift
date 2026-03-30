// AgendaView.swift — Enhanced: period filter, auto-show on date click, personal notes, prediction, bill list
import SwiftUI
struct AgendaView: View {
    @EnvironmentObject var vm: AgendaVM; @EnvironmentObject var appState: AppState
    private var fr: Bool { ThemeManager.shared.language == .fr }
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 18) { summaryRow; predictionCard; periodFilter; calendarGrid; dateDetail; upcomingSection; allBillsList }.padding(.bottom, 40) }
        .background(Color.theme.background).navigationTitle(L10n.agenda)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { vm.showAddSheet = true } label: { Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(Color.theme.accent) } } }
        .sheet(isPresented: $vm.showAddSheet) { addSheet }
        .sheet(item: $vm.showBillDetail) { bill in billDetailSheet(bill) }
    }
    // MARK: - Summary
    private var summaryRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) { Text(L10n.monthlyBills).sectionLabel(); Text(vm.monthlyTotal.asCurrency).font(AppFont.currency(26)).foregroundStyle(Color.theme.primary) }; Spacer()
            VStack(alignment: .trailing, spacing: 4) { Text(L10n.upcoming).sectionLabel(); Text("\(vm.upcomingBills.count) \(fr ? "factures" : "bills")").font(AppFont.heading()).foregroundStyle(Color.theme.accent) }
        }.padding(18).card().padding(.horizontal, 20)
    }
    // MARK: - Prediction
    private var predictionCard: some View {
        Group { if let user = appState.user {
            let pred = AIService.shared.predictMonthEnd(income: user.monthlyNetIncome, transactions: [], bills: vm.bills)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) { Image(systemName: "wand.and.stars").foregroundStyle(pred < 0 ? Color.theme.danger : Color.theme.success)
                    Text(fr ? "PRÉDICTION FIN DE MOIS" : "MONTH-END PREDICTION").sectionLabel() }
                Text(pred.asCurrency).font(AppFont.currency(24)).foregroundStyle(pred < 0 ? Color.theme.danger : Color.theme.success)
                Text(pred < 0 ? (fr ? "⚠️ Attention, c'est serré ce mois-ci!" : "⚠️ Warning, it's tight this month!") : (fr ? "✅ Tu es en bonne voie!" : "✅ You're on track!"))
                    .font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary)
            }.padding(16).card().padding(.horizontal, 20)
        }}
    }
    // MARK: - Period Filter
    private var periodFilter: some View {
        HStack(spacing: 6) { ForEach(AgendaVM.AgendaPeriod.allCases, id: \.self) { p in
            Button { withAnimation { vm.selectedPeriod = p } } label: { Text(p.label).font(AppFont.caption(12)).foregroundStyle(vm.selectedPeriod==p ? .white : Color.theme.textSecondary).padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(vm.selectedPeriod==p ? Color.theme.accent : Color.theme.surfaceAlt)) }
        }}.padding(.horizontal, 20)
    }
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 12) {
            HStack { Button { vm.prevMonth() } label: { Image(systemName: "chevron.left").foregroundStyle(Color.theme.textSecondary) }; Spacer()
                Text(vm.currentMonth.monthYear).font(AppFont.subhead()); Spacer()
                Button { vm.nextMonth() } label: { Image(systemName: "chevron.right").foregroundStyle(Color.theme.textSecondary) } }
            HStack { ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in Text(d).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary).frame(maxWidth: .infinity) } }
            let days = calDays
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 5) {
                ForEach(days, id: \.self) { d in if let date = d { dayCell(date) } else { Color.clear.frame(height: 40) } }
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private func dayCell(_ d: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(d); let isSel = Calendar.current.isDate(d, inSameDayAs: vm.selectedDate)
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; let hasBill = vm.datesWithBills.contains(f.string(from: d))
        return Button { withAnimation(.spring(response: 0.3)) { vm.selectedDate = d } } label: {
            VStack(spacing: 3) { Text(d.dayNumber).font(AppFont.body(14)).foregroundStyle(isSel ? .white : isToday ? Color.theme.accent : Color.theme.textPrimary)
                Circle().fill(hasBill ? (isSel ? .white : Color.theme.accent) : .clear).frame(width: 5, height: 5) }
            .frame(maxWidth: .infinity).frame(height: 40).background(RoundedRectangle(cornerRadius: 9).fill(isSel ? Color.theme.accent : isToday ? Color.theme.accentSoft : .clear))
        }
    }
    private var calDays: [Date?] {
        let c = Calendar.current; let r = c.range(of: .day, in: .month, for: vm.currentMonth)!
        let first = c.date(from: c.dateComponents([.year,.month], from: vm.currentMonth))!
        let sw = c.component(.weekday, from: first) - 1
        var d: [Date?] = Array(repeating: nil, count: sw)
        for day in r { if let date = c.date(byAdding: .day, value: day-1, to: first) { d.append(date) } }
        while d.count % 7 != 0 { d.append(nil) }; return d
    }
    // MARK: - Date Detail (Auto-display on click)
    private var dateDetail: some View {
        Group {
            let billsOnDate = vm.billsForDate
            if !billsOnDate.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(vm.selectedDate.dayMonth) — \(fr ? "Paiements" : "Payments")").font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                    ForEach(billsOnDate) { b in
                        Button { vm.showBillDetail = b } label: { billRow(b, showUrgency: true) }
                    }
                }.padding(16).card().padding(.horizontal, 20).transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
    }
    // MARK: - Upcoming
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(L10n.comingUp).sectionLabel(); Spacer(); Text(vm.selectedPeriod.label).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary) }
            if vm.upcomingBills.isEmpty { HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.theme.success)
                Text(fr ? "Tout est clair! Aucune facture à venir." : "All clear! No bills due soon.").font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary) }.padding(.vertical, 14) }
            else { ForEach(vm.upcomingBills) { b in Button { vm.showBillDetail = b } label: { billRow(b, showUrgency: true) } } }
        }.padding(18).card().padding(.horizontal, 20)
    }
    // MARK: - Bills List (Always visible)
    private var allBillsList: some View {
        VStack(alignment: .leading, spacing: 12) { Text(L10n.billsList).sectionLabel()
            ForEach(vm.bills.sorted { $0.nextDueDate < $1.nextDueDate }) { b in
                HStack(spacing: 12) {
                    ZStack { RoundedRectangle(cornerRadius: 9).fill(catColor(b.category).opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: b.iconName ?? b.category.icon).font(.system(size: 15)).foregroundStyle(catColor(b.category)) }
                    VStack(alignment: .leading, spacing: 2) { Text(b.title).font(AppFont.subhead(14)); HStack(spacing: 4) { Text(b.nextDueDate.dayMonth).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                        if b.autoDeduct { Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 9)).foregroundStyle(Color.theme.info) }
                        Text(b.recurrence.rawValue).font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary) } }; Spacer()
                    Text(b.amount.asCurrency).font(AppFont.subhead(14))
                    Button { withAnimation { vm.togglePaid(b) } } label: { Image(systemName: b.isPaid ? "checkmark.circle.fill" : "circle").font(.system(size: 20)).foregroundStyle(b.isPaid ? Color.theme.success : Color.theme.textTertiary) }
                }.padding(.vertical, 5)
                .swipeActions(edge: .trailing) { Button(role: .destructive) { vm.delete(b) } label: { Label(L10n.delete, systemImage: "trash") } }
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private func billRow(_ b: CalendarBill, showUrgency: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack { RoundedRectangle(cornerRadius: 9).fill(catColor(b.category).opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: b.iconName ?? b.category.icon).font(.system(size: 15)).foregroundStyle(catColor(b.category)) }
            VStack(alignment: .leading, spacing: 2) { Text(b.title).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                HStack(spacing: 4) { Text(b.nextDueDate.dayMonth).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                    if b.autoDeduct { Text(fr ? "Auto" : "Auto").font(AppFont.caption(9)).foregroundStyle(Color.theme.info).padding(.horizontal, 4).padding(.vertical, 1).background(Capsule().fill(Color.theme.info.opacity(0.1))) } } }; Spacer()
            VStack(alignment: .trailing, spacing: 2) { Text(b.amount.asCurrency).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                if showUrgency { urgBadge(b) } }
        }.padding(.vertical, 4)
    }
    private func urgBadge(_ b: CalendarBill) -> some View {
        let d = b.nextDueDate.daysFromNow; let t: String; let c: Color
        switch b.urgencyLevel { case .overdue: t = L10n.overdue; c = Color.theme.danger; case .urgent: t = d==0 ? L10n.today : "\(d)j"; c = Color.theme.danger
        case .soon: t = "\(d)j"; c = Color.theme.warning; case .normal: t = "\(d)j"; c = Color.theme.textTertiary }
        return Text(t).font(AppFont.caption(10)).foregroundStyle(c).padding(.horizontal, 5).padding(.vertical, 2).background(Capsule().fill(c.opacity(0.1)))
    }
    private func catColor(_ c: BillCategory) -> Color {
        switch c { case .subscription: return Color.theme.subscription; case .creditCard: return Color.theme.danger; case .rent: return Color.theme.housing
        case .insurance: return Color.theme.info; case .utility: return Color.theme.utilities; case .loan: return Color.theme.debt
        case .phone: return Color.theme.transport; case .internet: return Color.theme.info; case .other: return Color.theme.textTertiary }
    }
    // MARK: - Bill Detail Sheet (Personal Note)
    private func billDetailSheet(_ bill: CalendarBill) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack { RoundedRectangle(cornerRadius: 16).fill(catColor(bill.category).opacity(0.12)).frame(width: 64, height: 64)
                    Image(systemName: bill.iconName ?? bill.category.icon).font(.system(size: 28)).foregroundStyle(catColor(bill.category)) }
                Text(bill.title).font(AppFont.title(22)); Text(bill.amount.asCurrency).font(AppFont.currency(28)).foregroundStyle(Color.theme.primary)
                HStack(spacing: 16) { VStack { Text(fr ? "Prochaine" : "Next Due").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary); Text(bill.nextDueDate.dayMonth).font(AppFont.subhead()) }
                    VStack { Text(fr ? "Récurrence" : "Recurrence").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary); Text(bill.recurrence.rawValue).font(AppFont.subhead()) }
                    VStack { Text("Status").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary); Text(bill.isPaid ? L10n.paid : L10n.upcoming).font(AppFont.subhead()).foregroundStyle(bill.isPaid ? Color.theme.success : Color.theme.warning) } }
                // Personal note
                VStack(alignment: .leading, spacing: 8) { Text(L10n.personalNote).sectionLabel()
                    TextEditor(text: Binding(get: { bill.personalNote ?? "" }, set: { vm.updateNote(bill, $0) }))
                        .font(AppFont.body(14)).frame(height: 100).padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
                }.padding(.horizontal, 24)
                Spacer()
            }.padding(.top, 30).background(Color.theme.background)
            .navigationTitle(fr ? "Détails" : "Details").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(L10n.cancel) { vm.showBillDetail = nil } } }
        }
    }
    // MARK: - Add Sheet
    private var addSheet: some View {
        NavigationStack { ScrollView { VStack(spacing: 16) {
            fld(fr ? "Nom" : "Name", $vm.newTitle, "e.g. Netflix, Visa..."); fld(fr ? "Montant" : "Amount", $vm.newAmount, "0.00", .decimalPad, "$")
            DatePicker(fr ? "Date d'échéance" : "Due Date", selection: $vm.newDate, displayedComponents: .date).font(AppFont.body(14))
            VStack(alignment: .leading, spacing: 6) { Text(fr ? "Récurrence" : "Recurrence").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 5) { ForEach(BillRecurrence.allCases, id: \.self) { r in
                    Button { vm.newRecurrence = r } label: { Text(r.rawValue).font(AppFont.caption(11)).foregroundStyle(vm.newRecurrence==r ? .white : Color.theme.textSecondary).padding(.horizontal, 10).padding(.vertical, 7).background(Capsule().fill(vm.newRecurrence==r ? Color.theme.accent : Color.theme.surfaceAlt)) } } } } }
            VStack(alignment: .leading, spacing: 6) { Text(fr ? "Catégorie" : "Category").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 5)], spacing: 5) { ForEach(BillCategory.allCases, id: \.self) { c in
                    Button { vm.newCategory = c } label: { HStack(spacing: 3) { Image(systemName: c.icon).font(.system(size: 10)); Text(c.rawValue).font(AppFont.caption(10)) }.foregroundStyle(vm.newCategory==c ? .white : Color.theme.textSecondary).padding(.horizontal, 8).padding(.vertical, 6).background(RoundedRectangle(cornerRadius: 7).fill(vm.newCategory==c ? Color.theme.accent : Color.theme.surfaceAlt)) } } } }
            Toggle(fr ? "Déduction automatique" : "Auto-deduct from balance", isOn: $vm.newAutoDeduct).font(AppFont.body(14)).tint(Color.theme.accent)
            Stepper(fr ? "Rappel \(vm.newReminder) jour(s) avant" : "Remind \(vm.newReminder) day(s) before", value: $vm.newReminder, in: 1...14).font(AppFont.body(14))
            fld(L10n.personalNote, $vm.newNote, fr ? "Note optionnelle..." : "Optional note...")
            Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); vm.addBill() } label: { Text(L10n.addBill).primaryButton() }
        }.padding(22) }.background(Color.theme.background).navigationTitle(L10n.addBill).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(L10n.cancel) { vm.showAddSheet = false } } } }
    }
    private func fld(_ t: String, _ b: Binding<String>, _ ph: String, _ kb: UIKeyboardType = .default, _ pre: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(t).font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
            HStack { if let p = pre { Text(p).foregroundStyle(Color.theme.textTertiary) }; TextField(ph, text: b).keyboardType(kb) }.font(AppFont.body()).padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt)) }
    }
}
