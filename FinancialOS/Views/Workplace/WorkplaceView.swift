// WorkplaceView.swift — Enhanced: bigger summary cards, scrollable categories, visual %
import SwiftUI
struct WorkplaceView: View {
    @EnvironmentObject var vm: WorkplaceVM; private var fr: Bool { ThemeManager.shared.language == .fr }
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 18) { summaryCards; periodSelector; categoryChart; billAutoDeductInfo; categoryScroll; transactionList }.padding(.bottom, 40) }
        .background(Color.theme.background).navigationTitle(L10n.workplace)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { vm.showAddSheet = true } label: { Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(Color.theme.accent) } } }
        .sheet(isPresented: $vm.showAddSheet) { addSheet }
    }
    // MARK: - BIG Summary Cards
    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                bigCard(L10n.income, vm.totalIncome, Color.theme.success, "arrow.down.circle.fill")
                bigCard(L10n.expenses, vm.totalExpenses, Color.theme.danger, "arrow.up.circle.fill")
            }
            bigCard(L10n.balance, vm.balance, vm.balance >= 0 ? Color.theme.success : Color.theme.danger, "dollarsign.circle.fill", full: true)
        }.padding(.horizontal, 20)
    }
    private func bigCard(_ t: String, _ a: Double, _ c: Color, _ i: String, full: Bool = false) -> some View {
        VStack(spacing: 10) {
            HStack { Image(systemName: i).font(.system(size: 22)).foregroundStyle(c); Spacer()
                Text(a >= 0 ? "+" : "").font(AppFont.caption(12)).foregroundStyle(c) + Text(String(format: "%.0f", vm.totalIncome > 0 ? (a/vm.totalIncome)*100 : 0)).font(AppFont.caption(12)).foregroundStyle(c) + Text("%").font(AppFont.caption(10)).foregroundStyle(c) }
            VStack(alignment: .leading, spacing: 3) { Text(t).font(AppFont.caption()).foregroundStyle(Color.theme.textTertiary)
                Text(a.asCurrency).font(AppFont.currency(full ? 28 : 22)).foregroundStyle(Color.theme.textPrimary) }
            .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(16).card()
    }
    // Period selector
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) { ForEach(WorkplaceVM.TimePeriod.allCases, id: \.self) { p in
                Button { withAnimation { vm.selectedPeriod = p } } label: { Text(p.label).font(AppFont.caption(12)).foregroundStyle(vm.selectedPeriod==p ? .white : Color.theme.textSecondary).padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(vm.selectedPeriod==p ? Color.theme.accent : Color.theme.surfaceAlt)) }
            }}.padding(.horizontal, 20)
        }
    }
    // Donut chart
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) { Text(L10n.spendingByCategory).sectionLabel()
            if vm.categoryBreakdown.isEmpty { Text(fr ? "Aucune dépense" : "No expenses yet").font(AppFont.body()).foregroundStyle(Color.theme.textTertiary).frame(maxWidth: .infinity).padding(.vertical, 30) }
            else {
                HStack(spacing: 18) {
                    ZStack { ForEach(Array(donut.enumerated()), id: \.offset) { _, s in Circle().trim(from: s.0, to: s.1).stroke(s.2, style: StrokeStyle(lineWidth: 18, lineCap: .round)).rotationEffect(.degrees(-90)) }.frame(width: 120, height: 120)
                        VStack(spacing: 1) { Text(vm.totalExpenses.asCurrencyShort).font(AppFont.subhead(14)); Text("Total").font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary) } }
                    VStack(alignment: .leading, spacing: 6) { ForEach(vm.categoryBreakdown.prefix(5), id: \.0) { c, a in
                        HStack(spacing: 6) { Circle().fill(Color.theme.categoryColor(for: c)).frame(width: 7, height: 7); Text(c.rawValue).font(AppFont.caption(11)).foregroundStyle(Color.theme.textSecondary); Spacer()
                            Text("\(String(format:"%.0f",(a/vm.totalExpenses)*100))%").font(AppFont.caption(10)).bold().foregroundStyle(Color.theme.textPrimary)
                            Text(a.asCurrencyShort).font(AppFont.caption(11)).foregroundStyle(Color.theme.textPrimary) } } }
                }
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    private var donut: [(CGFloat,CGFloat,Color)] {
        guard vm.totalExpenses>0 else{return[]}; var s:[(CGFloat,CGFloat,Color)]=[]; var c:CGFloat=0
        for(cat,amt)in vm.categoryBreakdown{let f=CGFloat(amt/vm.totalExpenses);s.append((c,c+f-0.005,Color.theme.categoryColor(for:cat)));c+=f};return s
    }
    // Auto-deduct info
    private var billAutoDeductInfo: some View {
        Group {
            let auto = vm.transactions.filter { $0.isAutoDeducted }
            if !auto.isEmpty {
                HStack(spacing: 8) { Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundStyle(Color.theme.info)
                    Text(fr ? "\(auto.count) déductions automatiques ce mois" : "\(auto.count) auto-deductions this month").font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary); Spacer()
                    Text(auto.reduce(0){$0+$1.amount}.asCurrencyShort).font(AppFont.subhead(13)).foregroundStyle(Color.theme.info) }
                .padding(12).card().padding(.horizontal, 20)
            }
        }
    }
    // MARK: - Scrollable Category Menu
    private var categoryScroll: some View {
        VStack(alignment: .leading, spacing: 10) { Text(fr ? "CATÉGORIES" : "CATEGORIES").sectionLabel().padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    catChip(nil, fr ? "Tout" : "All", "square.grid.2x2.fill")
                    ForEach(SpendingCategory.allCases, id: \.self) { c in catChip(c, c.rawValue, c.icon) }
                }.padding(.horizontal, 20)
            }
        }
    }
    private func catChip(_ cat: SpendingCategory?, _ name: String, _ icon: String) -> some View {
        let sel = vm.selectedCategory == cat
        return Button { withAnimation { vm.selectedCategory = cat } } label: {
            HStack(spacing: 5) { Image(systemName: icon).font(.system(size: 11)); Text(name).font(AppFont.caption(11)) }
                .foregroundStyle(sel ? .white : Color.theme.textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(sel ? (cat != nil ? Color.theme.categoryColor(for: cat!) : Color.theme.accent) : Color.theme.surfaceAlt))
        }
    }
    // Transactions
    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 12) { HStack { Text(L10n.recentTransactions).sectionLabel(); Spacer()
            if vm.selectedCategory != nil { Button { withAnimation { vm.selectedCategory = nil } } label: { HStack(spacing: 3) { Text(fr ? "Effacer" : "Clear"); Image(systemName: "xmark.circle.fill") }.font(AppFont.caption(11)).foregroundStyle(Color.theme.accent) } } }
            ForEach(vm.filteredTransactions.prefix(25)) { t in
                HStack(spacing: 11) {
                    ZStack { RoundedRectangle(cornerRadius: 9).fill((t.type == .income ? Color.theme.success : Color.theme.categoryColor(for: t.category)).opacity(0.12)).frame(width: 38, height: 38)
                        Image(systemName: t.type == .income ? "arrow.down.left" : t.category.icon).font(.system(size: 13)).foregroundStyle(t.type == .income ? Color.theme.success : Color.theme.categoryColor(for: t.category)) }
                    VStack(alignment: .leading, spacing: 2) { Text(t.title).font(AppFont.body(14)); Text(t.date.dayMonth).font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary) }; Spacer()
                    Text("\(t.type == .income ? "+" : "-")\(t.amount.asCurrency)").font(AppFont.subhead(14)).foregroundStyle(t.type == .income ? Color.theme.success : Color.theme.textPrimary)
                }.padding(.vertical, 3)
                if t.id != vm.filteredTransactions.prefix(25).last?.id { Divider() }
            }
            if vm.filteredTransactions.isEmpty { Text(fr ? "Aucune transaction" : "No transactions").font(AppFont.body()).foregroundStyle(Color.theme.textTertiary).frame(maxWidth: .infinity).padding(.vertical, 24) }
        }.padding(18).card().padding(.horizontal, 20)
    }
    // MARK: - Add Sheet
    private var addSheet: some View {
        NavigationStack { ScrollView { VStack(spacing: 16) {
            HStack(spacing: 0) { tabBtn(fr ? "Dépense" : "Expense", .expense); tabBtn(fr ? "Revenu" : "Income", .income) }.background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
            fld(fr ? "Titre" : "Title", $vm.newTitle, "e.g. Épicerie"); fld(fr ? "Montant" : "Amount", $vm.newAmount, "0.00", .decimalPad, "$")
            if vm.newType == .expense { VStack(alignment: .leading, spacing: 6) { Text(fr ? "Catégorie" : "Category").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 6)], spacing: 6) { ForEach(SpendingCategory.allCases, id: \.self) { c in
                    Button { vm.newCategory = c } label: { HStack(spacing: 4) { Image(systemName: c.icon).font(.system(size: 10)); Text(c.rawValue).font(AppFont.caption(10)) }.foregroundStyle(vm.newCategory==c ? .white : Color.theme.textSecondary).padding(.horizontal, 8).padding(.vertical, 7).background(RoundedRectangle(cornerRadius: 7).fill(vm.newCategory==c ? Color.theme.categoryColor(for: c) : Color.theme.surfaceAlt)) } } } } }
            DatePicker(fr ? "Date" : "Date", selection: $vm.newDate, displayedComponents: .date).font(AppFont.body(14))
            fld(fr ? "Note" : "Note", $vm.newNote, fr ? "Optionnel..." : "Optional...")
            Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); vm.addTransaction() } label: { Text(L10n.add).primaryButton() }
        }.padding(22) }.background(Color.theme.background).navigationTitle(L10n.addTransaction).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(L10n.cancel) { vm.showAddSheet = false } } } }
    }
    private func tabBtn(_ l: String, _ t: TransactionType) -> some View {
        Button { withAnimation { vm.newType = t } } label: { Text(l).font(AppFont.subhead(13)).foregroundStyle(vm.newType==t ? .white : Color.theme.textSecondary).frame(maxWidth:.infinity).padding(.vertical,10).background(RoundedRectangle(cornerRadius:10).fill(vm.newType==t ? Color.theme.accent : .clear)) }
    }
    private func fld(_ t: String, _ b: Binding<String>, _ ph: String, _ kb: UIKeyboardType = .default, _ pre: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(t).font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
            HStack { if let p = pre { Text(p).foregroundStyle(Color.theme.textTertiary) }; TextField(ph, text: b).keyboardType(kb) }.font(AppFont.body()).padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt)) }
    }
}
