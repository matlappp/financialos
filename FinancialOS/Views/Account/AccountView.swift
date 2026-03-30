// AccountView.swift — Settings, Profile Photo, Theme, Bank Link, V2 Teaser
import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState; @EnvironmentObject var themeManager: ThemeManager
    @State private var showPhotoPicker = false; @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    private var fr: Bool { ThemeManager.shared.language == .fr }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                profileHeader
                bankIntegration
                personalizationSection
                teamProjectTeaser
                dangerZone
            }.padding(.bottom, 40)
        }.background(Color.theme.background).navigationTitle(L10n.account)
        .onAppear { if let data = appState.user?.profileImageData, let img = UIImage(data: data) { profileImage = img } }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 14) {
            // Photo
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: 90, height: 90).clipShape(Circle())
                    } else {
                        ZStack { Circle().fill(Color.theme.primaryGradient).frame(width: 90, height: 90)
                            Text(appState.user?.initials ?? "?").font(AppFont.title(28)).foregroundStyle(.white) }
                    }
                    Circle().stroke(Color.theme.accent, lineWidth: 3).frame(width: 94, height: 94)
                    ZStack { Circle().fill(Color.theme.accent).frame(width: 28, height: 28)
                        Image(systemName: "camera.fill").font(.system(size: 12)).foregroundStyle(.white) }.offset(x: 32, y: 32)
                }
            }
            .onChange(of: selectedPhoto) { item in
                Task { if let data = try? await item?.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    profileImage = img; var u = appState.user; u?.profileImageData = img.jpegData(compressionQuality: 0.6)
                    if let updated = u { appState.updateProfile(updated) }
                }}
            }
            
            Text(appState.user?.fullName ?? "User").font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
            Text(appState.user?.email ?? "").font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary)
            
            HStack(spacing: 16) {
                infoChip(fr ? "Net Mensuel" : "Monthly Net", appState.user?.monthlyNetIncome.asCurrencyShort ?? "$0")
                infoChip(fr ? "Méthode" : "Method", appState.user?.dataEntryMethod == .bankLink ? "🏦 Bank" : "✏️ Manual")
            }
        }.padding(22).card().padding(.horizontal, 20)
    }
    
    private func infoChip(_ l: String, _ v: String) -> some View {
        VStack(spacing: 3) { Text(l).font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary); Text(v).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary) }.frame(maxWidth: .infinity).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
    }
    
    // MARK: - Bank Integration
    private var bankIntegration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.bankIntegration).sectionLabel()
            HStack(spacing: 14) {
                ZStack { RoundedRectangle(cornerRadius: 12).fill(Color.theme.accent.opacity(0.1)).frame(width: 48, height: 48)
                    Image(systemName: "building.columns.fill").font(.system(size: 20)).foregroundStyle(Color.theme.accent) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.linkBank).font(AppFont.subhead(15)).foregroundStyle(Color.theme.textPrimary)
                    Text(fr ? "Importer automatiquement tes transactions via Plaid, Buddy ou YNAB." : "Auto-import transactions via Plaid, Buddy, or YNAB.")
                        .font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary).lineLimit(2)
                }; Spacer()
                Text("BETA").font(AppFont.label(9)).foregroundStyle(Color.theme.accent).padding(.horizontal, 6).padding(.vertical, 3).background(Capsule().fill(Color.theme.accentSoft))
            }
            
            Button { /* Open bank link flow */ } label: {
                HStack { Image(systemName: "link"); Text(fr ? "Connecter ma banque" : "Connect Bank") }.font(AppFont.subhead(14)).foregroundStyle(Color.theme.accent).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.theme.accent, lineWidth: 1.5))
            }
            
            HStack(spacing: 6) { Image(systemName: "lock.shield.fill").font(.system(size: 12)).foregroundStyle(Color.theme.success)
                Text(fr ? "Connexion sécurisée, données chiffrées" : "Secure connection, encrypted data").font(AppFont.caption(11)).foregroundStyle(Color.theme.textTertiary) }
        }.padding(18).card().padding(.horizontal, 20)
    }
    
    // MARK: - Personalization
    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.personalization).sectionLabel()
            
            // Dark mode
            Toggle(isOn: $themeManager.isDarkMode) {
                HStack(spacing: 10) { Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill").foregroundStyle(Color.theme.accent)
                    Text(L10n.darkMode).font(AppFont.body(14)) }
            }.tint(Color.theme.accent)
            
            Divider()
            
            // Accent color
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.accentColor).font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(ThemeManager.accentOptions, id: \.0) { hex, name in
                        Button {
                            withAnimation { themeManager.accentColorHex = hex }
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().fill(Color(hex: hex)).frame(width: 36, height: 36)
                                    if themeManager.accentColorHex == hex { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white) }
                                }
                                Text(name).font(AppFont.caption(9)).foregroundStyle(Color.theme.textTertiary)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Language
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.language).font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary)
                HStack(spacing: 8) { ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button { withAnimation { themeManager.language = lang } } label: {
                        HStack(spacing: 6) { Text(lang == .fr ? "🇫🇷" : "🇺🇸"); Text(lang.label).font(AppFont.subhead(14)) }
                            .foregroundStyle(themeManager.language == lang ? .white : Color.theme.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(themeManager.language == lang ? Color.theme.accent : Color.theme.surfaceAlt))
                    }
                }}
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    
    // MARK: - Team Project V2 Teaser
    private var teamProjectTeaser: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.3.fill").font(.system(size: 24)).foregroundStyle(Color.theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) { Text(L10n.teamProjectTitle).font(AppFont.subhead(15)).foregroundStyle(Color.theme.textPrimary)
                        Text("V2").font(AppFont.label(10)).foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.theme.accent)) }
                    Text(L10n.teamProjectDesc).font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary).lineLimit(2)
                }; Spacer()
            }
            
            HStack(spacing: 12) {
                featurePill("📊 " + (fr ? "Budgets partagés" : "Shared budgets"))
                featurePill("👥 " + (fr ? "Rôles" : "Roles"))
                featurePill("📈 " + (fr ? "Stats équipe" : "Team stats"))
            }
            
            HStack(spacing: 8) {
                Image(systemName: "lock.fill").foregroundStyle(Color.theme.textTertiary)
                Text(L10n.comingSoonV2).font(AppFont.body(14)).foregroundStyle(Color.theme.textTertiary)
                Spacer()
                Button { /* Notify me */ } label: {
                    Text(fr ? "Me notifier" : "Notify Me").font(AppFont.caption(12)).foregroundStyle(Color.theme.accent).padding(.horizontal, 12).padding(.vertical, 7).background(Capsule().fill(Color.theme.accentSoft))
                }
            }
        }.padding(18).card().padding(.horizontal, 20)
    }
    
    private func featurePill(_ t: String) -> some View {
        Text(t).font(AppFont.caption(10)).foregroundStyle(Color.theme.textSecondary).padding(.horizontal, 8).padding(.vertical, 5).background(RoundedRectangle(cornerRadius: 6).fill(Color.theme.surfaceAlt))
    }
    
    // MARK: - Danger Zone
    private var dangerZone: some View {
        VStack(spacing: 12) {
            Button { withAnimation { appState.logout() } } label: {
                HStack { Image(systemName: "arrow.right.square"); Text(L10n.signOut) }.font(AppFont.subhead()).foregroundStyle(Color.theme.danger).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.danger.opacity(0.08)))
            }
        }.padding(.horizontal, 20)
    }
}
