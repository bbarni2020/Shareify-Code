import SwiftUI

struct SharAIView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @Binding var isOpen: Bool
    @State private var userInput = ""
    @State private var chatMessages: [DisplayMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("sharaiSelectedModel") private var selectedModel = "auto"
    @State private var showModelPicker = false
    @AppStorage("sharaiIncludeContext") private var includeContext = true
    @State private var scrollProxy: ScrollViewProxy?
    @Namespace private var bottomID
    
    private let availableLanguageModels = [
        "qwen/qwen3-32b",
        "moonshotai/kimi-k2-thinking",
        "openai/gpt-oss-120b",
        "moonshotai/kimi-k2-0905",
        "qwen/qwen3-vl-235b-a22b-instruct",
        "nvidia/nemotron-nano-12b-v2-vl",
        "google/gemini-2.5-flash",
        "openai/gpt-5-mini",
        "deepseek/deepseek-r1",
        "z-ai/glm-4.6",
        "google/gemini-2.5-flash-image"
    ]
    private let availableEmbeddingModels = [
        "qwen/qwen3-embedding-8b",
        "mistralai/codestral-embed-2505",
        "openai/text-embedding-3-large"
    ]
    private var availableModels: [String] {
        ["auto"] + availableLanguageModels + availableEmbeddingModels
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .background(Color.appBorderSubtle)
            
            chatContentView
            
            Spacer(minLength: 0)
            
            inputAreaView
        }
        .frame(minWidth: 360, maxWidth: 420, maxHeight: .infinity)
        .background(Color.appBackground)
        .shadow(color: Color.black.opacity(0.15), radius: 40, x: -12, y: 0)
        .shadow(color: Color.appAccent.opacity(0.1), radius: 60, x: -20, y: 0)
        .onAppear {
            loadChatMessages()
        }
    }
    
    private var inputAreaView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.appBorderSubtle)
            
            VStack(spacing: Theme.spacingM) {
                HStack(spacing: Theme.spacingS) {
                    Toggle(isOn: $includeContext) {
                        HStack(spacing: 6) {
                            Image(systemName: includeContext ? "doc.text.fill" : "doc.text")
                                .font(.system(size: 11, weight: .medium))
                            Text("Include current file")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(includeContext ? Color.appAccent : Color.appTextTertiary)
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(includeContext ? Color.appAccent.opacity(0.1) : Color.appSurfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(includeContext ? Color.appAccent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: includeContext)
                    
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: Theme.spacingS) {
                    TextField("Ask me anything...", text: $userInput, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .lineLimit(1...6)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.appSurfaceElevated)
                        )
                        .onSubmit {
                            if !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                sendMessage()
                            }
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? AnyShapeStyle(Color.appTextTertiary)
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color.appAccent, Color.appAccentMuted],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .scaleEffect(
                                userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userInput.isEmpty)
                    }
                    .buttonStyle(.plain)
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .padding(Theme.spacingM)
            .background(
                LinearGradient(
                    colors: [
                        Color.appSurface,
                        Color.appAccent.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private var headerView: some View {
        ZStack {
            headerBackground
            headerContent
        }
    }
    
    private var headerBackground: some View {
        LinearGradient(
            colors: [
                Color.appAccent.opacity(0.08),
                Color.appSurface
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 80)
    }
    
    private var headerContent: some View {
        VStack(spacing: 8) {
            HStack {
                headerLeadingContent
                Spacer()
                headerTrailingButtons
            }
        }
        .padding(.horizontal, Theme.spacingL)
    }
    
    private var headerLeadingContent: some View {
        HStack(spacing: 10) {
            aiAvatarView
            modelInfoView
        }
    }
    
    private var aiAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccentMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
            
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    private var modelInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SharAI")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)
            
            modelPickerButton
        }
    }
    
    private var modelPickerButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showModelPicker.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Text(shortModelName(selectedModel))
                    .font(.system(size: 10, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .rotationEffect(.degrees(showModelPicker ? 180 : 0))
            }
            .foregroundStyle(Color.appTextTertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showModelPicker) {
            modelPickerContent
        }
    }
    
    private var modelPickerContent: some View {
        VStack(spacing: 0) {
            ForEach(availableModels, id: \.self) { model in
                modelPickerRow(for: model)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: .black.opacity(0.2), radius: 20)
        )
    }
    
    private func modelPickerRow(for model: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedModel = model
                showModelPicker = false
            }
        }) {
            HStack {
                Text(shortModelName(model))
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                if model == selectedModel {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(Color.appTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(model == selectedModel ? Color.appAccent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var headerTrailingButtons: some View {
        HStack(spacing: 8) {
            clearChatButton
            closeButton
        }
    }
    
    private var clearChatButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                chatMessages.removeAll()
                errorMessage = nil
                saveChatMessages()
            }
        }) {
            Image(systemName: "trash")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(chatMessages.isEmpty ? Color.appTextTertiary : Color.red)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(chatMessages.isEmpty ? Color.appSurfaceElevated.opacity(0.5) : Color.red.opacity(0.1))
                )
                .scaleEffect(chatMessages.isEmpty ? 1.0 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(chatMessages.isEmpty)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: chatMessages.isEmpty)
    }
    
    private var closeButton: some View {
        Button(action: {
            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                isOpen = false
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.appSurfaceElevated)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var chatContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    if let error = errorMessage {
                        errorView(error: error)
                    }
                    
                    if chatMessages.isEmpty {
                        emptyStateView
                    } else {
                        messagesView
                    }
                }
                .padding(Theme.spacingM)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: chatMessages.count) { _, _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }
    
    private func errorView(error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.orange)
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextSecondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    errorMessage = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacingM)
        .padding(.top, Theme.spacingM)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            emptyStateIcon
            emptyStateText
            suggestionChips
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }
    
    private var emptyStateIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appAccent.opacity(0.15),
                            Color.appAccent.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 20)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccentMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
            
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    private var emptyStateText: some View {
        VStack(spacing: 8) {
            Text("Ready to assist")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)
            
            Text("Ask me anything about your code")
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var suggestionChips: some View {
        VStack(spacing: 10) {
            SuggestionChip(icon: "wand.and.stars", text: "Explain this function", action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    userInput = "Explain this function"
                }
            })
            SuggestionChip(icon: "hammer.fill", text: "Fix this bug", action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    userInput = "Fix this bug"
                }
            })
            SuggestionChip(icon: "lightbulb.fill", text: "Suggest improvements", action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    userInput = "Suggest improvements"
                }
            })
            SuggestionChip(icon: "doc.text.fill", text: "Write documentation", action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    userInput = "Write documentation"
                }
            })
        }
    }
    
    private var messagesView: some View {
        Group {
            ForEach(chatMessages) { message in
                ChatBubbleView(message: message, vm: vm, onActionExecuted: { messageId, actionId, result in
                    if let idx = chatMessages.firstIndex(where: { $0.id == messageId }) {
                        chatMessages[idx].actionResults[actionId] = result
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            if isLoading {
                loadingIndicator
            }
            
            Color.clear
                .frame(height: 1)
                .id(bottomID)
        }
    }
    
    private var loadingIndicator: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.2), Color.appAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isLoading ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isLoading
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurfaceElevated)
            )
            
            Spacer(minLength: 0)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
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
        saveChatMessages()
        
        userInput = ""
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                var apiMessages = chatMessages.map { msg in
                    ChatMessage(role: msg.isUser ? "user" : "assistant", content: msg.content)
                }
                
                if includeContext, vm.openFiles.first(where: { $0.id == vm.activeFileID }) != nil {
                    apiMessages[apiMessages.count - 1] = ChatMessage(
                        role: "user",
                        content: messageContent
                    )
                }
                
                let modelSelection: ModelSelection = {
                    if selectedModel == "auto" {
                        return .auto
                    } else if availableLanguageModels.contains(selectedModel) {
                        return .languageModel(selectedModel)
                    } else if availableEmbeddingModels.contains(selectedModel) {
                        return .embeddingModel(selectedModel)
                    } else {
                        return .auto
                    }
                }()
                let response = try await AIService.shared.sendMessage(
                    messages: apiMessages,
                    modelSelection: modelSelection
                )
                
                await MainActor.run {
                    let parsed = AIActionParser.parseActions(from: response)
                    var aiMessage = DisplayMessage(content: parsed.cleanResponse, isUser: false)
                    aiMessage.actions = parsed.actions
                    chatMessages.append(aiMessage)
                    isLoading = false
                    saveChatMessages()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    chatMessages.append(DisplayMessage(
                        content: "Sorry, I couldn't process that request. Please try again.",
                        isUser: false
                    ))
                    isLoading = false
                    saveChatMessages()
                }
            }
        }
    }
    
    private func saveChatMessages() {
        guard let encoded = try? JSONEncoder().encode(chatMessages) else { return }
        UserDefaults.standard.set(encoded, forKey: "sharaiChatMessages")
    }
    
    private func loadChatMessages() {
        guard let data = UserDefaults.standard.data(forKey: "sharaiChatMessages"),
              let decoded = try? JSONDecoder().decode([DisplayMessage].self, from: data) else {
            return
        }
        chatMessages = decoded
    }
    
    private func shortModelName(_ fullName: String) -> String {
        if fullName == "auto" {
            return "Auto"
        } else if fullName.contains("llama-4") {
            return "Llama 4"
        } else if fullName.contains("120b") {
            return "GPT 120B"
        } else if fullName.contains("kimi") {
            return "Kimi K2"
        } else if fullName.contains("gemini") {
            return "Gemini"
        } else if fullName.contains("deepseek") {
            return "DeepSeek"
        } else if fullName.contains("nemotron") {
            return "Nemotron"
        } else if fullName.contains("glm") {
            return "GLM 4.6"
        } else if fullName.contains("qwen3-embedding") {
            return "Qwen Embedding"
        } else if fullName.contains("codestral-embed") {
            return "Codestral Embed"
        } else if fullName.contains("text-embedding-3-large") {
            return "OpenAI Embedding"
        }
        return fullName
    }
}

struct DisplayMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var actions: [AIAction]
    var actionResults: [UUID: Result<String, Error>] = [:]
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), actions: [AIAction] = [], actionResults: [UUID: Result<String, Error>] = [:]) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.actions = actions
        self.actionResults = actionResults
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp, actions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        actions = try container.decode([AIAction].self, forKey: .actions)
        actionResults = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(actions, forKey: .actions)
    }
}

struct ChatBubbleView: View {
    let message: DisplayMessage
    @ObservedObject var vm: WorkspaceViewModel
    let onActionExecuted: (UUID, UUID, Result<String, Error>) -> Void
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccentMuted],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .opacity(isVisible ? 1.0 : 0.0)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                message.isUser 
                                    ? LinearGradient(
                                        colors: [Color.appAccent.opacity(0.12), Color.appAccent.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.appSurfaceElevated, Color.appCodeBackground],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        message.isUser ? Color.appAccent.opacity(0.2) : Color.appBorder.opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                    )
                
                if !message.actions.isEmpty {
                    ForEach(message.actions) { action in
                        ActionCardView(
                            action: action,
                            vm: vm,
                            result: message.actionResults[action.id],
                            onExecute: { result in
                                onActionExecuted(message.id, action.id, result)
                            }
                        )
                    }
                }
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.appTextTertiary)
                    .padding(.horizontal, 4)
            }
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .opacity(isVisible ? 1.0 : 0.0)
            
            if message.isUser {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .opacity(isVisible ? 1.0 : 0.0)
            }
            
            if message.isUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.05)) {
                isVisible = true
            }
        }
    }
}

struct SuggestionChip: View {
    let icon: String
    let text: String
    var action: () -> Void = {}
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appTextPrimary)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurfaceElevated,
                                Color.appCodeBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct ActionCardView: View {
    let action: AIAction
    @ObservedObject var vm: WorkspaceViewModel
    let result: Result<String, Error>?
    let onExecute: (Result<String, Error>) -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(actionColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: actionIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(actionColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    
                    if result == nil {
                        Text(actionDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if result == nil {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            executeAction()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("Apply")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [actionColor, actionColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .scaleEffect(isHovered ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isHovered = hovering
                        }
                    }
                }
            }
            
            if let result = result {
                switch result {
                case .success(let message):
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.green.opacity(0.08))
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                case .failure(let error):
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                        Text(error.localizedDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurfaceElevated,
                            Color.appCodeBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(actionColor.opacity(0.2), lineWidth: 1.5)
                )
        )
    }
    
    private var actionIcon: String {
        switch action.type {
        case .edit: return "pencil.circle.fill"
        case .rewrite: return "arrow.triangle.2.circlepath"
        case .insert: return "plus.circle.fill"
        case .terminal: return "terminal.fill"
        case .search: return "magnifyingglass.circle.fill"
        }
    }
    
    private var actionColor: Color {
        switch action.type {
        case .edit: return .blue
        case .rewrite: return .orange
        case .insert: return .green
        case .terminal: return .purple
        case .search: return .cyan
        }
    }
    
    private var actionTitle: String {
        switch action.type {
        case .edit: return "Edit Code"
        case .rewrite: return "Rewrite File"
        case .insert: return "Insert Code"
        case .terminal(let command, _): return "Run: \(command)"
        case .search(let pattern, _): return "Search: \(pattern)"
        }
    }
    
    private var actionDescription: String {
        switch action.type {
        case .edit:
            return "Replace code in the current file"
        case .rewrite(let file, _):
            return "Completely rewrite \(file)"
        case .insert:
            return "Insert new code into the file"
        case .terminal(_, let reason):
            return reason
        case .search(_, let reason):
            return reason
        }
    }
    
    private func executeAction() {
        let result = vm.executeAction(action)
        onExecute(result)
    }
}
