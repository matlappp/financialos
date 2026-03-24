// SafeSpaceView.swift
// Financial.OS — SafeSpace: AI Financial Advisor Chat

import SwiftUI

struct SafeSpaceView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AIChatVM()
    @FocusState private var isFocused: Bool
    private let typingID = UUID()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("V2")
                    .font(AppFont.label(10))
                    .foregroundStyle(Color.theme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.theme.accentSoft))
                    .padding(.trailing, 20).padding(.top, 4)
            }
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                        
                        if vm.isTyping {
                            typingIndicator.id(typingID)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(vm.messages.last?.id ?? typingID, anchor: .bottom)
                    }
                }
            }
            
            // Quick suggestions
            if vm.messages.count <= 2 {
                quickSuggestions
            }
            
            // Input bar
            inputBar
        }
        .background(Color.theme.background)
        .navigationTitle("SafeSpace")
    }
    
    // MARK: - Message Bubble
    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if msg.isUser { Spacer(minLength: 50) }
            
            if !msg.isUser {
                ZStack {
                    Circle().fill(Color.theme.primaryGradient).frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile").font(.system(size: 14)).foregroundStyle(.white)
                }
            }
            
            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                Text(msg.content)
                    .font(AppFont.body(15))
                    .foregroundStyle(msg.isUser ? .white : Color.theme.textPrimary)
                    .lineSpacing(3)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(msg.isUser ? Color.theme.accent : Color.theme.surface)
                            .shadow(color: .black.opacity(msg.isUser ? 0 : 0.04), radius: 4, y: 2)
                    )
                
                Text(msg.timestamp.timeFormatted)
                    .font(AppFont.caption(10))
                    .foregroundStyle(Color.theme.textTertiary)
            }
            
            if !msg.isUser { Spacer(minLength: 50) }
        }
    }
    
    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.theme.primaryGradient).frame(width: 32, height: 32)
                Image(systemName: "brain.head.profile").font(.system(size: 14)).foregroundStyle(.white)
            }
            
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.theme.textTertiary)
                        .frame(width: 7, height: 7)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: vm.isTyping)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.theme.surface).shadow(color: .black.opacity(0.04), radius: 4, y: 2))
            
            Spacer()
        }
    }
    
    // MARK: - Quick Suggestions
    private var quickSuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                suggestionChip("How's my budget?", "chart.pie.fill")
                suggestionChip("Saving tips", "lightbulb.fill")
                suggestionChip("Investment advice", "chart.line.uptrend.xyaxis")
                suggestionChip("Rebuild my plan", "arrow.clockwise")
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
    
    private func suggestionChip(_ text: String, _ icon: String) -> some View {
        Button {
            vm.inputText = text
            vm.send(profile: appState.user, plan: appState.plan, transactions: [])
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(text).font(AppFont.caption(13))
            }
            .foregroundStyle(Color.theme.accent)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Capsule().fill(Color.theme.accentSoft))
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                HStack {
                    TextField("Ask your AI advisor...", text: $vm.inputText, axis: .vertical)
                        .font(AppFont.body())
                        .lineLimit(1...4)
                        .focused($isFocused)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.theme.surfaceAlt))
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    vm.send(profile: appState.user, plan: appState.plan, transactions: [])
                    isFocused = false
                } label: {
                    ZStack {
                        Circle().fill(vm.inputText.isEmpty ? Color.theme.surfaceAlt : Color.theme.accent).frame(width: 42, height: 42)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(vm.inputText.isEmpty ? Color.theme.textTertiary : .white)
                    }
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.theme.surface)
        }
    }
}

// Helper for timestamp
extension Date {
    var timeFormatted: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: self)
    }
}

