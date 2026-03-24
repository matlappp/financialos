// Theme.swift
// Financial.OS Design System — Blue & White Premium Theme

import SwiftUI

// MARK: - Color Theme
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Primary blues (matching screenshot)
    let primary        = Color(hex: "0D1B6F")   // Deep navy
    let primaryLight   = Color(hex: "1E3A8A")   // Royal blue
    let accent         = Color(hex: "2563EB")   // Bright blue
    let accentLight    = Color(hex: "3B82F6")   // Light blue
    let accentSoft     = Color(hex: "DBEAFE")   // Very light blue
    
    // Backgrounds
    let background     = Color(hex: "F8FAFC")   // Off-white
    let surface        = Color.white
    let surfaceAlt     = Color(hex: "F1F5F9")   // Light gray
    let sidebar        = Color.white
    
    // Text
    let textPrimary    = Color(hex: "0F172A")   // Near black
    let textSecondary  = Color(hex: "64748B")   // Slate
    let textTertiary   = Color(hex: "94A3B8")   // Light slate
    let textOnPrimary  = Color.white
    
    // Status
    let success        = Color(hex: "10B981")
    let warning        = Color(hex: "F59E0B")
    let danger         = Color(hex: "EF4444")
    let info           = Color(hex: "06B6D4")
    
    // Category colors
    let food           = Color(hex: "F97316")
    let restaurant     = Color(hex: "EC4899")
    let transport      = Color(hex: "06B6D4")
    let housing        = Color(hex: "8B5CF6")
    let utilities      = Color(hex: "6366F1")
    let entertainment  = Color(hex: "F59E0B")
    let shopping       = Color(hex: "10B981")
    let health         = Color(hex: "EF4444")
    let education      = Color(hex: "3B82F6")
    let savings        = Color(hex: "059669")
    let debt           = Color(hex: "DC2626")
    let subscription   = Color(hex: "7C3AED")
    
    // Gradients
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "0D1B6F"), Color(hex: "1E3A8A"), Color(hex: "2563EB")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "0D1B6F"), Color(hex: "1E3A8A")],
            startPoint: .top, endPoint: .bottom
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "1E293B"), Color(hex: "0F172A")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    func categoryColor(for cat: SpendingCategory) -> Color {
        switch cat {
        case .food: return food
        case .restaurant: return restaurant
        case .transport: return transport
        case .housing: return housing
        case .utilities: return utilities
        case .entertainment: return entertainment
        case .shopping: return shopping
        case .health: return health
        case .education: return education
        case .savings: return savings
        case .debt: return debt
        case .subscription: return subscription
        case .other: return textTertiary
        }
    }
}

// MARK: - Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
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
    static func hero(_ size: CGFloat = 40) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold) }
    static func heading(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .semibold) }
    static func subhead(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .medium) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .regular) }
    static func label(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .semibold) }
    static func mono(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
    static func currency(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .bold, design: .rounded) }
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    var radius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.theme.surface)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
    }
}

struct PrimaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true
    func body(content: Content) -> some View {
        content
            .font(AppFont.subhead())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isEnabled ? Color.theme.primaryGradient : LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
            )
            .shadow(color: Color.theme.accent.opacity(isEnabled ? 0.3 : 0), radius: 12, y: 4)
    }
}

struct SectionLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.label())
            .foregroundStyle(Color.theme.accent)
            .tracking(1.2)
            .textCase(.uppercase)
    }
}

extension View {
    func card(_ radius: CGFloat = 16) -> some View { modifier(CardModifier(radius: radius)) }
    func primaryButton(_ enabled: Bool = true) -> some View { modifier(PrimaryButtonStyle(isEnabled: enabled)) }
    func sectionLabel() -> some View { modifier(SectionLabel()) }
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
    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: self)).day ?? 0
    }
}
