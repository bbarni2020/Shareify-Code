import SwiftUI

struct EditorView: View {
    @ObservedObject var vm: WorkspaceViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(vm: vm)
            
            if let active = vm.openFiles.first(where: { $0.id == vm.activeFileID }) {
                VStack(spacing: 0) {
                    HStack(spacing: Theme.spacingM) {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: active.url.languageInfo.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(active.url.languageInfo.name)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(active.url.languageInfo.color)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingXS)
                        .background(
                            Capsule()
                                .fill(active.url.languageInfo.color.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(active.url.languageInfo.color.opacity(0.3), lineWidth: 1)
                        )
                        
                        Text(active.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        
                        if active.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.top, Theme.spacingM)
                    .padding(.bottom, Theme.spacingM)
                    
                    if active.isLoading {
                        VStack(spacing: Theme.spacingL) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Loading file from server...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.bottom, Theme.spacingL)
                    } else if active.url.detectedLanguage != .unknown {
                        SyntaxHighlightingTextEditor(
                            text: Binding<String>(
                                get: { active.content },
                                set: { vm.updateActiveContent($0) }
                            ),
                            language: active.url.detectedLanguage
                        )
                        .padding(Theme.spacingL)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.bottom, Theme.spacingL)
                    } else {
                        VStack(spacing: Theme.spacingM) {
                            HStack(spacing: Theme.spacingS) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.warningColor)
                                
                                Text("This file type isn't supported for editing")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                    .fill(Color.warningColor.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                    .stroke(Color.warningColor.opacity(0.3), lineWidth: 1)
                            )
                            
                            ScrollView {
                                Text(active.content)
                                    .font(.system(size: Theme.codeFontSize, design: .monospaced))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .padding(Theme.spacingL)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.bottom, Theme.spacingL)
                    }
                    
                    Spacer(minLength: 0)
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            } else {
                NoFileOpenView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            StatusBarView(vm: vm)
        }
        .background(Color.appBackground)
    }
}

private struct TabBarView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @State private var hoverTab: String?
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingXS) {
                    ForEach(vm.openFiles) { file in
                        let isActive = file.id == vm.activeFileID
                        let isHovering = hoverTab == file.id
                        
                        HStack(spacing: Theme.spacingS) {
                            HStack(spacing: Theme.spacingS) {
                                Image(systemName: file.url.languageInfo.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(file.url.languageInfo.color)
                                
                                Text(file.title)
                                    .font(.system(size: Theme.uiFontSize, design: .rounded))
                                    .foregroundStyle(
                                        isActive ? Color.appTextPrimary : Color.appTextSecondary
                                    )
                                
                                if file.isDirty {
                                    Circle()
                                        .fill(Color.appAccent)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                    .fill(
                                        isActive 
                                            ? Color.appSurfaceElevated 
                                            : (isHovering ? Color.appSurfaceHover : Color.clear)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                    .stroke(
                                        isActive ? Color.appBorder : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { vm.activeFileID = file.id }
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: Theme.animationFast)) {
                                    hoverTab = hovering ? file.id : nil
                                }
                            }
                            
                            Button {
                                vm.closeFile(file.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.appTextTertiary)
                                    .frame(width: 16, height: 16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
            }
            
            Divider()
                .frame(height: 24)
            
            Button(action: vm.saveActive) {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Save")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s")
        }
        .frame(height: 44)
        .background(
            Color.appSurface
                .overlay(
                    Rectangle()
                        .fill(Color.appBorderSubtle)
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
        )
    }
}

private struct StatusBarView: View {
    @ObservedObject var vm: WorkspaceViewModel
    
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            if let id = vm.activeFileID, let file = vm.openFiles.first(where: { $0.id == id }) {
                Text(file.url.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextTertiary)
                
                Circle()
                    .fill(Color.appBorder)
                    .frame(width: 3, height: 3)
                
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: file.url.languageInfo.icon)
                        .font(.system(size: 10))
                    Text(file.url.languageInfo.name)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(file.url.languageInfo.color)
                
                if !file.url.pathExtension.isEmpty {
                    Circle()
                        .fill(Color.appBorder)
                        .frame(width: 3, height: 3)
                    
                    Text(".\(file.url.pathExtension)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextTertiary)
                }
            } else {
                HStack(spacing: Theme.spacingXS) {
                    Circle()
                        .fill(Color.successColor)
                        .frame(width: 6, height: 6)
                    Text("Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            
            Spacer()
            
            Button(action: vm.saveActive) {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 10))
                    Text("Save")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.appTextSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s")
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingS)
        .background(
            Color.appSurface
                .overlay(
                    Rectangle()
                        .fill(Color.appBorderSubtle)
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
        )
    }
}

private struct NoFileOpenView: View {
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.15), lineWidth: 2)
                .frame(width: 160, height: 160)
                .blur(radius: 12)
                .opacity(pulse ? 0.3 : 0.5)
                .scaleEffect(pulse ? 1.1 : 0.9)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: pulse
                )
            
            VStack(spacing: Theme.spacingL) {
                ZStack {
                    Circle()
                        .fill(Color.appSurfaceElevated)
                        .frame(width: 96, height: 96)
                        .shadow(color: Theme.subtleShadow, radius: 20, x: 0, y: 8)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.appTextTertiary)
                }
                
                VStack(spacing: Theme.spacingXS) {
                    Text("No file open")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    
                    Text("Select a file from the explorer to start editing")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .task { pulse = true }
    }
}
