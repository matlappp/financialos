// Theme.swift
// Financial.OS — Design System with Light/Dark + Personalization

import SwiftUI
import Combine

// MARK: - User Preferences (Persisted)
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false
    @Published var accentColorHex: String = "2563EB"
    @Published var language: AppLanguage = .fr
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        accentColorHex = UserDefaults.standard.string(forKey: "accentColor") ?? "2563EB"
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "language") ?? "fr") ?? .fr
        
        $isDarkMode.dropFirst().sink { UserDefaults.standard.set($0, forKey: "isDarkMode") }.store(in: &cancellables)
        $accentColorHex.dropFirst().sink { UserDefaults.standard.set($0, forKey: "accentColor") }.store(in: &cancellables)
        $language.dropFirst().sink { UserDefaults.standard.set($0.rawValue, forKey: "language") }.store(in: &cancellables)
    }
    
    var userAccent: Color { Color(hex: accentColorHex) }
    
    static let accentOptions: [(String, String)] = [
        ("2563EB", "Bleu Royal"), ("0D1B6F", "Marine"), ("7C3AED", "Violet"),
        ("059669", "Émeraude"), ("DC2626", "Rouge"), ("F59E0B", "Or"),
        ("EC4899", "Rose"), ("06B6D4", "Cyan"), ("000000", "Noir")
    ]
}

enum AppLanguage: String, CaseIterable {
    case fr = "fr"; case en = "en"
    var label: String { self == .fr ? "Français" : "English" }
}

// MARK: - Localization
struct L10n {
    static var lang: AppLanguage { ThemeManager.shared.language }
    
    // Navigation
    static var roadmap: String { lang == .fr ? "Plan IA" : "AI Roadmap" }
    static var workplace: String { lang == .fr ? "Espace de travail" : "Workplace" }
    static var agenda: String { lang == .fr ? "Agenda" : "Agenda" }
    static var growth: String { lang == .fr ? "Croissance" : "Growth" }
    static var safeSpace: String { lang == .fr ? "SafeSpace" : "SafeSpace" }
    static var account: String { lang == .fr ? "Compte" : "Account" }
    
    // Common
    static var getStarted: String { lang == .fr ? "Commencer" : "Get Started" }
    static var continueBtn: String { lang == .fr ? "Continuer" : "Continue" }
    static var cancel: String { lang == .fr ? "Annuler" : "Cancel" }
    static var save: String { lang == .fr ? "Sauvegarder" : "Save" }
    static var delete: String { lang == .fr ? "Supprimer" : "Delete" }
    static var add: String { lang == .fr ? "Ajouter" : "Add" }
    static var income: String { lang == .fr ? "Revenus" : "Income" }
    static var expenses: String { lang == .fr ? "Dépenses" : "Expenses" }
    static var balance: String { lang == .fr ? "Solde" : "Balance" }
    static var settings: String { lang == .fr ? "Réglages" : "Settings" }
    static var month: String { lang == .fr ? "Mois" : "Month" }
    static var week: String { lang == .fr ? "Semaine" : "Week" }
    static var paid: String { lang == .fr ? "Payé" : "Paid" }
    static var upcoming: String { lang == .fr ? "À venir" : "Upcoming" }
    static var overdue: String { lang == .fr ? "En retard" : "Overdue" }
    static var today: String { lang == .fr ? "Aujourd'hui" : "Today" }
    
    // Landing
    static var heroTitle1: String { lang == .fr ? "Votre Système" : "Your Financial" }
    static var heroTitle2: String { lang == .fr ? "Financier Intelligent" : "Operating System" }
    static var heroSubtitle: String { lang == .fr ? "Planification financière propulsée par l'IA qui transforme vos revenus en une feuille de route stratégique vers le succès." : "AI-powered financial planning that transforms your income into a strategic roadmap for success." }
    static var freeToStart: String { lang == .fr ? "Gratuit • Aucune carte requise" : "Free to start • No credit card required" }
    
    // Onboarding
    static var letsStart: String { lang == .fr ? "Commençons avec vous" : "Let's start with you" }
    static var incomeDesc: String { lang == .fr ? "Entrez vos revenus pour estimer votre salaire net mensuel." : "Enter your income to estimate your monthly take-home pay." }
    static var financialGoals: String { lang == .fr ? "Objectifs Financiers" : "Financial Goals" }
    static var yourSituation: String { lang == .fr ? "Votre Situation" : "Your Situation" }
    static var analyzing: String { lang == .fr ? "Analyse en cours..." : "Analyzing..." }
    static var yourPlan: String { lang == .fr ? "Votre Plan" : "Your Plan" }
    static var launchPlan: String { lang == .fr ? "Lancer Mon Plan" : "Launch My Plan" }
    static var generatePlan: String { lang == .fr ? "Générer Mon Plan" : "Generate My Plan" }
    
    // Workplace
    static var addTransaction: String { lang == .fr ? "Ajouter Transaction" : "Add Transaction" }
    static var recentTransactions: String { lang == .fr ? "Transactions Récentes" : "Recent Transactions" }
    static var spendingByCategory: String { lang == .fr ? "Dépenses par Catégorie" : "Spending by Category" }
    
    // Agenda
    static var monthlyBills: String { lang == .fr ? "Factures Mensuelles" : "Monthly Bills" }
    static var addBill: String { lang == .fr ? "Ajouter Facture" : "Add Bill" }
    static var comingUp: String { lang == .fr ? "Prochainement" : "Coming Up" }
    static var allBills: String { lang == .fr ? "Toutes les Factures" : "All Bills" }
    static var billsList: String { lang == .fr ? "Liste des Factures" : "Bills List" }
    static var personalNote: String { lang == .fr ? "Note Personnelle" : "Personal Note" }
    static var scheduleFuture: String { lang == .fr ? "Programmer Paiement" : "Schedule Payment" }
    
    // Predictions
    static func monthEndPrediction(_ amount: Double) -> String {
        lang == .fr
        ? "📊 Prédiction: Tu vas finir le mois avec \(amount.asCurrency) sur ton compte"
        : "📊 Prediction: You're gonna end up the month with \(amount.asCurrency) in your account"
    }
    
    // Funny notifications
    static var funnyNotifications: [String] {
        lang == .fr ? [
            "💸 Ton portefeuille pleure... un paiement arrive!",
            "🔔 Ding dong! Une facture frappe à ta porte!",
            "😱 Alerte rouge! Paiement dans quelques jours!",
            "🎵 C'est le jour de payer les factures, la la la~",
            "💰 L'argent s'en va... mais au moins t'es responsable!",
            "🚨 Attention: ton compte va maigrir bientôt!",
        ] : [
            "💸 Your wallet is crying... a payment is coming!",
            "🔔 Ding dong! A bill is knocking at your door!",
            "😱 Red alert! Payment due in a few days!",
            "🎵 It's bill-paying day, la la la~",
            "💰 Money's leaving... but at least you're responsible!",
            "🚨 Warning: your account is about to slim down!",
        ]
    }
    
    // AI
    static var askAdvisor: String { lang == .fr ? "Posez une question à votre conseiller..." : "Ask your advisor..." }
    
    // Team Project
    static var teamProjectTitle: String { lang == .fr ? "Gestion de Projet en Équipe" : "Team Project Management" }
    static var teamProjectDesc: String { lang == .fr ? "Créez des espaces partagés avec d'autres utilisateurs pour gérer vos finances en équipe." : "Create shared spaces with other users to manage finances as a team." }
    static var comingSoonV2: String { lang == .fr ? "Disponible dans la V2" : "Coming in V2" }
    
    // Account
    static var profilePhoto: String { lang == .fr ? "Photo de profil" : "Profile Photo" }
    static var darkMode: String { lang == .fr ? "Mode sombre" : "Dark Mode" }
    static var accentColor: String { lang == .fr ? "Couleur d'accent" : "Accent Color" }
    static var language: String { lang == .fr ? "Langue" : "Language" }
    static var signOut: String { lang == .fr ? "Se déconnecter" : "Sign Out" }
    static var personalization: String { lang == .fr ? "Personnalisation" : "Personalization" }
    static var manualEntry: String { lang == .fr ? "Saisie manuelle" : "Manual Entry" }
    static var linkBank: String { lang == .fr ? "Lier ma banque" : "Link Bank Account" }
    static var bankIntegration: String { lang == .fr ? "Intégration Bancaire" : "Bank Integration" }
    static var more: String { lang == .fr ? "Plus" : "More" }
    static var projectManagement: String { lang == .fr ? "Gestion de Projet" : "Project Management" }
    static var weekdayLetters: [String] { lang == .fr ? ["D","L","M","M","J","V","S"] : ["S","M","T","W","T","F","S"] }
    static func daysLabel(_ n: Int) -> String { lang == .fr ? "\(n)j" : "\(n)d" }
}

// MARK: - Color Theme
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    private var dm: Bool { ThemeManager.shared.isDarkMode }
    private var userAccent: Color { ThemeManager.shared.userAccent }
    
    var primary: Color { Color(hex: "0D1B6F") }
    var primaryLight: Color { Color(hex: "1E3A8A") }
    var accent: Color { userAccent }
    var accentLight: Color { userAccent.opacity(0.7) }
    var accentSoft: Color { userAccent.opacity(0.1) }
    
    var background: Color { dm ? Color(hex: "0A0E17") : Color(hex: "F8FAFC") }
    var surface: Color { dm ? Color(hex: "111827") : .white }
    var surfaceAlt: Color { dm ? Color(hex: "1E293B") : Color(hex: "F1F5F9") }
    
    var textPrimary: Color { dm ? Color(hex: "F8FAFC") : Color(hex: "0F172A") }
    var textSecondary: Color { dm ? Color(hex: "94A3B8") : Color(hex: "64748B") }
    var textTertiary: Color { dm ? Color(hex: "64748B") : Color(hex: "94A3B8") }
    var textOnPrimary: Color { .white }
    
    var success: Color { Color(hex: "10B981") }
    var warning: Color { Color(hex: "F59E0B") }
    var danger: Color { Color(hex: "EF4444") }
    var info: Color { Color(hex: "06B6D4") }
    
    var food: Color { Color(hex: "F97316") }; var restaurant: Color { Color(hex: "EC4899") }
    var transport: Color { Color(hex: "06B6D4") }; var housing: Color { Color(hex: "8B5CF6") }
    var utilities: Color { Color(hex: "6366F1") }; var entertainment: Color { Color(hex: "F59E0B") }
    var shopping: Color { Color(hex: "10B981") }; var health: Color { Color(hex: "EF4444") }
    var education: Color { Color(hex: "3B82F6") }; var savings: Color { Color(hex: "059669") }
    var debt: Color { Color(hex: "DC2626") }; var subscription: Color { Color(hex: "7C3AED") }
    
    var primaryGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "0D1B6F"), Color(hex: "1E3A8A"), userAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var heroGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "0D1B6F"), Color(hex: "1E3A8A")], startPoint: .top, endPoint: .bottom)
    }
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: dm ? [Color(hex: "1E293B"), Color(hex: "0F172A")] : [Color(hex: "0D1B6F"), Color(hex: "1E3A8A")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    func categoryColor(for cat: SpendingCategory) -> Color {
        switch cat {
        case .food: return food; case .restaurant: return restaurant; case .transport: return transport
        case .housing: return housing; case .utilities: return utilities; case .entertainment: return entertainment
        case .shopping: return shopping; case .health: return health; case .education: return education
        case .savings: return savings; case .debt: return debt; case .subscription: return subscription
        case .insurance: return info; case .phone: return Color(hex: "8B5CF6"); case .other: return textTertiary
        }
    }
}

// MARK: - Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Typography
struct AppFont {
    static func hero(_ s: CGFloat = 40) -> Font { .system(size: s, weight: .bold, design: .rounded) }
    static func title(_ s: CGFloat = 28) -> Font { .system(size: s, weight: .bold) }
    static func heading(_ s: CGFloat = 22) -> Font { .system(size: s, weight: .semibold) }
    static func subhead(_ s: CGFloat = 17) -> Font { .system(size: s, weight: .medium) }
    static func body(_ s: CGFloat = 15) -> Font { .system(size: s, weight: .regular) }
    static func caption(_ s: CGFloat = 13) -> Font { .system(size: s, weight: .regular) }
    static func label(_ s: CGFloat = 11) -> Font { .system(size: s, weight: .semibold) }
    static func mono(_ s: CGFloat = 15) -> Font { .system(size: s, weight: .medium, design: .monospaced) }
    static func currency(_ s: CGFloat = 32) -> Font { .system(size: s, weight: .bold, design: .rounded) }
}

// MARK: - View Modifiers
struct CardMod: ViewModifier {
    var r: CGFloat = 16
    func body(content: Content) -> some View {
        content.background(RoundedRectangle(cornerRadius: r).fill(Color.theme.surface)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2))
    }
}
struct PrimaryBtn: ViewModifier {
    var on: Bool = true
    func body(content: Content) -> some View {
        content.font(AppFont.subhead()).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 14).fill(on ? Color.theme.primaryGradient : LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)))
            .shadow(color: Color.theme.accent.opacity(on ? 0.3 : 0), radius: 12, y: 4)
    }
}
struct SectionLbl: ViewModifier {
    func body(content: Content) -> some View {
        content.font(AppFont.label()).foregroundStyle(Color.theme.accent).tracking(1.2).textCase(.uppercase)
    }
}

extension View {
    func card(_ r: CGFloat = 16) -> some View { modifier(CardMod(r: r)) }
    func primaryButton(_ on: Bool = true) -> some View { modifier(PrimaryBtn(on: on)) }
    func sectionLabel() -> some View { modifier(SectionLbl()) }
}

// MARK: - Formatters
extension Double {
    var asCurrency: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    var asCurrencyShort: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.locale = Locale(identifier: "en_US"); f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: self)) ?? "$0"
    }
}

extension Date {
    var short: String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: self) }
    var dayMonth: String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: self) }
    var monthYear: String { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: self) }
    var weekday: String { let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: self) }
    var dayNumber: String { let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: self) }
    var timeFormatted: String { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: self) }
    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: self)).day ?? 0
    }
}
