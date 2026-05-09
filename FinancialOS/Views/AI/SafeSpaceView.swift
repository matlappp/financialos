// SafeSpaceView.swift — AI Financial Advisor (Human-like, FR/EN)
import SwiftUI
struct SafeSpaceView: View {
    @EnvironmentObject var appState: AppState; @EnvironmentObject var workVM: WorkplaceVM; @EnvironmentObject var agendaVM: AgendaVM
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var vm = AIChatVM(); @FocusState private var focused: Bool
    private var fr: Bool { themeManager.language == .fr }
    var body: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Text("V2").font(AppFont.label(10)).foregroundStyle(Color.theme.accent).padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Color.theme.accentSoft)).padding(.trailing, 20).padding(.top, 4) }
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) { LazyVStack(spacing: 10) { ForEach(vm.messages) { m in bubble(m).id(m.id) }
                    if vm.isTyping { typing.id("typing_indicator") } }.padding(.horizontal, 14).padding(.vertical, 10) }
                .onChange(of: vm.messages.count) { _ in
                    if let lastId = vm.messages.last?.id { withAnimation { proxy.scrollTo(lastId, anchor: .bottom) } }
                }
            }
            if vm.messages.count <= 2 { suggestions }
            inputBar
        }.background(Color.theme.background).navigationTitle(L10n.safeSpace)
    }
    private func bubble(_ m: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if m.isUser { Spacer(minLength: 44) }
            if !m.isUser { ZStack { Circle().fill(Color.theme.primaryGradient).frame(width: 30, height: 30); Image(systemName: "brain.head.profile").font(.system(size: 13)).foregroundStyle(.white) } }
            VStack(alignment: m.isUser ? .trailing : .leading, spacing: 3) {
                Text(m.content).font(AppFont.body(14)).foregroundStyle(m.isUser ? .white : Color.theme.textPrimary).lineSpacing(3)
                    .padding(12).background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(m.isUser ? Color.theme.accent : Color.theme.surface).shadow(color: .black.opacity(m.isUser ? 0 : 0.04), radius: 3, y: 1))
                Text(m.timestamp.timeFormatted).font(AppFont.caption(9)).foregroundStyle(Color.theme.textTertiary)
            }
            if !m.isUser { Spacer(minLength: 44) }
        }
    }
    private var typing: some View {
        HStack(spacing: 8) { ZStack { Circle().fill(Color.theme.primaryGradient).frame(width: 30, height: 30); Image(systemName: "brain.head.profile").font(.system(size: 13)).foregroundStyle(.white) }
            HStack(spacing: 4) { ForEach(0..<3, id: \.self) { i in Circle().fill(Color.theme.textTertiary).frame(width: 6, height: 6).opacity(0.6) } }
            .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.surface).shadow(color: .black.opacity(0.04), radius: 3, y: 1)); Spacer() }
    }
    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 7) {
            chip(fr ? "Mon budget?" : "My budget?", "chart.pie.fill")
            chip(fr ? "Prédiction fin de mois" : "Month-end prediction", "wand.and.stars")
            chip(fr ? "Comparer les mois" : "Compare months", "arrow.left.arrow.right")
            chip(fr ? "Conseils épargne" : "Saving tips", "lightbulb.fill")
            chip(fr ? "Investissement" : "Investment advice", "chart.line.uptrend.xyaxis")
            chip(fr ? "Reconstruire mon plan" : "Rebuild plan", "arrow.clockwise")
        }.padding(.horizontal, 14) }.padding(.bottom, 6)
    }
    private func chip(_ t: String, _ i: String) -> some View {
        Button { vm.inputText = t; vm.send(profile: appState.user, plan: appState.plan, transactions: workVM.transactions, bills: agendaVM.bills) } label: {
            HStack(spacing: 4) { Image(systemName: i).font(.system(size: 11)); Text(t).font(AppFont.caption(12)) }.foregroundStyle(Color.theme.accent).padding(.horizontal, 12).padding(.vertical, 8).background(Capsule().fill(Color.theme.accentSoft)) }
    }
    private var inputBar: some View {
        VStack(spacing: 0) { Divider()
            HStack(spacing: 10) {
                TextField(L10n.askAdvisor, text: $vm.inputText, axis: .vertical).font(AppFont.body()).lineLimit(1...4).focused($focused).padding(10).background(RoundedRectangle(cornerRadius: 20).fill(Color.theme.surfaceAlt))
                Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); vm.send(profile: appState.user, plan: appState.plan, transactions: workVM.transactions, bills: agendaVM.bills); focused = false } label: {
                    ZStack { Circle().fill(vm.inputText.isEmpty ? Color.theme.surfaceAlt : Color.theme.accent).frame(width: 40, height: 40)
                        Image(systemName: "arrow.up").font(.system(size: 15, weight: .semibold)).foregroundStyle(vm.inputText.isEmpty ? Color.theme.textTertiary : .white) }
                }.disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }.padding(.horizontal, 14).padding(.vertical, 8).background(Color.theme.surface) }
    }
}
