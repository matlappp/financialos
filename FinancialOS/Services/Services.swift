// Services.swift
// Financial.OS — AI Engine + Data Persistence + Notifications

import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - AI Service
class AIService {
    static let shared = AIService()
    
    func calculateNetIncome(gross: Double, frequency: PayFrequency) -> (net: Double, taxRate: Double) {
        let annual = gross * frequency.multiplier * 12
        // Federal brackets 2024
        let brackets: [(Double, Double)] = [(11600,0.10),(35550,0.12),(53375,0.22),(91400,0.24),(51775,0.32),(365625,0.35),(Double.infinity,0.37)]
        var tax = 0.0; var rem = annual
        for (width, rate) in brackets {
            let taxable = min(rem, width); tax += taxable * rate; rem -= taxable
            if rem <= 0 { break }
        }
        let fica = annual * 0.0765; let state = annual * 0.05
        let totalTax = tax + fica + state
        return ((annual - totalTax) / 12, totalTax / annual)
    }
    
    func generatePlan(profile: UserProfile, q: FinancialQuestionnaire) async throws -> FinancialPlan {
        try await Task.sleep(nanoseconds: 2_500_000_000)
        
        let income = profile.monthlyNetIncome
        let months = q.timeFrame.months
        let needed = max(0, q.goalAmount - q.currentSavings)
        let monthlyTarget = needed / Double(months)
        let after = income - monthlyTarget
        
        let budget = MonthlyBudget(
            income: income,
            housing: q.monthlyRent > 0 ? q.monthlyRent : after * 0.30,
            food: after * 0.12, transport: after * 0.08, utilities: after * 0.05,
            entertainment: after * 0.08, savings: monthlyTarget,
            debtPayment: q.monthlyDebt, miscellaneous: after * 0.05
        )
        
        // Milestones
        let cal = Calendar.current
        let milestoneInterval = max(1, months / 4)
        let milestones: [Milestone] = stride(from: milestoneInterval, through: months, by: milestoneInterval).map { m in
            Milestone(
                title: "Month \(m) Target",
                targetDate: cal.date(byAdding: .month, value: m, to: Date()) ?? Date(),
                targetAmount: monthlyTarget * Double(m) + q.currentSavings
            )
        }
        
        // Recommendations
        var recs: [Recommendation] = [
            Recommendation(title: "Automate Savings", description: "Set up auto-transfer of \(monthlyTarget.asCurrencyShort) on payday to a high-yield savings account.", category: "Savings", potentialSavings: monthlyTarget * 0.05, priority: "High"),
            Recommendation(title: "Meal Prep Strategy", description: "Cook at home 5 days/week. Budget \(budget.food.asCurrencyShort) monthly for groceries, limit dining out to weekends.", category: "Spending", potentialSavings: 200, priority: "Medium"),
            Recommendation(title: "Subscription Audit", description: "Review all recurring subscriptions. Cancel unused services — average person wastes $50-100/month.", category: "Spending", potentialSavings: 75, priority: "Medium"),
        ]
        if q.monthlyDebt > income * 0.15 {
            recs.insert(Recommendation(title: "Debt Avalanche", description: "Debt exceeds 15% of income. Pay minimums on all, then throw extra at highest-interest debt first.", category: "Debt", potentialSavings: q.monthlyDebt * 0.1, priority: "High"), at: 0)
        }
        if !q.hasEmergencyFund {
            recs.append(Recommendation(title: "Emergency Fund", description: "Build a $1,000 starter emergency fund before aggressive saving. Then grow to 3 months expenses.", category: "Savings", potentialSavings: 0, priority: "High"))
        }
        recs.append(Recommendation(title: "Income Boost", description: "An extra $300/month could accelerate your goal by \(max(1, months/6)) months. Consider freelancing or selling unused items.", category: "Income", potentialSavings: 300, priority: "Low"))
        
        // Weekly actions
        let actions: [WeeklyAction] = (1...min(months*4, 12)).map { w in
            let tasks: [String]
            switch w {
            case 1: tasks = ["Open high-yield savings account", "Set up automatic transfers", "List all subscriptions"]
            case 2: tasks = ["Create weekly meal plan", "Cancel unused subscriptions", "Track every expense"]
            case 3: tasks = ["Review week 1-2 spending", "Adjust budget categories", "Research cheaper insurance"]
            case 4: tasks = ["Month-end review vs targets", "Celebrate wins", "Plan next month"]
            default: tasks = ["Log daily transactions", "Weekly budget check-in", w % 4 == 0 ? "Monthly milestone review" : "Find one cost-saving opportunity"]
            }
            return WeeklyAction(weekNumber: w, tasks: tasks)
        }
        
        // Projections
        var cum = q.currentSavings
        let projections: [MonthlyProjection] = (1...months).map { m in
            cum += monthlyTarget
            return MonthlyProjection(month: m, projectedSavings: monthlyTarget, cumulativeSavings: cum)
        }
        
        let planTitle = q.goalAmount > 20000 ? "Capital Accumulation and Foundation Building" :
                        q.goalAmount > 10000 ? "Accelerated Savings Strategy" :
                        "Smart Savings Roadmap"
        
        return FinancialPlan(
            title: planTitle,
            summary: "Based on \(income.asCurrencyShort)/month net income, save \(monthlyTarget.asCurrencyShort)/month over \(months) months to reach \(q.goalAmount.asCurrencyShort). Current savings: \(q.currentSavings.asCurrencyShort) (\(String(format: "%.0f", (q.currentSavings/q.goalAmount)*100))% complete).",
            monthlyBudget: budget, milestones: milestones,
            recommendations: recs, weeklyActions: actions,
            projections: projections, goalAmount: q.goalAmount,
            timeFrameMonths: months
        )
    }
    
    func chat(message: String, context: (UserProfile?, FinancialPlan?, [Transaction])) async throws -> String {
        try await Task.sleep(nanoseconds: 800_000_000)
        let low = message.lowercased()
        
        if low.contains("budget") || low.contains("spend") {
            if let p = context.1 {
                return "📊 Your monthly budget breakdown:\n\n• Housing: \(p.monthlyBudget.housing.asCurrency)\n• Food: \(p.monthlyBudget.food.asCurrency)\n• Transport: \(p.monthlyBudget.transport.asCurrency)\n• Savings: \(p.monthlyBudget.savings.asCurrency)\n• Debt: \(p.monthlyBudget.debtPayment.asCurrency)\n\nTotal expenses: \(p.monthlyBudget.totalExpenses.asCurrency)\n\nWould you like me to optimize any category?"
            }
        }
        if low.contains("save") || low.contains("saving") {
            return "💰 Top savings strategies:\n\n1. Automate — transfer on payday before spending\n2. 24-hour rule — wait before non-essential purchases over $50\n3. Audit subscriptions — most people waste $50-100/month\n4. Meal prep — saves $200-400/month vs eating out\n5. Negotiate bills — call providers for better rates\n\nWhich area interests you most?"
        }
        if low.contains("invest") {
            return "📈 Investment priority order:\n\n1. Emergency fund (3-6 months expenses)\n2. Pay high-interest debt (>7% APR)\n3. Employer 401(k) match\n4. Roth IRA ($7,000/year limit)\n5. Taxable brokerage\n\nStart with index funds for broad market exposure. Want a specific allocation plan?"
        }
        if low.contains("rebuild") || low.contains("new plan") {
            return "🔄 I can rebuild your plan! Tell me:\n\n1. Has your income changed?\n2. New financial goals?\n3. Significant expense changes?\n\nShare what's different and I'll generate an updated strategy."
        }
        
        return "👋 I'm your Financial.OS AI advisor. I can help with:\n\n• Budget analysis & optimization\n• Savings strategies\n• Spending insights from your data\n• Plan adjustments\n• Investment guidance\n\nWhat would you like to explore?"
    }
}

// MARK: - Data Persistence
class DataStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    static let shared = DataStore()
    
    func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }
    
    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func clear(_ key: String) { UserDefaults.standard.removeObject(forKey: key) }
}

// MARK: - Notification Service
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    @Published var isAuthorized = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
            DispatchQueue.main.async { self.isAuthorized = ok }
        }
    }
    
    func scheduleBillReminder(_ bill: CalendarBill) {
        guard isAuthorized else { requestPermission(); return }
        
        let content = UNMutableNotificationContent()
        content.title = "💳 Payment Due Soon"
        content.body = "\(bill.title) — \(bill.amount.asCurrency) due in \(bill.reminderDaysBefore) day(s)"
        content.sound = .default
        
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -bill.reminderDaysBefore, to: bill.nextDueDate) else { return }
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: "bill-\(bill.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        
        // Due-day notification
        let dueContent = UNMutableNotificationContent()
        dueContent.title = "⚠️ Payment Due Today"
        dueContent.body = "\(bill.title) — \(bill.amount.asCurrency) is due today!"
        dueContent.sound = .default
        var dueComps = Calendar.current.dateComponents([.year,.month,.day], from: bill.nextDueDate)
        dueComps.hour = 9
        let dueTrigger = UNCalendarNotificationTrigger(dateMatching: dueComps, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "due-\(bill.id)", content: dueContent, trigger: dueTrigger))
    }
    
    func cancelReminder(_ billId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bill-\(billId)", "due-\(billId)"])
    }
}

