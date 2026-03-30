// ViewModels.swift
// Financial.OS — All ViewModels (MVVM Enhanced V2)

import SwiftUI
import Combine

// MARK: - App State
class AppState: ObservableObject {
    @Published var screen: AppScreen = .landing
    @Published var selectedTab: AppTab = .roadmap
    @Published var user: UserProfile?
    @Published var plan: FinancialPlan?
    @Published var isOnboarded = false
    
    init() {
        if let u = DataStore.shared.load(UserProfile.self, key: "user") { user = u; isOnboarded = true; screen = .main }
        if let p = DataStore.shared.load(FinancialPlan.self, key: "plan") { plan = p }
    }
    
    func completeOnboarding(_ profile: UserProfile, _ plan: FinancialPlan) {
        user = profile; self.plan = plan; isOnboarded = true; screen = .main
        DataStore.shared.save(profile, key: "user"); DataStore.shared.save(plan, key: "plan")
    }
    
    func updateProfile(_ profile: UserProfile) { user = profile; DataStore.shared.save(profile, key: "user") }
    
    func logout() {
        user = nil; plan = nil; isOnboarded = false; screen = .landing
        ["user", "plan", "transactions", "bills"].forEach { DataStore.shared.clear($0) }
    }
}

enum AppScreen { case landing, onboarding, main }
enum AppTab: Int, CaseIterable {
    case roadmap = 0, workplace, agenda, growth, safeSpace, account
    var title: String {
        switch self {
        case .roadmap: return L10n.roadmap; case .workplace: return L10n.workplace
        case .agenda: return L10n.agenda; case .growth: return L10n.growth
        case .safeSpace: return L10n.safeSpace; case .account: return L10n.account
        }
    }
    var icon: String {
        switch self {
        case .roadmap: return "square.grid.2x2.fill"; case .workplace: return "bolt.fill"
        case .agenda: return "calendar"; case .growth: return "chart.line.uptrend.xyaxis"
        case .safeSpace: return "shield.fill"; case .account: return "person.circle.fill"
        }
    }
}

// MARK: - Onboarding VM (5-page questionnaire)
class OnboardingVM: ObservableObject {
    @Published var step: Step = .dataMethod
    @Published var isLoading = false
    
    // Profile
    @Published var firstName = ""; @Published var lastName = ""; @Published var email = ""
    @Published var grossText = ""; @Published var payFreq: PayFrequency = .biweekly
    @Published var netMonthly: Double = 0; @Published var taxRate: Double = 0
    @Published var dataMethod: DataEntryMethod = .manual
    
    // Questionnaire
    @Published var q = FinancialQuestionnaire()
    @Published var goalAmtText = ""; @Published var savingsText = ""
    @Published var rentText = ""; @Published var utilitiesText = ""; @Published var groceriesText = ""
    @Published var transportText = ""; @Published var phoneText = ""; @Published var internetText = ""
    @Published var debtText = ""; @Published var debtBalanceText = ""; @Published var interestRateText = ""
    @Published var carPaymentText = ""; @Published var carInsuranceText = ""
    @Published var dependentCostText = ""; @Published var addlIncomeText = ""
    @Published var emergencyFundAmtText = ""
    @Published var newInsurance = InsuranceInfo()
    @Published var newSubscription = SubscriptionInfo()
    
    @Published var generatedPlan: FinancialPlan?
    
    enum Step: Int, CaseIterable {
        case dataMethod = 0, profile, goals, housing, debtInsurance, savingsSubs, processing, review
        var title: String {
            let fr = ThemeManager.shared.language == .fr
            switch self {
            case .dataMethod: return fr ? "Méthode" : "Method"
            case .profile: return fr ? "Revenus" : "Income"
            case .goals: return fr ? "Objectifs" : "Goals"
            case .housing: return fr ? "Logement" : "Housing"
            case .debtInsurance: return fr ? "Dettes & Assurance" : "Debt & Insurance"
            case .savingsSubs: return fr ? "Épargne" : "Savings"
            case .processing: return fr ? "Analyse..." : "Analyzing..."
            case .review: return fr ? "Votre Plan" : "Your Plan"
            }
        }
    }
    
    var progress: Double { Double(step.rawValue) / Double(Step.allCases.count - 1) }
    
    func calcIncome() {
        guard let g = Double(grossText.replacingOccurrences(of: ",", with: "")) else { return }
        let r = AIService.shared.calculateNetIncome(gross: g, frequency: payFreq)
        netMonthly = r.net; taxRate = r.taxRate
    }
    
    var canProceedProfile: Bool { !firstName.isEmpty && netMonthly > 0 }
    var canProceedGoals: Bool { !q.financialGoal.isEmpty && (Double(goalAmtText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0 }
    
    func next() { guard let n = Step(rawValue: step.rawValue + 1) else { return }; withAnimation(.spring(response: 0.4)) { step = n } }
    func back() { guard let p = Step(rawValue: step.rawValue - 1) else { return }; withAnimation(.spring(response: 0.4)) { step = p } }
    
    func addInsurance() {
        q.insuranceTypes.append(newInsurance); newInsurance = InsuranceInfo()
    }
    func addSubscription() {
        q.monthlySubscriptions.append(newSubscription); newSubscription = SubscriptionInfo()
    }
    
    func parseAllFields() {
        q.goalAmount = Double(goalAmtText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.currentSavings = Double(savingsText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyRent = Double(rentText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyUtilities = Double(utilitiesText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyGroceries = Double(groceriesText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyTransport = Double(transportText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyPhone = Double(phoneText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyInternet = Double(internetText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyDebt = Double(debtText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.totalDebtBalance = Double(debtBalanceText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.highestInterestRate = Double(interestRateText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyCarPayment = Double(carPaymentText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyCarInsurance = Double(carInsuranceText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyDependentCost = Double(dependentCostText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.additionalIncomeAmount = Double(addlIncomeText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.emergencyFundAmount = Double(emergencyFundAmtText.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    func generatePlan() async -> (UserProfile, FinancialPlan)? {
        parseAllFields()
        let gross = Double(grossText.replacingOccurrences(of: ",", with: "")) ?? 0
        let profile = UserProfile(firstName: firstName, lastName: lastName, email: email,
                                  monthlyNetIncome: netMonthly, grossIncome: gross,
                                  payFrequency: payFreq, estimatedTaxRate: taxRate, dataEntryMethod: dataMethod)
        do {
            let plan = try await AIService.shared.generatePlan(profile: profile, q: q)
            await MainActor.run { self.generatedPlan = plan }
            return (profile, plan)
        } catch { return nil }
    }
}

// MARK: - Dashboard VM
class DashboardVM: ObservableObject {
    @Published var expandedRec: UUID?
}

// MARK: - Workplace VM (Enhanced: bigger cards, period dropdown, scrollable categories)
class WorkplaceVM: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var showAddSheet = false
    @Published var selectedPeriod: TimePeriod = .thisMonth
    @Published var selectedCategory: SpendingCategory?
    
    @Published var newTitle = ""; @Published var newAmount = ""; @Published var newCategory: SpendingCategory = .other
    @Published var newType: TransactionType = .expense; @Published var newDate = Date(); @Published var newNote = ""
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "1W"; case thisMonth = "1M"; case threeMonths = "3M"
        case sixMonths = "6M"; case all = "All"
        var label: String {
            let fr = ThemeManager.shared.language == .fr
            switch self {
            case .thisWeek: return fr ? "1 Sem" : "1W"
            case .thisMonth: return fr ? "1 Mois" : "1M"
            case .threeMonths: return "3M"; case .sixMonths: return "6M"
            case .all: return fr ? "Tout" : "All"
            }
        }
    }
    
    init() { transactions = DataStore.shared.load([Transaction].self, key: "transactions") ?? Self.sampleData() }
    
    var filteredTransactions: [Transaction] {
        let cal = Calendar.current; let now = Date()
        return transactions.filter { t in
            let ok: Bool
            switch selectedPeriod {
            case .thisWeek: ok = cal.isDate(t.date, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth: ok = cal.isDate(t.date, equalTo: now, toGranularity: .month)
            case .threeMonths: ok = t.date >= cal.date(byAdding: .month, value: -3, to: now)!
            case .sixMonths: ok = t.date >= cal.date(byAdding: .month, value: -6, to: now)!
            case .all: ok = true
            }
            if let c = selectedCategory { return ok && t.category == c }
            return ok
        }.sorted { $0.date > $1.date }
    }
    
    var totalIncome: Double { filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var balance: Double { totalIncome - totalExpenses }
    var categoryBreakdown: [(SpendingCategory, Double)] {
        var m: [SpendingCategory: Double] = [:]
        filteredTransactions.filter { $0.type == .expense }.forEach { m[$0.category, default: 0] += $0.amount }
        return m.sorted { $0.value > $1.value }
    }
    
    func addTransaction() {
        guard let a = Double(newAmount.replacingOccurrences(of: ",", with: "")), !newTitle.isEmpty else { return }
        transactions.append(Transaction(title: newTitle, amount: a, category: newCategory, type: newType, date: newDate, note: newNote.isEmpty ? nil : newNote))
        save(); newTitle = ""; newAmount = ""; newNote = ""; showAddSheet = false
    }
    func delete(_ t: Transaction) { transactions.removeAll { $0.id == t.id }; save() }
    func save() { DataStore.shared.save(transactions, key: "transactions") }
    
    static func sampleData() -> [Transaction] {
        let c = Calendar.current; let n = Date()
        return [
            Transaction(title: "Épicerie IGA", amount: 87.50, category: .food, type: .expense, date: c.date(byAdding: .day, value: -1, to: n)!),
            Transaction(title: "Salaire Mensuel", amount: 3200, category: .other, type: .income, date: c.date(byAdding: .day, value: -3, to: n)!),
            Transaction(title: "Netflix", amount: 15.99, category: .subscription, type: .expense, date: c.date(byAdding: .day, value: -5, to: n)!),
            Transaction(title: "Essence", amount: 45.00, category: .transport, type: .expense, date: c.date(byAdding: .day, value: -2, to: n)!),
            Transaction(title: "Restaurant Le Local", amount: 62.30, category: .restaurant, type: .expense, date: c.date(byAdding: .day, value: -4, to: n)!),
            Transaction(title: "Hydro-Québec", amount: 120.00, category: .utilities, type: .expense, date: c.date(byAdding: .day, value: -7, to: n)!),
            Transaction(title: "Gym Membership", amount: 49.99, category: .health, type: .expense, date: c.date(byAdding: .day, value: -8, to: n)!),
            Transaction(title: "Freelance", amount: 500, category: .other, type: .income, date: c.date(byAdding: .day, value: -10, to: n)!),
            Transaction(title: "Café", amount: 12.50, category: .restaurant, type: .expense, date: n),
            Transaction(title: "Amazon", amount: 34.99, category: .shopping, type: .expense, date: c.date(byAdding: .day, value: -6, to: n)!),
            Transaction(title: "Spotify", amount: 10.99, category: .subscription, type: .expense, date: c.date(byAdding: .day, value: -12, to: n)!),
            Transaction(title: "Assurance Auto", amount: 95.00, category: .insurance, type: .expense, date: c.date(byAdding: .day, value: -14, to: n)!),
        ]
    }
}

// MARK: - Agenda VM (Enhanced: period filter, personal notes, auto-deduct, prediction)
class AgendaVM: ObservableObject {
    @Published var bills: [CalendarBill] = []
    @Published var selectedDate = Date()
    @Published var showAddSheet = false
    @Published var currentMonth = Date()
    @Published var selectedPeriod: AgendaPeriod = .month
    @Published var showBillDetail: CalendarBill?
    @Published var editingNote = ""
    
    @Published var newTitle = ""; @Published var newAmount = ""; @Published var newDate = Date()
    @Published var newRecurrence: BillRecurrence = .monthly; @Published var newCategory: BillCategory = .subscription
    @Published var newReminder = 3; @Published var newAutoDeduct = false; @Published var newNote = ""
    
    enum AgendaPeriod: String, CaseIterable {
        case week = "1W"; case month = "1M"; case threeMonths = "3M"
        var label: String {
            let fr = ThemeManager.shared.language == .fr
            switch self {
            case .week: return fr ? "1 Sem" : "1 Week"
            case .month: return fr ? "1 Mois" : "1 Month"
            case .threeMonths: return fr ? "3 Mois" : "3 Months"
            }
        }
        var dateRange: (Date, Date) {
            let c = Calendar.current; let n = Date()
            switch self {
            case .week: return (n, c.date(byAdding: .weekOfYear, value: 1, to: n)!)
            case .month: return (n, c.date(byAdding: .month, value: 1, to: n)!)
            case .threeMonths: return (n, c.date(byAdding: .month, value: 3, to: n)!)
            }
        }
    }
    
    init() { bills = DataStore.shared.load([CalendarBill].self, key: "bills") ?? Self.sampleBills() }
    
    var upcomingBills: [CalendarBill] {
        let range = selectedPeriod.dateRange
        return bills.filter { !$0.isPaid && $0.nextDueDate >= range.0 && $0.nextDueDate <= range.1 }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    var billsForDate: [CalendarBill] { bills.filter { Calendar.current.isDate($0.nextDueDate, inSameDayAs: selectedDate) } }
    var monthlyTotal: Double { bills.filter { $0.recurrence != .oneTime }.reduce(0) { $0 + $1.amount } }
    var datesWithBills: Set<String> {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return Set(bills.map { f.string(from: $0.nextDueDate) })
    }
    
    func addBill() {
        guard let a = Double(newAmount.replacingOccurrences(of: ",", with: "")), !newTitle.isEmpty else { return }
        let b = CalendarBill(title: newTitle, amount: a, dueDate: newDate, recurrence: newRecurrence,
                             category: newCategory, reminderDaysBefore: newReminder, personalNote: newNote.isEmpty ? nil : newNote, autoDeduct: newAutoDeduct)
        bills.append(b); save(); NotificationService.shared.scheduleBillReminder(b)
        newTitle = ""; newAmount = ""; newNote = ""; showAddSheet = false
    }
    
    func togglePaid(_ b: CalendarBill) { if let i = bills.firstIndex(where: { $0.id == b.id }) { bills[i].isPaid.toggle(); save() } }
    func delete(_ b: CalendarBill) { NotificationService.shared.cancelReminder(b.id); bills.removeAll { $0.id == b.id }; save() }
    func updateNote(_ b: CalendarBill, _ note: String) { if let i = bills.firstIndex(where: { $0.id == b.id }) { bills[i].personalNote = note; save() } }
    func save() { DataStore.shared.save(bills, key: "bills") }
    func prevMonth() { currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }
    func nextMonth() { currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }
    
    static func sampleBills() -> [CalendarBill] {
        let c = Calendar.current; let n = Date()
        return [
            CalendarBill(title: "Netflix", amount: 15.99, dueDate: c.date(byAdding: .day, value: 5, to: n)!, category: .subscription, iconName: "play.rectangle.fill", autoDeduct: true),
            CalendarBill(title: "Spotify", amount: 10.99, dueDate: c.date(byAdding: .day, value: 12, to: n)!, category: .subscription, iconName: "music.note", autoDeduct: true),
            CalendarBill(title: "Visa", amount: 250.00, dueDate: c.date(byAdding: .day, value: 8, to: n)!, category: .creditCard, iconName: "creditcard.fill"),
            CalendarBill(title: "Loyer", amount: 1200.00, dueDate: c.date(byAdding: .day, value: 1, to: n)!, category: .rent, iconName: "house.fill", autoDeduct: true),
            CalendarBill(title: "Assurance Auto", amount: 180.00, dueDate: c.date(byAdding: .day, value: 15, to: n)!, category: .insurance, iconName: "car.fill"),
            CalendarBill(title: "Fido", amount: 65.00, dueDate: c.date(byAdding: .day, value: 20, to: n)!, category: .phone, iconName: "iphone", autoDeduct: true),
        ]
    }
}

// MARK: - AI Chat VM
class AIChatVM: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""; @Published var isTyping = false
    
    init() {
        let fr = ThemeManager.shared.language == .fr
        messages = [ChatMessage(content: fr
            ? "Salut! 👋 Je suis ton conseiller financier IA. Pense à moi comme un ami qui s'y connaît en finances. Qu'est-ce qui te préoccupe aujourd'hui?"
            : "Hey! 👋 I'm your AI financial advisor. Think of me as a friend who knows money. What's on your mind today?", isUser: false)]
    }
    
    func send(profile: UserProfile?, plan: FinancialPlan?, transactions: [Transaction], bills: [CalendarBill]) {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = inputText; inputText = ""
        messages.append(ChatMessage(content: text, isUser: true)); isTyping = true
        Task {
            do {
                let r = try await AIService.shared.chat(message: text, context: (profile, plan, transactions, bills))
                await MainActor.run { messages.append(ChatMessage(content: r, isUser: false)); isTyping = false }
            } catch { await MainActor.run { isTyping = false } }
        }
    }
}
