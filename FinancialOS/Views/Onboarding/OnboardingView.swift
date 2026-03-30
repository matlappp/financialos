// OnboardingView.swift
// Financial.OS — 8-Step Onboarding (Data Method → Profile → Goals → Housing → Debt/Insurance → Savings → AI → Review)

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = OnboardingVM()
    private var fr: Bool { ThemeManager.shared.language == .fr }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header; progressBar
                TabView(selection: $vm.step) {
                    dataMethodStep.tag(OnboardingVM.Step.dataMethod)
                    profileStep.tag(OnboardingVM.Step.profile)
                    goalsStep.tag(OnboardingVM.Step.goals)
                    housingStep.tag(OnboardingVM.Step.housing)
                    debtInsuranceStep.tag(OnboardingVM.Step.debtInsurance)
                    savingsSubsStep.tag(OnboardingVM.Step.savingsSubs)
                    processingStep.tag(OnboardingVM.Step.processing)
                    reviewStep.tag(OnboardingVM.Step.review)
                }.tabViewStyle(.page(indexDisplayMode: .never)).animation(.easeInOut, value: vm.step)
            }
        }
    }
    
    private var header: some View {
        HStack {
            if vm.step.rawValue > 0 && vm.step != .processing {
                Button { vm.back() } label: { Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.theme.textSecondary) }
            }
            Spacer(); Text(vm.step.title).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary); Spacer()
            Color.clear.frame(width: 24, height: 24)
        }.padding(.horizontal, 20).padding(.vertical, 12)
    }
    
    private var progressBar: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.theme.surfaceAlt).frame(height: 4)
                Capsule().fill(Color.theme.primaryGradient).frame(width: g.size.width * vm.progress, height: 4).animation(.spring(response: 0.5), value: vm.progress)
            }
        }.frame(height: 4).padding(.horizontal, 20)
    }
    
    // MARK: - Step 0: Data Entry Method
    private var dataMethodStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer().frame(height: 30)
                Image(systemName: "arrow.triangle.branch").font(.system(size: 40)).foregroundStyle(Color.theme.accent)
                Text(fr ? "Comment souhaitez-vous entrer vos données?" : "How would you like to enter your data?").font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary).multilineTextAlignment(.center)
                
                // Manual option
                methodCard(icon: "pencil.and.list.clipboard", title: L10n.manualEntry,
                          desc: fr ? "Entrez manuellement chaque transaction et information financière pour un contrôle total." : "Manually enter every transaction and financial detail for full control.",
                          selected: vm.dataMethod == .manual) { vm.dataMethod = .manual }
                
                // Bank Link option
                methodCard(icon: "building.columns.fill", title: L10n.linkBank,
                          desc: fr ? "Connectez votre compte bancaire pour importer automatiquement vos transactions. (Buddy, YNAB, Plaid)" : "Connect your bank to auto-import transactions. (Buddy, YNAB, Plaid)",
                          selected: vm.dataMethod == .bankLink, badge: "BETA") { vm.dataMethod = .bankLink }
                
                if vm.dataMethod == .bankLink {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundStyle(Color.theme.info)
                        Text(fr ? "L'intégration bancaire nécessite un partenaire comme Plaid ou MX. Pour l'instant, tu peux aussi utiliser la saisie manuelle." : "Bank integration requires a partner like Plaid or MX. For now, you can also use manual entry.")
                            .font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary)
                    }.padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.info.opacity(0.08))).padding(.horizontal, 24)
                }
                
                Button { vm.next() } label: { Text(L10n.continueBtn).primaryButton() }.padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    private func methodCard(icon: String, title: String, desc: String, selected: Bool, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(selected ? Color.theme.accent.opacity(0.12) : Color.theme.surfaceAlt).frame(width: 50, height: 50)
                    Image(systemName: icon).font(.system(size: 20)).foregroundStyle(selected ? Color.theme.accent : Color.theme.textTertiary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
                        if let b = badge { Text(b).font(AppFont.label(9)).foregroundStyle(Color.theme.accent).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.theme.accentSoft)) }
                    }
                    Text(desc).font(AppFont.caption(12)).foregroundStyle(Color.theme.textSecondary).lineLimit(3)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.system(size: 22)).foregroundStyle(selected ? Color.theme.accent : Color.theme.textTertiary)
            }.padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.surface).overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Color.theme.accent : Color.clear, lineWidth: 2)))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }.padding(.horizontal, 24)
    }
    
    // MARK: - Step 1: Profile & Income
    private var profileStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer().frame(height: 16)
                Text(L10n.letsStart).font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
                Text(L10n.incomeDesc).font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    HStack(spacing: 10) { field(fr ? "Prénom" : "First Name", $vm.firstName, "John"); field(fr ? "Nom" : "Last Name", $vm.lastName, "Doe") }
                    field("Email", $vm.email, "john@example.com", kb: .emailAddress)
                    field(fr ? "Revenu brut (par paie)" : "Gross Income (per pay)", $vm.grossText, "1,200", kb: .decimalPad, pre: "$")
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fr ? "Fréquence de paie" : "Pay Frequency").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 6) { ForEach(PayFrequency.allCases, id: \.self) { f in
                            Button { vm.payFreq = f; vm.calcIncome() } label: {
                                Text(f.label).font(AppFont.caption(11)).foregroundStyle(vm.payFreq == f ? .white : Color.theme.textSecondary)
                                    .padding(.horizontal, 10).padding(.vertical, 9).background(RoundedRectangle(cornerRadius: 8).fill(vm.payFreq == f ? Color.theme.accent : Color.theme.surfaceAlt))
                            }
                        }}
                    }
                }.padding(.horizontal, 24)
                
                if vm.netMonthly > 0 {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) { Text(fr ? "REVENU NET MENSUEL EST." : "EST. NET MONTHLY").sectionLabel()
                                Text(vm.netMonthly.asCurrency).font(AppFont.currency(32)).foregroundStyle(Color.theme.primary) }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) { Text(fr ? "TAUX D'IMPÔT" : "TAX RATE").sectionLabel()
                                Text("\(String(format: "%.1f", vm.taxRate * 100))%").font(AppFont.heading()).foregroundStyle(Color.theme.danger) }
                        }
                        Divider()
                        HStack(spacing: 16) {
                            miniStat(fr ? "Brut Annuel" : "Annual Gross", (vm.netMonthly / (1 - vm.taxRate) * 12).asCurrencyShort)
                            miniStat(fr ? "Brut Mensuel" : "Monthly Gross", (vm.netMonthly / (1 - vm.taxRate)).asCurrencyShort)
                            miniStat(fr ? "Déductions" : "Deductions", (vm.netMonthly / (1 - vm.taxRate) - vm.netMonthly).asCurrencyShort)
                        }
                    }.padding(18).card().padding(.horizontal, 24).transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Button { vm.next() } label: { Text(L10n.continueBtn).primaryButton(vm.canProceedProfile) }.disabled(!vm.canProceedProfile).padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
        .onChange(of: vm.grossText) { _ in vm.calcIncome() }
        .onChange(of: vm.payFreq) { _ in vm.calcIncome() }
    }
    
    // MARK: - Step 2: Goals
    private var goalsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer().frame(height: 16)
                Text(L10n.financialGoals).font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
                VStack(spacing: 12) {
                    field(fr ? "Objectif financier" : "Financial Goal", $vm.q.financialGoal, fr ? "Ex: Fonds d'urgence, mise de fonds..." : "e.g. Emergency fund, down payment...")
                    field(fr ? "Description de l'objectif" : "Goal Description", $vm.q.goalDescription, fr ? "Décris ton objectif en détail..." : "Describe your goal in detail...")
                    field(fr ? "Montant cible" : "Target Amount", $vm.goalAmtText, "10,000", kb: .decimalPad, pre: "$")
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fr ? "Période" : "Time Frame").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(GoalTimeFrame.allCases, id: \.self) { tf in
                                Button { vm.q.timeFrame = tf } label: {
                                    Text(tf.rawValue).font(AppFont.caption(12)).foregroundStyle(vm.q.timeFrame == tf ? .white : Color.theme.textSecondary)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(vm.q.timeFrame == tf ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                    
                    field(fr ? "Épargne actuelle" : "Current Savings", $vm.savingsText, "0", kb: .decimalPad, pre: "$")
                    
                    Toggle(fr ? "Source de revenu supplémentaire?" : "Additional income source?", isOn: $vm.q.additionalIncomeSource).font(AppFont.body(14)).tint(Color.theme.accent)
                    if vm.q.additionalIncomeSource {
                        field(fr ? "Montant additionnel/mois" : "Additional monthly amount", $vm.addlIncomeText, "300", kb: .decimalPad, pre: "$")
                        field(fr ? "Description" : "Description", $vm.q.additionalIncomeDescription, fr ? "Ex: Freelance, vente..." : "e.g. Freelance, sales...")
                    }
                }.padding(.horizontal, 24)
                Button { vm.next() } label: { Text(L10n.continueBtn).primaryButton(vm.canProceedGoals) }.disabled(!vm.canProceedGoals).padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    // MARK: - Step 3: Housing & Essential Expenses
    private var housingStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer().frame(height: 16)
                Text(fr ? "Logement & Dépenses Essentielles" : "Housing & Essentials").font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
                Text(fr ? "On veut connaître toutes tes dépenses indispensables par mois." : "We need to know all your essential monthly expenses.").font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fr ? "Type de logement" : "Housing Type").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 6) { ForEach(HousingType.allCases, id: \.self) { h in
                            Button { vm.q.housingType = h } label: {
                                Text(h.rawValue).font(AppFont.caption(11)).foregroundStyle(vm.q.housingType == h ? .white : Color.theme.textSecondary)
                                    .padding(.horizontal, 10).padding(.vertical, 9).background(RoundedRectangle(cornerRadius: 8).fill(vm.q.housingType == h ? Color.theme.accent : Color.theme.surfaceAlt))
                            }
                        }}
                    }
                    field(fr ? "Loyer / Hypothèque" : "Rent / Mortgage", $vm.rentText, "1,000", kb: .decimalPad, pre: "$")
                    field(fr ? "Services publics (Hydro, gaz...)" : "Utilities (Electric, gas...)", $vm.utilitiesText, "120", kb: .decimalPad, pre: "$")
                    field(fr ? "Épicerie / Alimentation" : "Groceries / Food", $vm.groceriesText, "400", kb: .decimalPad, pre: "$")
                    field(fr ? "Transport" : "Transport", $vm.transportText, "100", kb: .decimalPad, pre: "$")
                    field(fr ? "Téléphone" : "Phone", $vm.phoneText, "65", kb: .decimalPad, pre: "$")
                    field(fr ? "Internet" : "Internet", $vm.internetText, "60", kb: .decimalPad, pre: "$")
                    
                    Stepper(fr ? "Personnes à charge: \(vm.q.dependents)" : "Dependents: \(vm.q.dependents)", value: $vm.q.dependents, in: 0...10).font(AppFont.body(14))
                    if vm.q.dependents > 0 {
                        Toggle(fr ? "Dépenses liées aux personnes à charge?" : "Dependent-related expenses?", isOn: $vm.q.hasDependentExpenses).font(AppFont.body(14)).tint(Color.theme.accent)
                        if vm.q.hasDependentExpenses {
                            field(fr ? "Coût mensuel pour les dépendants" : "Monthly dependent cost", $vm.dependentCostText, "500", kb: .decimalPad, pre: "$")
                        }
                    }
                }.padding(.horizontal, 24)
                Button { vm.next() } label: { Text(L10n.continueBtn).primaryButton() }.padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    // MARK: - Step 4: Debt & Insurance (Conditional)
    private var debtInsuranceStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer().frame(height: 16)
                Text(fr ? "Dettes & Assurances" : "Debt & Insurance").font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
                
                VStack(spacing: 12) {
                    // DEBT SECTION
                    Toggle(fr ? "As-tu des dettes?" : "Do you have any debt?", isOn: $vm.q.hasDebt).font(AppFont.body(14)).tint(Color.theme.accent)
                    if vm.q.hasDebt {
                        field(fr ? "Paiements mensuels de dette" : "Monthly debt payments", $vm.debtText, "200", kb: .decimalPad, pre: "$")
                        field(fr ? "Solde total de dette" : "Total debt balance", $vm.debtBalanceText, "5,000", kb: .decimalPad, pre: "$")
                        field(fr ? "Taux d'intérêt le plus élevé (%)" : "Highest interest rate (%)", $vm.interestRateText, "19.99", kb: .decimalPad)
                    }
                    
                    // CAR
                    Toggle(fr ? "Paiement de voiture?" : "Car payment?", isOn: $vm.q.hasCarPayment).font(AppFont.body(14)).tint(Color.theme.accent)
                    if vm.q.hasCarPayment {
                        field(fr ? "Paiement mensuel auto" : "Monthly car payment", $vm.carPaymentText, "350", kb: .decimalPad, pre: "$")
                        field(fr ? "Assurance auto mensuelle" : "Monthly car insurance", $vm.carInsuranceText, "95", kb: .decimalPad, pre: "$")
                    }
                    
                    // INSURANCE
                    Toggle(fr ? "As-tu des assurances?" : "Do you have insurance?", isOn: $vm.q.hasInsurance).font(AppFont.body(14)).tint(Color.theme.accent)
                    if vm.q.hasInsurance {
                        ForEach(vm.q.insuranceTypes) { ins in
                            HStack {
                                Image(systemName: "shield.fill").foregroundStyle(Color.theme.info)
                                Text(ins.type.label).font(AppFont.body(14))
                                Spacer()
                                Text(ins.monthlyCost.asCurrency).font(AppFont.subhead(14))
                            }.padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
                        }
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                ForEach(InsuranceType.allCases, id: \.self) { t in
                                    Button { vm.newInsurance.type = t } label: {
                                        Text(t.label).font(AppFont.caption(10)).foregroundStyle(vm.newInsurance.type == t ? .white : Color.theme.textSecondary)
                                            .padding(.horizontal, 8).padding(.vertical, 6).background(RoundedRectangle(cornerRadius: 6).fill(vm.newInsurance.type == t ? Color.theme.accent : Color.theme.surfaceAlt))
                                    }
                                }
                            }
                            HStack(spacing: 8) {
                                TextField(fr ? "Coût/mois" : "Cost/mo", value: $vm.newInsurance.monthlyCost, format: .currency(code: "USD")).keyboardType(.decimalPad).font(AppFont.body(14)).padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.theme.surfaceAlt))
                                Button { vm.addInsurance() } label: { Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundStyle(Color.theme.accent) }
                            }
                        }
                    }
                }.padding(.horizontal, 24)
                Button { vm.next() } label: { Text(L10n.continueBtn).primaryButton() }.padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    // MARK: - Step 5: Savings & Subscriptions
    private var savingsSubsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer().frame(height: 16)
                Text(fr ? "Épargne & Abonnements" : "Savings & Subscriptions").font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary)
                
                VStack(spacing: 12) {
                    Toggle(fr ? "Fonds d'urgence existant?" : "Existing emergency fund?", isOn: $vm.q.hasEmergencyFund).font(AppFont.body(14)).tint(Color.theme.accent)
                    if vm.q.hasEmergencyFund {
                        field(fr ? "Montant actuel du fonds" : "Current fund amount", $vm.emergencyFundAmtText, "2,000", kb: .decimalPad, pre: "$")
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fr ? "Expérience investissement" : "Investment Experience").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 6) { ForEach(InvestmentExperience.allCases, id: \.self) { e in
                            Button { vm.q.investmentExperience = e } label: {
                                Text(e.rawValue).font(AppFont.caption(11)).foregroundStyle(vm.q.investmentExperience == e ? .white : Color.theme.textSecondary)
                                    .padding(.horizontal, 10).padding(.vertical, 9).background(RoundedRectangle(cornerRadius: 8).fill(vm.q.investmentExperience == e ? Color.theme.accent : Color.theme.surfaceAlt))
                            }
                        }}
                    }
                    
                    // Subscriptions
                    Text(fr ? "ABONNEMENTS MENSUELS" : "MONTHLY SUBSCRIPTIONS").sectionLabel()
                    ForEach(vm.q.monthlySubscriptions) { sub in
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Color.theme.subscription)
                            Text(sub.name).font(AppFont.body(14))
                            Spacer()
                            Text(sub.amount.asCurrency).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
                        }.padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
                    }
                    
                    if !vm.q.monthlySubscriptions.isEmpty {
                        HStack {
                            Text(fr ? "Total abonnements:" : "Total subscriptions:").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                            Spacer()
                            Text(vm.q.totalSubscriptionCost.asCurrency).font(AppFont.subhead()).foregroundStyle(Color.theme.accent)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        TextField(fr ? "Nom (Netflix, Spotify...)" : "Name (Netflix, Spotify...)", text: $vm.newSubscription.name).font(AppFont.body(13)).padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.theme.surfaceAlt))
                        TextField("$", value: $vm.newSubscription.amount, format: .currency(code: "USD")).keyboardType(.decimalPad).font(AppFont.body(13)).frame(width: 80).padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.theme.surfaceAlt))
                        Button { vm.addSubscription() } label: { Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundStyle(Color.theme.accent) }
                    }
                    
                    field(fr ? "Notes additionnelles" : "Additional notes", $vm.q.additionalNotes, fr ? "Autre chose qu'on devrait savoir?" : "Anything else we should know?")
                }.padding(.horizontal, 24)
                
                Button {
                    vm.next()
                    Task { if let _ = await vm.generatePlan() { await MainActor.run { vm.next() } } }
                } label: { Text(L10n.generatePlan).primaryButton() }.padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    // MARK: - Processing
    private var processingStep: some View {
        VStack(spacing: 32) {
            Spacer()
            ProgressView().scaleEffect(1.5).tint(Color.theme.accent)
            VStack(spacing: 10) {
                Text(fr ? "Analyse de tes finances" : "Analyzing Your Finances").font(AppFont.heading()).foregroundStyle(Color.theme.textPrimary)
                Text(fr ? "Notre IA construit une stratégie\npersonnalisée juste pour toi..." : "Our AI is building a personalized\nstrategy just for you...").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 12) {
                procItem(fr ? "Calcul du revenu net" : "Calculating net income", true)
                procItem(fr ? "Analyse du profil financier" : "Analyzing financial profile", true)
                procItem(fr ? "Évaluation des dépenses essentielles" : "Evaluating essential expenses", true)
                procItem(fr ? "Analyse des dettes et assurances" : "Analyzing debt & insurance", true)
                procItem(fr ? "Génération du plan budgétaire" : "Generating budget plan", false)
                procItem(fr ? "Création du plan d'action" : "Building action plan", false)
            }.padding(20).card().padding(.horizontal, 32)
            Spacer()
        }
    }
    
    private func procItem(_ text: String, _ done: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle").foregroundStyle(done ? Color.theme.success : Color.theme.textTertiary)
            Text(text).font(AppFont.body(14)).foregroundStyle(done ? Color.theme.textPrimary : Color.theme.textTertiary)
        }
    }
    
    // MARK: - Review
    private var reviewStep: some View {
        ScrollView(showsIndicators: false) {
            if let plan = vm.generatedPlan {
                VStack(spacing: 18) {
                    Spacer().frame(height: 16)
                    VStack(spacing: 10) {
                        Text("TIMELINE").sectionLabel()
                        Text(plan.title).font(AppFont.title(20)).foregroundStyle(Color.theme.textPrimary).multilineTextAlignment(.center)
                        HStack {
                            VStack(spacing: 3) { Text("TARGET").sectionLabel(); Text(plan.goalAmount.asCurrency).font(AppFont.currency(26)).foregroundStyle(Color.theme.primary) }
                            Spacer()
                            VStack(spacing: 3) { Text(fr ? "ÉPARGNE/MOIS" : "MONTHLY SAVINGS").sectionLabel(); Text(plan.monthlyBudget.savings.asCurrency).font(AppFont.heading()).foregroundStyle(Color.theme.success) }
                        }
                    }.padding(18).card().padding(.horizontal, 24)
                    
                    Text(plan.summary).font(AppFont.body(14)).foregroundStyle(Color.theme.textSecondary).padding(.horizontal, 24).lineSpacing(3)
                    
                    // Essential expenses summary
                    VStack(alignment: .leading, spacing: 10) {
                        Text(fr ? "DÉPENSES ESSENTIELLES DÉTECTÉES" : "DETECTED ESSENTIAL EXPENSES").sectionLabel()
                        Text(vm.q.totalEssentialExpenses.asCurrency).font(AppFont.currency(22)).foregroundStyle(Color.theme.danger)
                        Text(fr ? "par mois en dépenses obligatoires" : "per month in mandatory expenses").font(AppFont.caption()).foregroundStyle(Color.theme.textTertiary)
                    }.padding(18).card().padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(fr ? "JALONS" : "MILESTONES").sectionLabel()
                        ForEach(plan.milestones) { m in
                            HStack { Circle().fill(Color.theme.accent).frame(width: 8, height: 8)
                                Text(m.title).font(AppFont.body(14)).foregroundStyle(Color.theme.textPrimary); Spacer()
                                Text(m.targetAmount.asCurrencyShort).font(AppFont.subhead(14)).foregroundStyle(Color.theme.accent) }
                        }
                    }.padding(18).card().padding(.horizontal, 24)
                    
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        let gross = Double(vm.grossText.replacingOccurrences(of: ",", with: "")) ?? 0
                        let profile = UserProfile(firstName: vm.firstName, lastName: vm.lastName, email: vm.email,
                                                  monthlyNetIncome: vm.netMonthly, grossIncome: gross,
                                                  payFrequency: vm.payFreq, estimatedTaxRate: vm.taxRate, dataEntryMethod: vm.dataMethod)
                        withAnimation { appState.completeOnboarding(profile, plan) }
                    } label: { HStack { Image(systemName: "rocket.fill"); Text(L10n.launchPlan) }.primaryButton() }.padding(.horizontal, 24)
                    Spacer().frame(height: 40)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func field(_ title: String, _ text: Binding<String>, _ ph: String, kb: UIKeyboardType = .default, pre: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
            HStack(spacing: 6) {
                if let p = pre { Text(p).font(AppFont.body()).foregroundStyle(Color.theme.textTertiary) }
                TextField(ph, text: text).font(AppFont.body()).keyboardType(kb).foregroundStyle(Color.theme.textPrimary)
            }.padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.surfaceAlt))
        }
    }
    
    private func miniStat(_ l: String, _ v: String) -> some View {
        VStack(spacing: 2) { Text(l).font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary); Text(v).font(AppFont.subhead(13)).foregroundStyle(Color.theme.textPrimary) }.frame(maxWidth: .infinity)
    }
}
