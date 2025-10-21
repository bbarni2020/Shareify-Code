import SwiftUI

struct SharAIView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @Binding var isOpen: Bool
    @State private var userInput = ""
    @State private var chatMessages: [DisplayMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedModel = "meta-llama/llama-4-maverick"
    @State private var showModelPicker = false
    @State private var includeContext = true
    
    private let availableModels = [
        "meta-llama/llama-4-maverick",
        "openai/gpt-oss-120b",
        "openai/gpt-oss-20b",
        "moonshotai/kimi-k2-instruct-0905"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccentMuted],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("SharAI")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    
                    Button(action: { showModelPicker.toggle() }) {
                        HStack(spacing: 4) {
                            Text(shortModelName(selectedModel))
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(Color.appTextTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.appCodeBackground)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showModelPicker) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(availableModels, id: \.self) { model in
                                Button(action: {
                                    selectedModel = model
                                    showModelPicker = false
                                }) {
                                    HStack {
                                        Text(shortModelName(model))
                                            .font(.system(size: 13))
                                        Spacer()
                                        if model == selectedModel {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                    }
                                    .foregroundStyle(Color.appTextPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                        .background(Color.appSurface)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    chatMessages.removeAll()
                    errorMessage = nil
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.appSurfaceElevated)
                        )
                }
                .buttonStyle(.plain)
                .disabled(chatMessages.isEmpty)
                
                Button(action: {
                    withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                        isOpen = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.appSurfaceElevated)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.spacingL)
            .padding(.vertical, Theme.spacingM)
            .background(
                Color.appSurface
                    .overlay(
                        Rectangle()
                            .fill(Color.appBorderSubtle)
                            .frame(height: 1)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    )
            )

            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    if let error = errorMessage {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.orange)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .padding(Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.top, Theme.spacingM)
                    }
                    
                    if chatMessages.isEmpty {
                        VStack(spacing: Theme.spacingXL) {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent.opacity(0.1))
                                    .frame(width: 96, height: 96)
                                
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.appAccent, Color.appAccentMuted],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: Theme.spacingS) {
                                Text("Your AI Assistant")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                
                                Text("Ask me anything about your code or let me help you write it")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Theme.spacingXL)
                            }
                            
                            VStack(alignment: .leading, spacing: Theme.spacingS) {
                                SuggestionChip(icon: "wand.and.stars", text: "Explain this function", action: {
                                    userInput = "Explain this function"
                                })
                                SuggestionChip(icon: "hammer.fill", text: "Fix this bug", action: {
                                    userInput = "Fix this bug"
                                })
                                SuggestionChip(icon: "lightbulb.fill", text: "Suggest improvements", action: {
                                    userInput = "Suggest improvements"
                                })
                                SuggestionChip(icon: "doc.text.fill", text: "Write documentation", action: {
                                    userInput = "Write documentation"
                                })
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(chatMessages) { message in
                            ChatBubbleView(message: message)
                        }
                        
                        if isLoading {
                            HStack(alignment: .top, spacing: Theme.spacingS) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appAccent.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.appAccent)
                                }
                                
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(Color.appTextTertiary)
                                            .frame(width: 6, height: 6)
                                            .opacity(0.5)
                                    }
                                }
                                .padding(.horizontal, Theme.spacingM)
                                .padding(.vertical, Theme.spacingS)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                        .fill(Color.appSurfaceElevated)
                                )
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .padding(Theme.spacingM)
            }
            
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.appBorderSubtle)
                    .frame(height: 1)
                
                if let activeFile = vm.openFiles.first(where: { $0.id == vm.activeFileID }) {
                    HStack(spacing: Theme.spacingS) {
                        Toggle(isOn: $includeContext) {
                            HStack(spacing: 4) {
                                Image(systemName: includeContext ? "doc.text.fill" : "doc.text")
                                    .font(.system(size: 10))
                                Text("Include \(activeFile.title)")
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.appTextTertiary)
                        }
                        .toggleStyle(.switch)
                        .tint(Color.appAccent)
                    }
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingXS)
                    .background(Color.appSurface)
                }
                
                HStack(spacing: Theme.spacingM) {
                    TextField("Ask SharAI...", text: $userInput, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: Theme.uiFontSize))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .fill(Color.appCodeBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .lineLimit(1...5)
                    
                    Button(action: sendMessage) {
                        ZStack {
                            if isLoading {
                                Circle()
                                    .fill(Color.appTextTertiary.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        ProgressView()
                                            .tint(Color.appTextTertiary)
                                    )
                            } else if userInput.isEmpty {
                                Circle()
                                    .fill(Color.appTextTertiary.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.appTextTertiary)
                                    )
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appAccent, Color.appAccentMuted],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(userInput.isEmpty || isLoading)
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingM)
                .background(Color.appSurface)
            }
        }
        .frame(minWidth: 320, maxWidth: 400, maxHeight: .infinity)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Theme.panelShadow, radius: 32, x: -8, y: 0)
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        var messageContent = userInput
        
        if includeContext, 
           let activeFile = vm.openFiles.first(where: { $0.id == vm.activeFileID }) {
            messageContent = """
            File: \(activeFile.title)
            
            ```
            \(activeFile.content)
            ```
            
            \(userInput)
            """
        }
        
        let userMessage = DisplayMessage(content: userInput, isUser: true)
        chatMessages.append(userMessage)
        
        let currentInput = userInput
        userInput = ""
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                var apiMessages = chatMessages.map { msg in
                    ChatMessage(role: msg.isUser ? "user" : "assistant", content: msg.content)
                }
                
                if includeContext, let activeFile = vm.openFiles.first(where: { $0.id == vm.activeFileID }) {
                    apiMessages[apiMessages.count - 1] = ChatMessage(
                        role: "user",
                        content: messageContent
                    )
                }
                
                let response = try await AIService.shared.sendMessage(
                    messages: apiMessages,
                    model: selectedModel
                )
                
                await MainActor.run {
                    let aiMessage = DisplayMessage(content: response, isUser: false)
                    chatMessages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    chatMessages.append(DisplayMessage(
                        content: "Sorry, I couldn't process that request. Please try again.",
                        isUser: false
                    ))
                    isLoading = false
                }
            }
        }
    }
    
    private func shortModelName(_ fullName: String) -> String {
        if fullName.contains("llama-4") {
            return "Llama 4"
        } else if fullName.contains("120b") {
            return "GPT 120B"
        } else if fullName.contains("20b") {
            return "GPT 20B"
        } else if fullName.contains("kimi") {
            return "Kimi K2"
        }
        return fullName
    }
}

struct DisplayMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubbleView: View {
    let message: DisplayMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingS) {
            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: Theme.spacingXS) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(
                                message.isUser 
                                    ? Color.appAccent.opacity(0.15)
                                    : Color.appSurfaceElevated
                            )
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appTextTertiary)
                    .padding(.horizontal, Theme.spacingXS)
            }
            
            if message.isUser {
                ZStack {
                    Circle()
                        .fill(Color.appSurfaceElevated)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            
            if message.isUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

struct SuggestionChip: View {
    let icon: String
    let text: String
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(text)
                    .font(.system(size: 13))
            }
            .foregroundStyle(Color.appTextSecondary)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .fill(Color.appSurfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
