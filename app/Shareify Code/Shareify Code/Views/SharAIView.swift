//
//  SharAIView.swift
//  Shareify Code
//

import SwiftUI

struct SharAIView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @Binding var isOpen: Bool
    @State private var userInput = ""
    @State private var chatMessages: [ChatMessage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("SharAI")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isOpen = false }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 10)
            }
            .glassLikeBackground()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            Divider()
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 16) {
                    if chatMessages.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top, 40)
                            
                            Text("Your AI Pair Programmer")
                                .font(.title2.weight(.semibold))
                                .multilineTextAlignment(.center)
                            
                            Text("Ask me anything about your code, or let me help you write it!")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                SuggestionChip(icon: "wand.and.stars", text: "Explain this function")
                                SuggestionChip(icon: "hammer.fill", text: "Fix this bug")
                                SuggestionChip(icon: "lightbulb.fill", text: "Suggest improvements")
                                SuggestionChip(icon: "doc.text.fill", text: "Write documentation")
                            }
                            .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(chatMessages) { message in
                            ChatBubbleView(message: message)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    TextField("Ask SharAI...", text: $userInput, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.systemBackground).opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .lineLimit(1...5)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(
                                userInput.isEmpty ? 
                                LinearGradient(
                                    colors: [.gray, .gray],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(userInput.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .glassLikeBackground()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(minWidth: 320, maxWidth: 400, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: -5, y: 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                    )
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(message.isUser ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.isUser {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appAccent)
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
