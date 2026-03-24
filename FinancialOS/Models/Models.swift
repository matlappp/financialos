// Models.swift
// Financial.OS — Data Models

import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var monthlyNetIncome: Double
    var grossIncome: Double
    var payFrequency: PayFrequency
    var estimatedTaxRate: Double
    var createdAt: Date
    
    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String { String(firstName.prefix(1)) + String(lastName.prefix(1)) }
    
    init(id: UUID = UUID(), firstName: String = "", lastName: String = "",
         email: String = "", monthlyNetIncome: Double = 0, grossIncome: Double = 0,
         payFrequency: PayFrequency = .biweekly, estimatedTaxRate: Double = 0.25, createdAt: Date = Date()) {
        self.id = id; self.firstName = firstName; self.lastName = lastName
        self.email = email; self.monthlyNetIncome = monthlyNetIncome
        self.grossIncome = grossIncome; self.payFrequency = payFrequency
        self.estimatedTaxRate = estimatedTaxRate; self.createdAt = createdAt
    }
}

enum PayFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case semimonthly = "Semi-Monthly"
    case monthly = "Monthly"
    
    var multiplier: Double {
        switch self {
        case .weekly: return 52.0/12.0
        case .biweekly: return 26.0/12.0
        case .semimonthly: return 2.0
        case .monthly: return 1.0
        }
    }
}

// MARK: - Financial Questionnaire
struct FinancialQuestionnaire: Codable {
    var financialGoal: String = ""
    var goalAmount: Double = 0
    var timeFrame: GoalTimeFrame = .sixMonths
    var currentSavings: Double = 0
    var monthlyFixedExpenses: Double = 0
    var monthlyDebt: Double = 0
    var debtTypes: [DebtType] = []
    var dependents: Int = 0
    var housingType: HousingType = .renting
    var monthlyRent: Double = 0
    var hasEmergencyFund: Bool = false
    var emergencyFundAmount: Double = 0
    var investmentExperience: InvestmentExperience = .none
    var riskTolerance: RiskTolerance = .moderate
    var additionalNotes: String = ""
}

enum GoalTimeFrame: String, Codable, CaseIterable {
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case nineMonths = "9 Months"
    case twelveMonths = "12 Months"
    case eighteenMonths = "18 Months"
    case twentyFourMonths = "24 Months"
    var months: Int {
        switch self {
        case .threeMonths: return 3; case .sixMonths: return 6; case .nineMonths: return 9
        case .twelveMonths: return 12; case .eighteenMonths: return 18; case .twentyFourMonths: return 24
        }
    }
}

enum DebtType: String, Codable, CaseIterable {
    case creditCard = "Credit Card"; case studentLoan = "Student Loan"
    case carLoan = "Car Loan"; case mortgage = "Mortgage"
    case personalLoan = "Personal Loan"; case medicalDebt = "Medical"
    case other = "Other"
}

enum HousingType: String, Codable, CaseIterable {
    case renting = "Renting"; case owning = "Homeowner"
    case livingWithFamily = "With Family"; case other = "Other"
}

enum InvestmentExperience: String, Codable, CaseIterable {
    case none = "None"; case beginner = "Beginner"
    case intermediate = "Intermediate"; case advanced = "Advanced"
}

enum RiskTolerance: String, Codable, CaseIterable {
    case conservative = "Conservative"; case moderate = "Moderate"; case aggressive = "Aggressive"
}

// MARK: - Financial Plan (AI Generated)
struct FinancialPlan: Codable, Identifiable {
    let id: UUID
    var title: String
    var summary: String
    var monthlyBudget: MonthlyBudget
    var milestones: [Milestone]
    var recommendations: [Recommendation]
    var weeklyActions: [WeeklyAction]
    var projections: [MonthlyProjection]
    var goalAmount: Double
    var timeFrameMonths: Int
    var createdAt: Date
    
    var progressPercent: Double {
        guard goalAmount > 0 else { return 0 }
        let saved = projections.filter { $0.month <= currentMonth }.last?.cumulativeSavings ?? 0
        return min(saved / goalAmount, 1.0)
    }
    
    private var currentMonth: Int {
        let months = Calendar.current.dateComponents([.month], from: createdAt, to: Date()).month ?? 0
        return months + 1
    }
    
    init(id: UUID = UUID(), title: String = "", summary: String = "",
         monthlyBudget: MonthlyBudget = MonthlyBudget(), milestones: [Milestone] = [],
         recommendations: [Recommendation] = [], weeklyActions: [WeeklyAction] = [],
         projections: [MonthlyProjection] = [], goalAmount: Double = 0,
         timeFrameMonths: Int = 6, createdAt: Date = Date()) {
        self.id = id; self.title = title; self.summary = summary
        self.monthlyBudget = monthlyBudget; self.milestones = milestones
        self.recommendations = recommendations; self.weeklyActions = weeklyActions
        self.projections = projections; self.goalAmount = goalAmount
        self.timeFrameMonths = timeFrameMonths; self.createdAt = createdAt
    }
}

struct MonthlyBudget: Codable {
    var income: Double = 0; var housing: Double = 0; var food: Double = 0
    var transport: Double = 0; var utilities: Double = 0; var entertainment: Double = 0
    var savings: Double = 0; var debtPayment: Double = 0; var miscellaneous: Double = 0
    var totalExpenses: Double { housing + food + transport + utilities + entertainment + debtPayment + miscellaneous }
    var remaining: Double { income - totalExpenses - savings }
}

struct Milestone: Codable, Identifiable {
    let id: UUID; var title: String; var targetDate: Date; var targetAmount: Double; var isCompleted: Bool
    init(id: UUID = UUID(), title: String, targetDate: Date, targetAmount: Double, isCompleted: Bool = false) {
        self.id = id; self.title = title; self.targetDate = targetDate; self.targetAmount = targetAmount; self.isCompleted = isCompleted
    }
}

struct Recommendation: Codable, Identifiable {
    let id: UUID; var title: String; var description: String; var category: String; var potentialSavings: Double; var priority: String
    init(id: UUID = UUID(), title: String, description: String, category: String = "Savings", potentialSavings: Double = 0, priority: String = "Medium") {
        self.id = id; self.title = title; self.description = description; self.category = category; self.potentialSavings = potentialSavings; self.priority = priority
    }
}

struct WeeklyAction: Codable, Identifiable {
    let id: UUID; var weekNumber: Int; var tasks: [String]; var isCompleted: Bool
    init(id: UUID = UUID(), weekNumber: Int, tasks: [String], isCompleted: Bool = false) {
        self.id = id; self.weekNumber = weekNumber; self.tasks = tasks; self.isCompleted = isCompleted
    }
}

struct MonthlyProjection: Codable, Identifiable {
    let id: UUID; var month: Int; var projectedSavings: Double; var cumulativeSavings: Double
    init(id: UUID = UUID(), month: Int, projectedSavings: Double, cumulativeSavings: Double) {
        self.id = id; self.month = month; self.projectedSavings = projectedSavings; self.cumulativeSavings = cumulativeSavings
    }
}

// MARK: - Transactions
struct Transaction: Codable, Identifiable {
    let id: UUID; var title: String; var amount: Double; var category: SpendingCategory
    var type: TransactionType; var date: Date; var note: String?
    init(id: UUID = UUID(), title: String, amount: Double, category: SpendingCategory,
         type: TransactionType, date: Date = Date(), note: String? = nil) {
        self.id = id; self.title = title; self.amount = amount; self.category = category
        self.type = type; self.date = date; self.note = note
    }
}

enum TransactionType: String, Codable { case expense = "Expense"; case income = "Income" }

enum SpendingCategory: String, Codable, CaseIterable {
    case food = "Groceries"; case restaurant = "Restaurants"; case transport = "Transport"
    case housing = "Housing"; case utilities = "Utilities"; case entertainment = "Entertainment"
    case shopping = "Shopping"; case health = "Health"; case education = "Education"
    case savings = "Savings"; case debt = "Debt Payment"; case subscription = "Subscriptions"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "cart.fill"; case .restaurant: return "fork.knife"
        case .transport: return "car.fill"; case .housing: return "house.fill"
        case .utilities: return "bolt.fill"; case .entertainment: return "gamecontroller.fill"
        case .shopping: return "bag.fill"; case .health: return "heart.fill"
        case .education: return "book.fill"; case .savings: return "banknote.fill"
        case .debt: return "creditcard.fill"; case .subscription: return "arrow.triangle.2.circlepath"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Calendar Bills & Subscriptions
struct CalendarBill: Codable, Identifiable {
    let id: UUID; var title: String; var amount: Double; var dueDate: Date
    var recurrence: BillRecurrence; var category: BillCategory; var isPaid: Bool
    var reminderDaysBefore: Int; var iconName: String?
    
    init(id: UUID = UUID(), title: String, amount: Double, dueDate: Date,
         recurrence: BillRecurrence = .monthly, category: BillCategory = .subscription,
         isPaid: Bool = false, reminderDaysBefore: Int = 3, iconName: String? = nil) {
        self.id = id; self.title = title; self.amount = amount; self.dueDate = dueDate
        self.recurrence = recurrence; self.category = category; self.isPaid = isPaid
        self.reminderDaysBefore = reminderDaysBefore; self.iconName = iconName
    }
    
    var nextDueDate: Date {
        let cal = Calendar.current; var d = dueDate
        while d < Date() {
            switch recurrence {
            case .weekly: d = cal.date(byAdding: .weekOfYear, value: 1, to: d) ?? d
            case .biweekly: d = cal.date(byAdding: .weekOfYear, value: 2, to: d) ?? d
            case .monthly: d = cal.date(byAdding: .month, value: 1, to: d) ?? d
            case .quarterly: d = cal.date(byAdding: .month, value: 3, to: d) ?? d
            case .yearly: d = cal.date(byAdding: .year, value: 1, to: d) ?? d
            case .oneTime: return d
            }
        }
        return d
    }
    
    var urgencyLevel: UrgencyLevel {
        let days = nextDueDate.daysFromNow
        if days < 0 { return .overdue }
        if days <= 3 { return .urgent }
        if days <= 7 { return .soon }
        return .normal
    }
}

enum UrgencyLevel { case overdue, urgent, soon, normal }

enum BillRecurrence: String, Codable, CaseIterable {
    case weekly = "Weekly"; case biweekly = "Bi-Weekly"; case monthly = "Monthly"
    case quarterly = "Quarterly"; case yearly = "Yearly"; case oneTime = "One-Time"
}

enum BillCategory: String, Codable, CaseIterable {
    case subscription = "Subscription"; case creditCard = "Credit Card"
    case rent = "Rent / Mortgage"; case insurance = "Insurance"
    case utility = "Utility"; case loan = "Loan"
    case phone = "Phone"; case internet = "Internet"; case other = "Other"
    
    var icon: String {
        switch self {
        case .subscription: return "play.rectangle.fill"; case .creditCard: return "creditcard.fill"
        case .rent: return "house.fill"; case .insurance: return "shield.fill"
        case .utility: return "bolt.fill"; case .loan: return "banknote.fill"
        case .phone: return "iphone"; case .internet: return "wifi"; case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - AI Chat
struct ChatMessage: Identifiable {
    let id: UUID; var content: String; var isUser: Bool; var timestamp: Date
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id; self.content = content; self.isUser = isUser; self.timestamp = timestamp
    }
}
