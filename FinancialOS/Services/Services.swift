// Services.swift
// Financial.OS — AI Engine (Human-like), Predictions, Data, Notifications

import Foundation
import UserNotifications
import Combine

// MARK: - AI Service (More Human Responses)
class AIService {
    static let shared = AIService()
    private var fr: Bool { ThemeManager.shared.language == .fr }
    
    func calculateNetIncome(gross: Double, frequency: PayFrequency) -> (net: Double, taxRate: Double) {
        let annual = gross * frequency.multiplier * 12
        let brackets: [(Double, Double)] = [(11600,0.10),(35550,0.12),(53375,0.22),(91400,0.24),(51775,0.32),(365625,0.35),(Double.infinity,0.37)]
        var tax = 0.0; var rem = annual
        for (w, r) in brackets { let t = min(rem, w); tax += t * r; rem -= t; if rem <= 0 { break } }
        let fica = annual * 0.0765; let state = annual * 0.05
        return ((annual - tax - fica - state) / 12, (tax + fica + state) / annual)
    }
    
    // MARK: - Month-End Prediction
    func predictMonthEnd(income: Double, transactions: [Transaction], bills: [CalendarBill]) -> Double {
        let cal = Calendar.current; let now = Date()
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        
        let spentThisMonth = transactions.filter { $0.type == .expense && $0.date >= monthStart && $0.date <= now }
            .reduce(0) { $0 + $1.amount }
        let earnedThisMonth = transactions.filter { $0.type == .income && $0.date >= monthStart && $0.date <= now }
            .reduce(0) { $0 + $1.amount }
        let upcomingBills = bills.filter { !$0.isPaid && $0.nextDueDate >= now && $0.nextDueDate < monthEnd }
            .reduce(0) { $0 + $1.amount }
        
        // Estimate remaining daily spending based on current pattern
        let dayOfMonth = cal.component(.day, from: now)
        let totalDays = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let remainingDays = totalDays - dayOfMonth
        let dailySpendRate = dayOfMonth > 0 ? spentThisMonth / Double(dayOfMonth) : 0
        let projectedSpending = dailySpendRate * Double(remainingDays)
        
        return (earnedThisMonth > 0 ? earnedThisMonth : income) - spentThisMonth - upcomingBills - projectedSpending
    }
    
    // MARK: - Month Comparison
    func compareMonths(transactions: [Transaction], month1: Date, month2: Date) -> String {
        let cal = Calendar.current
        func monthTotal(_ date: Date) -> Double {
            let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return transactions.filter { $0.type == .expense && $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.amount }
        }
        let t1 = monthTotal(month1); let t2 = monthTotal(month2)
        let diff = t2 - t1; let pct = t1 > 0 ? (diff / t1 * 100) : 0
        let f = DateFormatter(); f.dateFormat = "MMMM"
        let m1 = f.string(from: month1); let m2 = f.string(from: month2)
        
        if fr {
            return diff > 0
            ? "📈 Tu as dépensé \(abs(diff).asCurrency) de plus en \(m2) vs \(m1) (+\(String(format: "%.0f", pct))%). Voyons où on peut ajuster ça."
            : "📉 Bonne nouvelle! Tu as dépensé \(abs(diff).asCurrency) de moins en \(m2) vs \(m1) (\(String(format: "%.0f", pct))%). Continue comme ça!"
        } else {
            return diff > 0
            ? "📈 You spent \(abs(diff).asCurrency) more in \(m2) vs \(m1) (+\(String(format: "%.0f", pct))%). Let's see where we can adjust."
            : "📉 Good news! You spent \(abs(diff).asCurrency) less in \(m2) vs \(m1) (\(String(format: "%.0f", pct))%). Keep it up!"
        }
    }
    
    // MARK: - Generate Plan
    func generatePlan(profile: UserProfile, q: FinancialQuestionnaire) async throws -> FinancialPlan {
        try await Task.sleep(nanoseconds: 2_500_000_000)
        let income = profile.monthlyNetIncome
        let months = q.timeFrame.months
        let needed = max(0, q.goalAmount - q.currentSavings)
        let monthlyTarget = needed / Double(months)
        let after = income - monthlyTarget
        
        let budget = MonthlyBudget(
            income: income, housing: q.monthlyRent > 0 ? q.monthlyRent : after * 0.30,
            food: q.monthlyGroceries > 0 ? q.monthlyGroceries : after * 0.12,
            transport: q.monthlyTransport > 0 ? q.monthlyTransport : after * 0.08,
            utilities: q.monthlyUtilities > 0 ? q.monthlyUtilities : after * 0.05,
            entertainment: after * 0.06, savings: monthlyTarget,
            debtPayment: q.monthlyDebt,
            insurance: q.insuranceTypes.reduce(0) { $0 + $1.monthlyCost },
            subscriptions: q.totalSubscriptionCost,
            miscellaneous: after * 0.04
        )
        
        let cal = Calendar.current
        let mi = max(1, months / 4)
        let milestones: [Milestone] = stride(from: mi, through: months, by: mi).map { m in
            Milestone(title: fr ? "Mois \(m) — Objectif" : "Month \(m) Target",
                      targetDate: cal.date(byAdding: .month, value: m, to: Date()) ?? Date(),
                      targetAmount: monthlyTarget * Double(m) + q.currentSavings)
        }
        
        var recs: [Recommendation] = [
            Recommendation(title: fr ? "Automatiser l'épargne" : "Automate Savings",
                          description: fr ? "Configure un virement automatique de \(monthlyTarget.asCurrencyShort) le jour de paie vers un compte épargne à haut rendement. C'est la règle #1 — paie-toi en premier." : "Set up auto-transfer of \(monthlyTarget.asCurrencyShort) on payday to a high-yield savings account. Rule #1 — pay yourself first.",
                          category: "Savings", potentialSavings: monthlyTarget * 0.05, priority: "High"),
            Recommendation(title: fr ? "Stratégie repas" : "Meal Strategy",
                          description: fr ? "Cuisine à la maison 5 jours/semaine. Budget \(budget.food.asCurrencyShort)/mois pour l'épicerie. Le meal prep du dimanche te fera gagner du temps ET de l'argent." : "Cook at home 5 days/week. Budget \(budget.food.asCurrencyShort)/month for groceries. Sunday meal prep saves time AND money.",
                          category: "Spending", potentialSavings: 200, priority: "Medium"),
        ]
        
        if q.totalSubscriptionCost > 50 {
            recs.append(Recommendation(title: fr ? "Audit des abonnements" : "Subscription Audit",
                          description: fr ? "Tu paies \(q.totalSubscriptionCost.asCurrency)/mois en abonnements. Regarde chacun — est-ce que tu l'utilises vraiment? La plupart des gens gaspillent 30-40% en abonnements oubliés." : "You're paying \(q.totalSubscriptionCost.asCurrency)/month in subscriptions. Check each one — do you actually use it? Most people waste 30-40% on forgotten subscriptions.",
                          category: "Spending", potentialSavings: q.totalSubscriptionCost * 0.3, priority: "Medium"))
        }
        if q.monthlyDebt > income * 0.15 {
            recs.insert(Recommendation(title: fr ? "Avalanche de dette" : "Debt Avalanche",
                          description: fr ? "Ta dette représente plus de 15% de tes revenus. Stratégie: paie le minimum sur tout, puis attaque la dette avec le plus haut taux d'intérêt. Chaque dollar compte." : "Your debt exceeds 15% of income. Strategy: pay minimums on everything, then attack the highest interest rate debt. Every dollar counts.",
                          category: "Debt", potentialSavings: q.monthlyDebt * 0.1, priority: "High"), at: 0)
        }
        if !q.hasEmergencyFund {
            recs.append(Recommendation(title: fr ? "Fonds d'urgence" : "Emergency Fund",
                          description: fr ? "Avant d'épargner agressivement, constitue un coussin de $1,000. Ensuite, vise 3-6 mois de dépenses (\(String(format: "$%.0f", budget.totalExpenses * 3)) - \(String(format: "$%.0f", budget.totalExpenses * 6)))." : "Before aggressive saving, build a $1,000 cushion. Then aim for 3-6 months of expenses.",
                          category: "Savings", potentialSavings: 0, priority: "High"))
        }
        if !q.hasInsurance || q.insuranceTypes.isEmpty {
            recs.append(Recommendation(title: fr ? "Couverture assurance" : "Insurance Coverage",
                          description: fr ? "Tu n'as pas mentionné d'assurance. C'est un risque majeur — une urgence médicale pourrait effacer toute ton épargne. Regarde les options disponibles." : "You didn't mention insurance. This is a major risk — a medical emergency could wipe out all your savings.",
                          category: "Savings", potentialSavings: 0, priority: "High"))
        }
        
        let actions: [WeeklyAction] = (1...min(months*4, 12)).map { w in
            let t: [String]
            switch w {
            case 1: t = [fr ? "Ouvrir compte épargne haut rendement" : "Open high-yield savings account",
                         fr ? "Configurer virements automatiques" : "Set up automatic transfers",
                         fr ? "Lister tous les abonnements" : "List all subscriptions"]
            case 2: t = [fr ? "Planifier les repas de la semaine" : "Plan weekly meals",
                         fr ? "Annuler abonnements inutilisés" : "Cancel unused subscriptions",
                         fr ? "Tracker chaque dépense" : "Track every expense"]
            case 3: t = [fr ? "Analyser les dépenses semaine 1-2" : "Review week 1-2 spending",
                         fr ? "Ajuster les catégories budget" : "Adjust budget categories",
                         fr ? "Comparer les prix d'assurance" : "Compare insurance prices"]
            case 4: t = [fr ? "Bilan de fin de mois vs objectifs" : "Month-end review vs targets",
                         fr ? "Célébrer les petites victoires!" : "Celebrate small wins!",
                         fr ? "Planifier le mois prochain" : "Plan next month"]
            default: t = [fr ? "Logger les transactions du jour" : "Log daily transactions",
                          fr ? "Revue hebdomadaire du budget" : "Weekly budget review",
                          w % 4 == 0 ? (fr ? "Bilan mensuel des jalons" : "Monthly milestone review") : (fr ? "Trouver 1 économie possible" : "Find one savings opportunity")]
            }
            return WeeklyAction(weekNumber: w, tasks: t)
        }
        
        var cum = q.currentSavings
        let projections: [MonthlyProjection] = (1...months).map { m in
            cum += monthlyTarget
            return MonthlyProjection(month: m, projectedSavings: monthlyTarget, cumulativeSavings: cum)
        }
        
        let title = fr
            ? (q.goalAmount > 20000 ? "Accumulation de Capital et Fondation" : q.goalAmount > 10000 ? "Stratégie d'Épargne Accélérée" : "Feuille de Route Épargne Intelligente")
            : (q.goalAmount > 20000 ? "Capital Accumulation and Foundation Building" : q.goalAmount > 10000 ? "Accelerated Savings Strategy" : "Smart Savings Roadmap")
        
        return FinancialPlan(title: title, summary: fr
            ? "Basé sur \(income.asCurrencyShort)/mois de revenu net, épargne \(monthlyTarget.asCurrencyShort)/mois pendant \(months) mois pour atteindre \(q.goalAmount.asCurrencyShort). Épargne actuelle: \(q.currentSavings.asCurrencyShort) (\(String(format: "%.0f", (q.currentSavings/max(q.goalAmount,1))*100))% complété)."
            : "Based on \(income.asCurrencyShort)/month net income, save \(monthlyTarget.asCurrencyShort)/month over \(months) months to reach \(q.goalAmount.asCurrencyShort). Current savings: \(q.currentSavings.asCurrencyShort) (\(String(format: "%.0f", (q.currentSavings/max(q.goalAmount,1))*100))% complete).",
            monthlyBudget: budget, milestones: milestones, recommendations: recs, weeklyActions: actions, projections: projections, goalAmount: q.goalAmount, timeFrameMonths: months)
    }
    
    // MARK: - Human-Like Chat
    func chat(message: String, context: (UserProfile?, FinancialPlan?, [Transaction], [CalendarBill])) async throws -> String {
        try await Task.sleep(nanoseconds: 800_000_000)
        let low = message.lowercased()
        let p = context.1; let txns = context.2; let bills = context.3
        let income = context.0?.monthlyNetIncome ?? 0
        
        if low.contains("budget") || low.contains("dépens") || low.contains("spend") {
            if let plan = p {
                return fr
                ? "D'accord, regardons ça ensemble 📊\n\nVoici ta répartition mensuelle actuelle:\n\n🏠 Logement: \(plan.monthlyBudget.housing.asCurrency)\n🛒 Alimentation: \(plan.monthlyBudget.food.asCurrency)\n🚗 Transport: \(plan.monthlyBudget.transport.asCurrency)\n💰 Épargne: \(plan.monthlyBudget.savings.asCurrency)\n💳 Dettes: \(plan.monthlyBudget.debtPayment.asCurrency)\n\nTon total de dépenses devrait rester sous \(plan.monthlyBudget.totalExpenses.asCurrency). Je vois quelques endroits où on pourrait optimiser — tu veux qu'on regarde ensemble?"
                : "Let's look at this together 📊\n\nHere's your current monthly breakdown:\n\n🏠 Housing: \(plan.monthlyBudget.housing.asCurrency)\n🛒 Food: \(plan.monthlyBudget.food.asCurrency)\n🚗 Transport: \(plan.monthlyBudget.transport.asCurrency)\n💰 Savings: \(plan.monthlyBudget.savings.asCurrency)\n💳 Debt: \(plan.monthlyBudget.debtPayment.asCurrency)\n\nTotal expenses should stay under \(plan.monthlyBudget.totalExpenses.asCurrency). I see some areas we could optimize — want to dive in?"
            }
        }
        
        if low.contains("prédiction") || low.contains("prediction") || low.contains("end of month") || low.contains("fin du mois") {
            let predicted = predictMonthEnd(income: income, transactions: txns, bills: bills)
            return fr
            ? "Laisse-moi calculer ça pour toi... 🔮\n\n\(L10n.monthEndPrediction(predicted))\n\n\(predicted < 0 ? "⚠️ C'est serré. On devrait regarder tes dépenses non-essentielles restantes et voir où couper." : "✅ Tu es en bonne voie! Continue de surveiller tes dépenses quotidiennes.")"
            : "Let me crunch the numbers for you... 🔮\n\n\(L10n.monthEndPrediction(predicted))\n\n\(predicted < 0 ? "⚠️ That's tight. We should look at your remaining non-essential spending and see where to cut." : "✅ You're on track! Keep monitoring your daily spending.")"
        }
        
        if low.contains("compare") || low.contains("comparer") {
            let cal = Calendar.current
            let lastMonth = cal.date(byAdding: .month, value: -1, to: Date())!
            return compareMonths(transactions: txns, month1: lastMonth, month2: Date())
        }
        
        if low.contains("save") || low.contains("saving") || low.contains("épargh") || low.contains("économi") {
            return fr
            ? "Très bonne question! Voici mes meilleures stratégies pour toi 💡\n\n1. **Automatise d'abord** — le virement le jour de paie, avant de dépenser quoi que ce soit\n2. **La règle des 24h** — attends avant tout achat non-essentiel de +$50\n3. **Audit abonnements** — vérifie chacun. Honnêtement, combien tu utilises vraiment?\n4. **Meal prep** — cuisine le dimanche, économise $200-400/mois vs manger dehors\n5. **Négocie tes factures** — appelle tes fournisseurs pour de meilleurs tarifs\n\nPar quoi veux-tu commencer?"
            : "Great question! Here are my best strategies for you 💡\n\n1. **Automate first** — transfer on payday, before spending anything\n2. **24-hour rule** — wait before any non-essential purchase over $50\n3. **Subscription audit** — check each one. Honestly, how many do you actually use?\n4. **Meal prep** — cook Sundays, save $200-400/month vs eating out\n5. **Negotiate bills** — call providers for better rates\n\nWhere do you want to start?"
        }
        
        if low.contains("invest") || low.contains("placem") {
            return fr
            ? "Parlons investissement! Voici l'ordre de priorité que je recommande 📈\n\n1. Fonds d'urgence (3-6 mois de dépenses) — compte épargne haut rendement\n2. Rembourse les dettes à taux élevé (>7%)\n3. Match employeur REER/401k — c'est de l'argent gratuit!\n4. CELI/Roth IRA — croissance libre d'impôt\n5. Compte de courtage — pour aller plus loin\n\nAvec ta tolérance au risque, je suggère de commencer avec des fonds indiciels pour une exposition large au marché. On en discute plus en détail?"
            : "Let's talk investing! Here's the priority order I recommend 📈\n\n1. Emergency fund (3-6 months expenses) — high-yield savings\n2. Pay off high-interest debt (>7% APR)\n3. Employer 401(k) match — that's free money!\n4. Roth IRA — tax-free growth\n5. Taxable brokerage — for going further\n\nBased on your risk tolerance, I'd suggest starting with index funds for broad market exposure. Want to discuss more?"
        }
        
        if low.contains("rebuild") || low.contains("new plan") || low.contains("reconstrui") || low.contains("nouveau plan") {
            return fr
            ? "Bien sûr! Je peux reconstruire ton plan 🔄\n\nDis-moi ce qui a changé:\n1. Ton revenu a changé?\n2. Nouveaux objectifs financiers?\n3. Des dépenses qui ont bougé significativement?\n\nPartage les détails et je génère une stratégie mise à jour. L'important c'est de s'adapter — la flexibilité est la clé du succès financier."
            : "Of course! I can rebuild your plan 🔄\n\nTell me what's changed:\n1. Has your income changed?\n2. New financial goals?\n3. Any significant expense shifts?\n\nShare the details and I'll generate an updated strategy. The key is adapting — flexibility is essential for financial success."
        }
        
        // Default welcome
        return fr
        ? "Salut! 👋 Je suis ton conseiller financier IA. Pense à moi comme un ami qui s'y connaît en finances.\n\nJe peux t'aider avec:\n• 📊 Analyse de budget et optimisation\n• 💰 Stratégies d'épargne personnalisées\n• 🔮 Prédictions de fin de mois\n• 📈 Comparaison entre les mois\n• 🔄 Ajustements de plan\n• 💼 Conseils d'investissement\n\nQu'est-ce qui te préoccupe en ce moment?"
        : "Hey! 👋 I'm your AI financial advisor. Think of me as a friend who knows their way around money.\n\nI can help with:\n• 📊 Budget analysis & optimization\n• 💰 Personalized savings strategies\n• 🔮 Month-end predictions\n• 📈 Month-over-month comparison\n• 🔄 Plan adjustments\n• 💼 Investment guidance\n\nWhat's on your mind right now?"
    }
}

// MARK: - Data Persistence
class DataStore: ObservableObject {
    static let shared = DataStore()
    func save<T: Encodable>(_ v: T, key: String) { if let d = try? JSONEncoder().encode(v) { UserDefaults.standard.set(d, forKey: key) } }
    func load<T: Decodable>(_ t: T.Type, key: String) -> T? { guard let d = UserDefaults.standard.data(forKey: key) else { return nil }; return try? JSONDecoder().decode(t, from: d) }
    func clear(_ key: String) { UserDefaults.standard.removeObject(forKey: key) }
}

// MARK: - Notification Service (with funny messages)
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
        let funny = L10n.funnyNotifications.randomElement() ?? ""
        
        let content = UNMutableNotificationContent()
        content.title = funny
        content.body = "\(bill.title) — \(bill.amount.asCurrency) " + (ThemeManager.shared.language == .fr ? "dans \(bill.reminderDaysBefore) jour(s)" : "due in \(bill.reminderDaysBefore) day(s)")
        content.sound = .default
        
        guard let d = Calendar.current.date(byAdding: .day, value: -bill.reminderDaysBefore, to: bill.nextDueDate) else { return }
        let c = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: d)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "bill-\(bill.id)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: c, repeats: false)))
        
        // Due-day
        let dc = UNMutableNotificationContent()
        dc.title = ThemeManager.shared.language == .fr ? "⚠️ Paiement dû aujourd'hui!" : "⚠️ Payment Due Today!"
        dc.body = "\(bill.title) — \(bill.amount.asCurrency)"; dc.sound = .default
        var dd = Calendar.current.dateComponents([.year,.month,.day], from: bill.nextDueDate); dd.hour = 9
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "due-\(bill.id)", content: dc, trigger: UNCalendarNotificationTrigger(dateMatching: dd, repeats: false)))
    }
    
    func cancelReminder(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bill-\(id)", "due-\(id)"])
    }
}
