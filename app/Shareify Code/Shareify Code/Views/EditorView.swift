//
//  EditorView.swift
//  Shareify Code
//

import SwiftUI

struct EditorView: View {
    @ObservedObject var vm: WorkspaceViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(vm: vm)
            Divider()
            if let active = vm.openFiles.first(where: { $0.id == vm.activeFileID }) {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: active.url.languageInfo.icon)
                                .font(.callout)
                            Text(active.url.languageInfo.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(active.url.languageInfo.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(active.url.languageInfo.color.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(active.url.languageInfo.color.opacity(0.3), lineWidth: 1)
                        )
                        
                        Text(active.title)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    if active.url.detectedLanguage != .unknown {
                        SyntaxHighlightingTextEditor(
                            text: Binding<String>(
                                get: { active.content },
                                set: { vm.updateActiveContent($0) }
                            ),
                            language: active.url.detectedLanguage
                        )
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground).opacity(0.7))
                                .glassLikeBackground()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    } else {
                        TextEditor(text: Binding<String>(
                            get: { active.content },
                            set: { vm.updateActiveContent($0) }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground).opacity(0.7))
                                .glassLikeBackground()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No file open")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            StatusBarView(vm: vm)
                .glassLikeBackground()
        }
        .background(Color.clear)
    }
}

private struct TabBarView: View {
    @ObservedObject var vm: WorkspaceViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.openFiles) { file in
                    let isActive = file.id == vm.activeFileID
                    HStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: file.url.languageInfo.icon)
                                .font(.caption)
                                .foregroundStyle(file.url.languageInfo.color)
                            
                            Text(file.title + (file.isDirty ? " •" : ""))
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(isActive ? Color.accentColor : .primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                            .background(
                                Group {
                                    if isActive {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.accentColor.opacity(0.18))
                                            .glassLikeBackground()
                                    } else {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.clear)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: isActive ? 2 : 0)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { vm.activeFileID = file.id }
                        Button {
                            vm.closeFile(file.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.trailing, 4)
                        .glassButtonStyleIfAvailable()
                    }
                }
                Spacer(minLength: 0)
                
                Button(action: vm.saveActive) {
                    Image(systemName: "arrow.down.doc")
                        .font(.body)
                }
                .glassButtonStyleIfAvailable()
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
        .frame(height: 48)
        .glassLikeBackground()
    }
}

private struct StatusBarView: View {
    @ObservedObject var vm: WorkspaceViewModel
    var body: some View {
        HStack(spacing: 12) {
            if let id = vm.activeFileID, let file = vm.openFiles.first(where: { $0.id == id }) {
                Text(file.url.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Divider()
                    .frame(height: 12)
                
                HStack(spacing: 4) {
                    Image(systemName: file.url.languageInfo.icon)
                        .font(.caption2)
                    Text(file.url.languageInfo.name)
                }
                .foregroundStyle(file.url.languageInfo.color)
                
                Divider()
                    .frame(height: 12)

                if !file.url.pathExtension.isEmpty {
                    Text(".\(file.url.pathExtension)")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Ready")
            }
            Spacer()
            Button(action: vm.saveActive) { 
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc")
                        .font(.caption)
                    Text("Save")
                }
            }
            .keyboardShortcut("s")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.clear)
    }
}
