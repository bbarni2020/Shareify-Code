import SwiftUI

struct SharAIView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @Binding var isOpen: Bool
    @State private var userInput = ""
    @State private var chatMessages: [ChatMessage] = []
    
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
                }
                
                Spacer()
                
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
                                SuggestionChip(icon: "wand.and.stars", text: "Explain this function")
                                SuggestionChip(icon: "hammer.fill", text: "Fix this bug")
                                SuggestionChip(icon: "lightbulb.fill", text: "Suggest improvements")
                                SuggestionChip(icon: "doc.text.fill", text: "Write documentation")
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(chatMessages) { message in
                            ChatBubbleView(message: message)
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
                            if userInput.isEmpty {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.appTextTertiary)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.appAccent, Color.appAccentMuted],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(userInput.isEmpty)
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
        
        let message = ChatMessage(content: userInput, isUser: true)
        chatMessages.append(message)
        userInput = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = ChatMessage(
                content: "I'm SharAI, your coding assistant! This feature is coming soon with full AI capabilities.",
                isUser: false
            )
            chatMessages.append(response)
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
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
    
    var body: some View {
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
}
