// ViewModels.swift
// Financial.OS — All ViewModels (MVVM)

import SwiftUI
import Combine

// MARK: - App State (Root)
class AppState: ObservableObject {
    @Published var screen: AppScreen = .landing
    @Published var selectedTab: AppTab = .roadmap
    @Published var user: UserProfile?
    @Published var plan: FinancialPlan?
    @Published var isOnboarded = false
    
    init() {
        if let u = DataStore.shared.load(UserProfile.self, key: "user") {
            user = u; isOnboarded = true; screen = .main
        }
        if let p = DataStore.shared.load(FinancialPlan.self, key: "plan") { plan = p }
    }
    
    func completeOnboarding(_ profile: UserProfile, _ plan: FinancialPlan) {
        user = profile; self.plan = plan; isOnboarded = true; screen = .main
        DataStore.shared.save(profile, key: "user")
        DataStore.shared.save(plan, key: "plan")
    }
    
    func logout() {
        user = nil; plan = nil; isOnboarded = false; screen = .landing
        DataStore.shared.clear("user"); DataStore.shared.clear("plan")
        DataStore.shared.clear("transactions"); DataStore.shared.clear("bills")
    }
}

enum AppScreen { case landing, onboarding, main }
enum AppTab: Int, CaseIterable {
    case roadmap = 0, workplace, agenda, growth, safeSpace
    var title: String {
        switch self {
        case .roadmap: return "AI Roadmap"; case .workplace: return "Workplace"
        case .agenda: return "Agenda"; case .growth: return "Growth"; case .safeSpace: return "SafeSpace"
        }
    }
    var icon: String {
        switch self {
        case .roadmap: return "square.grid.2x2.fill"; case .workplace: return "bolt.fill"
        case .agenda: return "calendar"; case .growth: return "chart.line.uptrend.xyaxis"
        case .safeSpace: return "shield.fill"
        }
    }
}

// MARK: - Onboarding ViewModel
class OnboardingVM: ObservableObject {
    @Published var step: OnboardingStep = .profile
    @Published var isLoading = false
    
    // Profile
    @Published var firstName = ""; @Published var lastName = ""; @Published var email = ""
    @Published var grossText = ""; @Published var payFreq: PayFrequency = .biweekly
    @Published var netMonthly: Double = 0; @Published var taxRate: Double = 0
    
    // Questionnaire
    @Published var q = FinancialQuestionnaire()
    @Published var goalAmtText = ""; @Published var savingsText = ""
    @Published var expensesText = ""; @Published var debtText = ""; @Published var rentText = ""
    
    @Published var generatedPlan: FinancialPlan?
    
    enum OnboardingStep: Int, CaseIterable {
        case profile = 0, goals, situation, processing, review
        var title: String {
            switch self { case .profile: return "Income"; case .goals: return "Goals"
            case .situation: return "Situation"; case .processing: return "Analyzing"
            case .review: return "Your Plan" }
        }
    }
    
    var progress: Double { Double(step.rawValue) / Double(OnboardingStep.allCases.count - 1) }
    
    func calcIncome() {
        guard let g = Double(grossText.replacingOccurrences(of: ",", with: "")) else { return }
        let r = AIService.shared.calculateNetIncome(gross: g, frequency: payFreq)
        netMonthly = r.net; taxRate = r.taxRate
    }
    
    var canProceedProfile: Bool { !firstName.isEmpty && netMonthly > 0 }
    var canProceedGoals: Bool { !q.financialGoal.isEmpty && (Double(goalAmtText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0 }
    
    func next() {
        guard let n = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.4)) { step = n }
    }
    func back() {
        guard let p = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.4)) { step = p }
    }
    
    func generatePlan() async -> (UserProfile, FinancialPlan)? {
        let gross = Double(grossText.replacingOccurrences(of: ",", with: "")) ?? 0
        let profile = UserProfile(firstName: firstName, lastName: lastName, email: email,
                                  monthlyNetIncome: netMonthly, grossIncome: gross,
                                  payFrequency: payFreq, estimatedTaxRate: taxRate)
        q.goalAmount = Double(goalAmtText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.currentSavings = Double(savingsText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyFixedExpenses = Double(expensesText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyDebt = Double(debtText.replacingOccurrences(of: ",", with: "")) ?? 0
        q.monthlyRent = Double(rentText.replacingOccurrences(of: ",", with: "")) ?? 0
        
        do {
            let plan = try await AIService.shared.generatePlan(profile: profile, q: q)
            await MainActor.run { self.generatedPlan = plan }
            return (profile, plan)
        } catch { return nil }
    }
}

// MARK: - Dashboard / Roadmap ViewModel
class DashboardVM: ObservableObject {
    @Published var selectedMilestone: Milestone?
    @Published var expandedRecommendation: UUID?
    
    var setupProgress: Double {
        1.0 // After onboarding, setup is complete
    }
}

// MARK: - Workplace ViewModel
class WorkplaceVM: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var showAddSheet = false
    @Published var selectedPeriod: TimePeriod = .thisMonth
    @Published var selectedCategory: SpendingCategory?
    
    // Add form
    @Published var newTitle = ""; @Published var newAmount = ""; @Published var newCategory: SpendingCategory = .other
    @Published var newType: TransactionType = .expense; @Published var newDate = Date(); @Published var newNote = ""
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "Week"; case thisMonth = "Month"; case threeMonths = "3M"; case all = "All"
    }
    
    init() { transactions = DataStore.shared.load([Transaction].self, key: "transactions") ?? sampleTransactions() }
    
    var filteredTransactions: [Transaction] {
        let cal = Calendar.current; let now = Date()
        return transactions.filter { t in
            let inPeriod: Bool
            switch selectedPeriod {
            case .thisWeek: inPeriod = cal.isDate(t.date, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth: inPeriod = cal.isDate(t.date, equalTo: now, toGranularity: .month)
            case .threeMonths: inPeriod = t.date >= cal.date(byAdding: .month, value: -3, to: now)!
            case .all: inPeriod = true
            }
            if let cat = selectedCategory { return inPeriod && t.category == cat }
            return inPeriod
        }.sorted { $0.date > $1.date }
    }
    
    var totalIncome: Double { filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var balance: Double { totalIncome - totalExpenses }
    
    var categoryBreakdown: [(SpendingCategory, Double)] {
        var map: [SpendingCategory: Double] = [:]
        filteredTransactions.filter { $0.type == .expense }.forEach { map[$0.category, default: 0] += $0.amount }
        return map.sorted { $0.value > $1.value }
    }
    
    func addTransaction() {
        guard let amt = Double(newAmount.replacingOccurrences(of: ",", with: "")), !newTitle.isEmpty else { return }
        let t = Transaction(title: newTitle, amount: amt, category: newCategory, type: newType, date: newDate, note: newNote.isEmpty ? nil : newNote)
        transactions.append(t); save()
        newTitle = ""; newAmount = ""; newNote = ""; newCategory = .other; showAddSheet = false
    }
    
    func delete(_ t: Transaction) { transactions.removeAll { $0.id == t.id }; save() }
    func save() { DataStore.shared.save(transactions, key: "transactions") }
    
    private func sampleTransactions() -> [Transaction] {
        let cal = Calendar.current; let now = Date()
        return [
            Transaction(title: "Grocery Store", amount: 87.50, category: .food, type: .expense, date: cal.date(byAdding: .day, value: -1, to: now)!),
            Transaction(title: "Monthly Salary", amount: 3200, category: .other, type: .income, date: cal.date(byAdding: .day, value: -3, to: now)!),
            Transaction(title: "Netflix", amount: 15.99, category: .subscription, type: .expense, date: cal.date(byAdding: .day, value: -5, to: now)!),
            Transaction(title: "Gas Station", amount: 45.00, category: .transport, type: .expense, date: cal.date(byAdding: .day, value: -2, to: now)!),
            Transaction(title: "Restaurant", amount: 62.30, category: .restaurant, type: .expense, date: cal.date(byAdding: .day, value: -4, to: now)!),
            Transaction(title: "Electric Bill", amount: 120.00, category: .utilities, type: .expense, date: cal.date(byAdding: .day, value: -7, to: now)!),
            Transaction(title: "Gym Membership", amount: 49.99, category: .health, type: .expense, date: cal.date(byAdding: .day, value: -8, to: now)!),
            Transaction(title: "Freelance Work", amount: 500, category: .other, type: .income, date: cal.date(byAdding: .day, value: -10, to: now)!),
            Transaction(title: "Coffee Shop", amount: 12.50, category: .restaurant, type: .expense, date: cal.date(byAdding: .day, value: 0, to: now)!),
            Transaction(title: "Amazon Order", amount: 34.99, category: .shopping, type: .expense, date: cal.date(byAdding: .day, value: -6, to: now)!),
        ]
    }
}

// MARK: - Calendar / Agenda ViewModel
class AgendaVM: ObservableObject {
    @Published var bills: [CalendarBill] = []
    @Published var selectedDate = Date()
    @Published var showAddSheet = false
    @Published var currentMonth = Date()
    
    // Add form
    @Published var newTitle = ""; @Published var newAmount = ""; @Published var newDate = Date()
    @Published var newRecurrence: BillRecurrence = .monthly; @Published var newCategory: BillCategory = .subscription
    @Published var newReminder = 3
    
    init() { bills = DataStore.shared.load([CalendarBill].self, key: "bills") ?? sampleBills() }
    
    var upcomingBills: [CalendarBill] {
        bills.filter { !$0.isPaid }.sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    var billsForSelectedDate: [CalendarBill] {
        bills.filter { Calendar.current.isDate($0.nextDueDate, inSameDayAs: selectedDate) }
    }
    
    var monthlyTotal: Double { bills.filter { $0.recurrence == .monthly || $0.recurrence == .biweekly || $0.recurrence == .weekly }.reduce(0) { $0 + $1.amount } }
    
    var datesWithBills: Set<String> {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return Set(bills.map { f.string(from: $0.nextDueDate) })
    }
    
    func addBill() {
        guard let amt = Double(newAmount.replacingOccurrences(of: ",", with: "")), !newTitle.isEmpty else { return }
        let b = CalendarBill(title: newTitle, amount: amt, dueDate: newDate, recurrence: newRecurrence, category: newCategory, reminderDaysBefore: newReminder)
        bills.append(b); save()
        NotificationService.shared.scheduleBillReminder(b)
        newTitle = ""; newAmount = ""; showAddSheet = false
    }
    
    func togglePaid(_ bill: CalendarBill) {
        guard let i = bills.firstIndex(where: { $0.id == bill.id }) else { return }
        bills[i].isPaid.toggle(); save()
    }
    
    func delete(_ bill: CalendarBill) {
        NotificationService.shared.cancelReminder(bill.id)
        bills.removeAll { $0.id == bill.id }; save()
    }
    
    func save() { DataStore.shared.save(bills, key: "bills") }
    
    func goToPrevMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    func goToNextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func sampleBills() -> [CalendarBill] {
        let cal = Calendar.current; let now = Date()
        return [
            CalendarBill(title: "Netflix", amount: 15.99, dueDate: cal.date(byAdding: .day, value: 5, to: now)!, category: .subscription, iconName: "play.rectangle.fill"),
            CalendarBill(title: "Spotify", amount: 10.99, dueDate: cal.date(byAdding: .day, value: 12, to: now)!, category: .subscription, iconName: "music.note"),
            CalendarBill(title: "Visa Credit Card", amount: 250.00, dueDate: cal.date(byAdding: .day, value: 8, to: now)!, category: .creditCard, iconName: "creditcard.fill"),
            CalendarBill(title: "Rent", amount: 1200.00, dueDate: cal.date(byAdding: .day, value: 1, to: now)!, category: .rent, iconName: "house.fill"),
            CalendarBill(title: "Car Insurance", amount: 180.00, dueDate: cal.date(byAdding: .day, value: 15, to: now)!, category: .insurance, iconName: "car.fill"),
            CalendarBill(title: "Phone Bill", amount: 65.00, dueDate: cal.date(byAdding: .day, value: 20, to: now)!, category: .phone, iconName: "iphone"),
        ]
    }
}

// MARK: - AI Chat ViewModel
class AIChatVM: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(content: "👋 Welcome to Financial.OS AI Advisor! I can help you with budgeting, savings strategies, spending analysis, and plan adjustments. What would you like to explore?", isUser: false)
    ]
    @Published var inputText = ""
    @Published var isTyping = false
    
    func send(profile: UserProfile?, plan: FinancialPlan?, transactions: [Transaction]) {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = inputText; inputText = ""
        messages.append(ChatMessage(content: text, isUser: true))
        isTyping = true
        
        Task {
            do {
                let response = try await AIService.shared.chat(message: text, context: (profile, plan, transactions))
                await MainActor.run { messages.append(ChatMessage(content: response, isUser: false)); isTyping = false }
            } catch {
                await MainActor.run { messages.append(ChatMessage(content: "Sorry, I encountered an error. Please try again.", isUser: false)); isTyping = false }
            }
        }
    }
}
