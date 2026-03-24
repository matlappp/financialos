// OnboardingView.swift
// Financial.OS — Multi-step Onboarding

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = OnboardingVM()
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                progressBar
                
                TabView(selection: $vm.step) {
                    profileStep.tag(OnboardingVM.OnboardingStep.profile)
                    goalsStep.tag(OnboardingVM.OnboardingStep.goals)
                    situationStep.tag(OnboardingVM.OnboardingStep.situation)
                    processingStep.tag(OnboardingVM.OnboardingStep.processing)
                    reviewStep.tag(OnboardingVM.OnboardingStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: vm.step)
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            if vm.step.rawValue > 0 && vm.step != .processing {
                Button { vm.back() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.theme.textSecondary)
                }
            }
            Spacer()
            Text(vm.step.title).font(AppFont.subhead()).foregroundStyle(Color.theme.textPrimary)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.theme.surfaceAlt).frame(height: 4)
                Capsule().fill(Color.theme.primaryGradient).frame(width: geo.size.width * vm.progress, height: 4)
                    .animation(.spring(response: 0.5), value: vm.progress)
            }
        }.frame(height: 4).padding(.horizontal, 20)
    }
    
    // MARK: - Step 1: Profile & Income
    private var profileStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)
                
                VStack(spacing: 6) {
                    Text("Let's start with you").font(AppFont.title(24)).foregroundStyle(Color.theme.textPrimary)
                    Text("Enter your income to estimate monthly take-home pay.").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary).multilineTextAlignment(.center)
                }.padding(.horizontal, 24)
                
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        fieldBox("First Name", text: $vm.firstName, placeholder: "John")
                        fieldBox("Last Name", text: $vm.lastName, placeholder: "Doe")
                    }
                    fieldBox("Email", text: $vm.email, placeholder: "john@example.com", keyboard: .emailAddress)
                    fieldBox("Gross Income (per pay period)", text: $vm.grossText, placeholder: "1,200", keyboard: .decimalPad, prefix: "$")
                    
                    // Pay frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pay Frequency").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(PayFrequency.allCases, id: \.self) { f in
                                Button { vm.payFreq = f; vm.calcIncome() } label: {
                                    Text(f.rawValue).font(AppFont.caption(12))
                                        .foregroundStyle(vm.payFreq == f ? .white : Color.theme.textSecondary)
                                        .padding(.horizontal, 12).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(vm.payFreq == f ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 24)
                
                // Income estimate
                if vm.netMonthly > 0 {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EST. NET MONTHLY").sectionLabel()
                                Text(vm.netMonthly.asCurrency).font(AppFont.currency(34)).foregroundStyle(Color.theme.primary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("TAX RATE").sectionLabel()
                                Text("\(String(format: "%.1f", vm.taxRate * 100))%").font(AppFont.heading()).foregroundStyle(Color.theme.danger)
                            }
                        }
                        
                        Divider()
                        
                        HStack(spacing: 20) {
                            miniStat("Annual Gross", (vm.netMonthly / (1 - vm.taxRate) * 12).asCurrencyShort)
                            miniStat("Monthly Gross", (vm.netMonthly / (1 - vm.taxRate)).asCurrencyShort)
                            miniStat("Est. Deductions", (vm.netMonthly / (1 - vm.taxRate) - vm.netMonthly).asCurrencyShort)
                        }
                    }
                    .padding(20)
                    .card()
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); vm.next() } label: {
                    Text("Continue").primaryButton(vm.canProceedProfile)
                }.disabled(!vm.canProceedProfile).padding(.horizontal, 24)
                
                Spacer().frame(height: 40)
            }
        }
        .onChange(of: vm.grossText) { _ in vm.calcIncome() }
        .onChange(of: vm.payFreq) { _ in vm.calcIncome() }
    }
    
    // MARK: - Step 2: Goals
    private var goalsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)
                VStack(spacing: 6) {
                    Text("Financial Goals").font(AppFont.title(24)).foregroundStyle(Color.theme.textPrimary)
                    Text("What are you working towards?").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary)
                }
                
                VStack(spacing: 14) {
                    fieldBox("Financial Goal", text: $vm.q.financialGoal, placeholder: "e.g. Emergency fund, down payment...")
                    fieldBox("Target Amount", text: $vm.goalAmtText, placeholder: "10,000", keyboard: .decimalPad, prefix: "$")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Frame").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(GoalTimeFrame.allCases, id: \.self) { tf in
                                Button { vm.q.timeFrame = tf } label: {
                                    Text(tf.rawValue).font(AppFont.caption(13))
                                        .foregroundStyle(vm.q.timeFrame == tf ? .white : Color.theme.textSecondary)
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(vm.q.timeFrame == tf ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                    
                    fieldBox("Current Savings", text: $vm.savingsText, placeholder: "0", keyboard: .decimalPad, prefix: "$")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Risk Tolerance").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(RiskTolerance.allCases, id: \.self) { r in
                                Button { vm.q.riskTolerance = r } label: {
                                    Text(r.rawValue).font(AppFont.caption(13))
                                        .foregroundStyle(vm.q.riskTolerance == r ? .white : Color.theme.textSecondary)
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(vm.q.riskTolerance == r ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 24)
                
                Button { vm.next() } label: { Text("Continue").primaryButton(vm.canProceedGoals) }
                    .disabled(!vm.canProceedGoals).padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    // MARK: - Step 3: Situation
    private var situationStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)
                VStack(spacing: 6) {
                    Text("Your Situation").font(AppFont.title(24)).foregroundStyle(Color.theme.textPrimary)
                    Text("Help our AI understand your finances.").font(AppFont.body()).foregroundStyle(Color.theme.textSecondary)
                }
                
                VStack(spacing: 14) {
                    fieldBox("Monthly Fixed Expenses", text: $vm.expensesText, placeholder: "800", keyboard: .decimalPad, prefix: "$")
                    fieldBox("Monthly Debt Payments", text: $vm.debtText, placeholder: "0", keyboard: .decimalPad, prefix: "$")
                    fieldBox("Monthly Rent / Mortgage", text: $vm.rentText, placeholder: "1,000", keyboard: .decimalPad, prefix: "$")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Housing Type").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(HousingType.allCases, id: \.self) { h in
                                Button { vm.q.housingType = h } label: {
                                    Text(h.rawValue).font(AppFont.caption(12))
                                        .foregroundStyle(vm.q.housingType == h ? .white : Color.theme.textSecondary)
                                        .padding(.horizontal, 10).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(vm.q.housingType == h ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                    
                    Toggle("Do you have an emergency fund?", isOn: $vm.q.hasEmergencyFund)
                        .font(AppFont.body()).foregroundStyle(Color.theme.textPrimary).tint(Color.theme.accent)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Investment Experience").font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(InvestmentExperience.allCases, id: \.self) { e in
                                Button { vm.q.investmentExperience = e } label: {
                                    Text(e.rawValue).font(AppFont.caption(12))
                                        .foregroundStyle(vm.q.investmentExperience == e ? .white : Color.theme.textSecondary)
                                        .padding(.horizontal, 10).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(vm.q.investmentExperience == e ? Color.theme.accent : Color.theme.surfaceAlt))
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 24)
                
                Button {
                    vm.next()
                    vm.isLoading = true
                    Task {
                        if let (profile, plan) = await vm.generatePlan() {
                            await MainActor.run { vm.isLoading = false; vm.next() }
                        }
                    }
                } label: { Text("Generate My Plan").primaryButton() }
                .padding(.horizontal, 24)
                Spacer().frame(height: 40)
            }
        }
    }
    
    // MARK: - Step 4: Processing
    private var processingStep: some View {
        VStack(spacing: 32) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.theme.accent)
            
            VStack(spacing: 12) {
                Text("Analyzing Your Finances").font(AppFont.heading()).foregroundStyle(Color.theme.textPrimary)
                Text("Our AI is building a personalized\nfinancial strategy just for you...")
                    .font(AppFont.body()).foregroundStyle(Color.theme.textSecondary).multilineTextAlignment(.center)
            }
            
            // Processing steps animation
            VStack(alignment: .leading, spacing: 14) {
                processingItem("Calculating net income", done: true)
                processingItem("Analyzing financial profile", done: true)
                processingItem("Generating budget allocation", done: vm.isLoading)
                processingItem("Creating milestone plan", done: false)
                processingItem("Building weekly actions", done: false)
            }
            .padding(24).card().padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func processingItem(_ text: String, done: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? Color.theme.success : Color.theme.textTertiary)
                .font(.system(size: 16))
            Text(text).font(AppFont.body()).foregroundStyle(done ? Color.theme.textPrimary : Color.theme.textTertiary)
        }
    }
    
    // MARK: - Step 5: Plan Review
    private var reviewStep: some View {
        ScrollView(showsIndicators: false) {
            if let plan = vm.generatedPlan {
                VStack(spacing: 20) {
                    Spacer().frame(height: 20)
                    
                    // Title card
                    VStack(spacing: 12) {
                        Text("TIMELINE").sectionLabel()
                        Text(plan.title).font(AppFont.title(22)).foregroundStyle(Color.theme.textPrimary).multilineTextAlignment(.center)
                        
                        HStack {
                            VStack(spacing: 4) {
                                Text("TARGET").sectionLabel()
                                Text(plan.goalAmount.asCurrency).font(AppFont.currency(28)).foregroundStyle(Color.theme.primary)
                            }
                            Spacer()
                            VStack(spacing: 4) {
                                Text("MONTHLY SAVINGS").sectionLabel()
                                Text(plan.monthlyBudget.savings.asCurrency).font(AppFont.heading()).foregroundStyle(Color.theme.success)
                            }
                        }
                    }.padding(20).card().padding(.horizontal, 24)
                    
                    // Summary
                    Text(plan.summary).font(AppFont.body()).foregroundStyle(Color.theme.textSecondary).padding(.horizontal, 24).lineSpacing(3)
                    
                    // Milestones preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MILESTONES").sectionLabel()
                        ForEach(plan.milestones) { m in
                            HStack {
                                Circle().fill(Color.theme.accent).frame(width: 8, height: 8)
                                Text(m.title).font(AppFont.body()).foregroundStyle(Color.theme.textPrimary)
                                Spacer()
                                Text(m.targetAmount.asCurrencyShort).font(AppFont.subhead()).foregroundStyle(Color.theme.accent)
                            }
                        }
                    }.padding(20).card().padding(.horizontal, 24)
                    
                    // Launch button
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        let gross = Double(vm.grossText.replacingOccurrences(of: ",", with: "")) ?? 0
                        let profile = UserProfile(firstName: vm.firstName, lastName: vm.lastName, email: vm.email,
                                                  monthlyNetIncome: vm.netMonthly, grossIncome: gross,
                                                  payFrequency: vm.payFreq, estimatedTaxRate: vm.taxRate)
                        withAnimation { appState.completeOnboarding(profile, plan) }
                    } label: {
                        HStack {
                            Image(systemName: "rocket.fill")
                            Text("Launch My Plan")
                        }.primaryButton()
                    }.padding(.horizontal, 24)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func fieldBox(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default, prefix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(AppFont.caption()).foregroundStyle(Color.theme.textSecondary)
            HStack(spacing: 8) {
                if let pre = prefix {
                    Text(pre).font(AppFont.body()).foregroundStyle(Color.theme.textTertiary)
                }
                TextField(placeholder, text: text)
                    .font(AppFont.body())
                    .keyboardType(keyboard)
                    .foregroundStyle(Color.theme.textPrimary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.surfaceAlt))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.theme.accent.opacity(0.1), lineWidth: 1))
        }
    }
    
    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label).font(AppFont.caption(10)).foregroundStyle(Color.theme.textTertiary)
            Text(value).font(AppFont.subhead(14)).foregroundStyle(Color.theme.textPrimary)
        }.frame(maxWidth: .infinity)
    }
}
