// AccountView.swift — More Hub: Account, Personalization, Bank Integration, Project Management
import SwiftUI
import PhotosUI

// MARK: - More Hub
struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    private var fr: Bool { themeManager.language == .fr }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                profileSummaryCard
                menuRows
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle(L10n.more)
    }

    private var profileSummaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                if let data = appState.user?.profileImageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 56, height: 56).clipShape(Circle())
                } else {
                    Circle().fill(Color.theme.primaryGradient).frame(width: 56, height: 56)
                    Text(appState.user?.initials ?? "?")
                        .font(AppFont.heading(22)).foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.user?.fullName ?? "User")
                    .font(AppFont.subhead(16)).foregroundStyle(Color.theme.textPrimary)
                Text(appState.user?.email ?? "")
                    .font(AppFont.caption(13)).foregroundStyle(Color.theme.textSecondary)
            }
            Spacer()
            Text(appState.user?.monthlyNetIncome.asCurrencyShort ?? "$0")
                .font(AppFont.subhead(15)).foregroundStyle(Color.theme.accent)
        }
        .padding(16).card().padding(.horizontal, 20)
    }

    private var menuRows: some View {
        VStack(spacing: 10) {
            moreRow(icon: "person.fill", color: Color.theme.accent,
                    title: fr ? "Compte" : "Account",
                    subtitle: fr ? "Profil & déconnexion" : "Profile & sign out") {
                AccountDetailView()
            }
            moreRow(icon: "paintbrush.pointed.fill", color: Color.theme.info,
                    title: L10n.personalization,
                    subtitle: fr ? "Thème, couleurs, langue" : "Theme, colors, language") {
                PersonalizationView()
            }
            moreRow(icon: "building.columns.fill", color: Color.theme.success,
                    title: L10n.bankIntegration,
                    subtitle: fr ? "Connexion bancaire (BETA)" : "Bank connection (BETA)") {
                BankIntegrationView()
            }
            moreRow(icon: "person.3.fill", color: Color.theme.warning,
                    title: L10n.projectManagement,
                    subtitle: fr ? "Gestion d'équipe — V2" : "Team management — V2") {
                ProjectManagementView()
            }
        }
        .padding(.horizontal, 20)
    }

    private func moreRow<D: View>(icon: String, color: Color, title: String, subtitle: String,
                                   @ViewBuilder destination: () -> D) -> some View {
        NavigationLink { destination() } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.subhead(15)).foregroundStyle(Color.theme.textPrimary)
                    Text(subtitle).font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.theme.textTertiary)
            }
            .padding(14).card()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Account Detail
struct AccountDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    private var fr: Bool { themeManager.language == .fr }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                profileHeader
                infoSection
                dangerZone
            }
            .padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle(fr ? "Compte" : "Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let data = appState.user?.profileImageData, let img = UIImage(data: data) {
                profileImage = img
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 90, height: 90).clipShape(Circle())
                    } else {
                        ZStack {
                            Circle().fill(Color.theme.primaryGradient).frame(width: 90, height: 90)
                            Text(appState.user?.initials ?? "?")
                                .font(AppFont.title(28)).foregroundStyle(.white)
                        }
                    }
                    Circle().stroke(Color.theme.accent, lineWidth: 3).frame(width: 94, height: 94)
                    ZStack {
                        Circle().fill(Color.theme.accent).frame(width: 28, height: 28)
                        Image(systemName: "camera.fill").font(.system(size: 12)).foregroundStyle(.white)
                    }.offset(x: 32, y: 32)
                }
            }
            .onChange(of: selectedPhoto) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        profileImage = img
                        var u = appState.user
                        u?.profileImageData = img.jpegData(compressionQuality: 0.6)
                        if let updated = u { appState.updateProfile(updated) }
                    }
                }
            }
            Text(appState.user?.fullName ?? "User")
                .font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
            Text(appState.user?.email ?? "")
                .font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary)
            HStack(spacing: 16) {
                infoChip(fr ? "Net Mensuel" : "Monthly Net",
                         appState.user?.monthlyNetIncome.asCurrencyShort ?? "$0")
                infoChip(fr ? "Méthode" : "Method",
                         appState.user?.dataEntryMethod == .bankLink ? "🏦 Bank" : "✏️ Manual")
            }
        }
        .padding(22).card().padding(.horizontal, 20)
    }

    private func infoChip(_ l: String, _ v: String) -> some View {
        VStack(spacing: 3) {
            Text(l).font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary)
            Text(v).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(fr ? "INFORMATIONS" : "INFORMATION").sectionLabel()
            infoRow(icon: "envelope.fill", label: "Email", value: appState.user?.email ?? "—")
            Divider()
            infoRow(icon: "calendar",
                    label: fr ? "Membre depuis" : "Member since",
                    value: appState.user?.createdAt.short ?? "—")
        }
        .padding(18).card().padding(.horizontal, 20)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundStyle(Color.theme.accent).frame(width: 20)
            Text(label).font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary)
            Spacer()
            Text(value).font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary)
        }
        .padding(.vertical, 4)
    }

    private var dangerZone: some View {
        Button { withAnimation { appState.logout() } } label: {
            HStack {
                Image(systemName: "arrow.right.square")
                Text(L10n.signOut)
            }
            .font(AppFont.subhead())
            .foregroundStyle(Color.theme.danger)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.danger.opacity(0.08)))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Personalization
struct PersonalizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    private var fr: Bool { themeManager.language == .fr }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                modeSection
                colorSection
                languageSection
            }
            .padding(.top, 8).padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle(L10n.personalization)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.darkMode).sectionLabel()
            Toggle(isOn: $themeManager.isDarkMode) {
                HStack(spacing: 10) {
                    Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundStyle(Color.theme.accent)
                    Text(themeManager.isDarkMode
                         ? (fr ? "Mode Sombre" : "Dark Mode")
                         : (fr ? "Mode Clair" : "Light Mode"))
                        .font(AppFont.body(14))
                }
            }
            .tint(Color.theme.accent)
        }
        .padding(18).card().padding(.horizontal, 20)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.accentColor).sectionLabel()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(ThemeManager.accentOptions, id: \.0) { hex, name in
                    Button { withAnimation { themeManager.accentColorHex = hex } } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(Color(hex: hex)).frame(width: 36, height: 36)
                                if themeManager.accentColorHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                            Text(name).font(AppFont.caption(9)).foregroundStyle(Color.theme.textTertiary)
                        }
                    }
                }
            }
        }
        .padding(18).card().padding(.horizontal, 20)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.language).sectionLabel()
            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button { withAnimation { themeManager.language = lang } } label: {
                        HStack(spacing: 6) {
                            Text(lang == .fr ? "🇫🇷" : "🇺🇸")
                            Text(lang.label).font(AppFont.subhead(14))
                        }
                        .foregroundStyle(themeManager.language == lang ? .white : Color.theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.language == lang ? Color.theme.accent : Color.theme.surfaceAlt)
                        )
                    }
                }
            }
        }
        .padding(18).card().padding(.horizontal, 20)
    }
}

// MARK: - Bank Integration
struct BankIntegrationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    private var fr: Bool { themeManager.language == .fr }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                bankHeader
                bankConnectCard
                securityNote
            }
            .padding(.top, 8).padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle(L10n.bankIntegration)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bankHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.theme.success.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 32)).foregroundStyle(Color.theme.success)
            }
            Text(L10n.bankIntegration).font(AppFont.heading()).foregroundStyle(Color.theme.textPrimary)
            Text(fr ? "Connectez votre compte bancaire pour importer automatiquement vos transactions."
                    : "Connect your bank account to automatically import your transactions.")
                .font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("BETA").font(AppFont.label(10)).foregroundStyle(Color.theme.accent)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.theme.accentSoft))
        }
        .padding(22).card().padding(.horizontal, 20)
    }

    private var bankConnectCard: some View {
        VStack(spacing: 14) {
            Text(fr ? "SERVICES SUPPORTÉS" : "SUPPORTED SERVICES").sectionLabel()
            ForEach(["Plaid", "Buddy", "YNAB"], id: \.self) { service in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color.theme.surfaceAlt).frame(width: 40, height: 40)
                        Image(systemName: "link").foregroundStyle(Color.theme.textSecondary)
                    }
                    Text(service).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    Text(fr ? "À venir" : "Coming soon")
                        .font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary)
                }
                if service != "YNAB" { Divider() }
            }
            Button { /* Open bank link flow */ } label: {
                HStack {
                    Image(systemName: "link")
                    Text(fr ? "Connecter ma banque" : "Connect Bank")
                }
                .font(AppFont.subhead(14)).foregroundStyle(Color.theme.accent)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.theme.accent, lineWidth: 1.5))
            }
        }
        .padding(18).card().padding(.horizontal, 20)
    }

    private var securityNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill").foregroundStyle(Color.theme.success)
            Text(fr ? "Connexion sécurisée — données chiffrées de bout en bout"
                    : "Secure connection — end-to-end encrypted data")
                .font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary)
        }
        .padding(14).card().padding(.horizontal, 20)
    }
}

// MARK: - Project Management
struct ProjectManagementView: View {
    @EnvironmentObject var themeManager: ThemeManager
    private var fr: Bool { themeManager.language == .fr }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerCard
                featuresCard
                notifyCard
            }
            .padding(.top, 8).padding(.bottom, 40)
        }
        .background(Color.theme.background)
        .navigationTitle(L10n.projectManagement)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.theme.warning.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: "person.3.fill").font(.system(size: 28)).foregroundStyle(Color.theme.warning)
            }
            HStack(spacing: 6) {
                Text(L10n.teamProjectTitle)
                    .font(AppFont.heading()).foregroundStyle(Color.theme.textPrimary)
                Text("V2").font(AppFont.label(10)).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.theme.accent))
            }
            Text(L10n.teamProjectDesc)
                .font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(22).card().padding(.horizontal, 20)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fr ? "FONCTIONNALITÉS PRÉVUES" : "PLANNED FEATURES").sectionLabel()
            featureRow(icon: "chart.bar.fill", color: Color.theme.accent,
                       title: fr ? "Budgets partagés" : "Shared budgets",
                       desc: fr ? "Gérez un budget commun avec votre équipe" : "Manage a shared budget with your team")
            Divider()
            featureRow(icon: "person.badge.key.fill", color: Color.theme.info,
                       title: fr ? "Rôles & permissions" : "Roles & permissions",
                       desc: fr ? "Contrôlez qui peut voir quoi" : "Control who can see what")
            Divider()
            featureRow(icon: "chart.xyaxis.line", color: Color.theme.success,
                       title: fr ? "Stats d'équipe" : "Team stats",
                       desc: fr ? "Analysez les dépenses collectives" : "Analyze collective spending")
        }
        .padding(18).card().padding(.horizontal, 20)
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.1)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                Text(desc).font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary)
            }
        }
    }

    private var notifyCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill").foregroundStyle(Color.theme.textTertiary)
            Text(L10n.comingSoonV2).font(AppFont.body(14)).foregroundStyle(Color.theme.textTertiary)
            Spacer()
            Button { } label: {
                Text(fr ? "Me notifier" : "Notify Me")
                    .font(AppFont.caption(12)).foregroundStyle(Color.theme.accent)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(Color.theme.accentSoft))
            }
        }
        .padding(16).card().padding(.horizontal, 20)
    }
}
