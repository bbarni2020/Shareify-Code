import SwiftUI
#if os(iOS)
import UniformTypeIdentifiers
#endif

struct ContentView: View {
    @EnvironmentObject private var vm: WorkspaceViewModel
    @State private var showSharAI = false
    @State private var hoverSharAI = false
    @State private var showSettings = false
    @State private var aiEnabled = true
    @State private var isServerConnected = false
    @State private var showFolderSourcePicker = false
    @State private var showServerBrowser = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            NavigationSplitView {
                ExplorerView(vm: vm)
                    .navigationSplitViewColumnWidth(min: 260, ideal: 320, max: 480)
            } detail: {
                EditorView(vm: vm)
            }
            .navigationSplitViewStyle(.balanced)
            
            VStack {
                HStack {
                    Spacer()
                    
                    if !showSharAI {
                        if isServerConnected {
                            HStack(spacing: Theme.spacingXS) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Server")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.appSurface)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                            .shadow(color: Theme.subtleShadow, radius: 8, x: 0, y: 2)
                            .transition(.opacity)
                        }
                        
                        Button(action: {
                            if isServerConnected {
                                showFolderSourcePicker = true
                            } else {
                                vm.openFolder()
                            }
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.appSurface)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                                .shadow(color: Theme.subtleShadow, radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                        
                        Button(action: {
                            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                                showSettings = true
                            }
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.appSurface)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                                .shadow(color: Theme.subtleShadow, radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .padding(.top, Theme.spacingL)
                .padding(.trailing, Theme.spacingL)
                
                Spacer()
            }
            .zIndex(2)
            
            if showSharAI && aiEnabled {
                SharAIView(vm: vm, isOpen: $showSharAI)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(1)
                    .padding(.trailing, Theme.spacingM)
                    .padding(.vertical, Theme.spacingM)
            }
            
            if !showSharAI && aiEnabled {
                VStack {
                    Spacer()
                    Button(action: { 
                        withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                            showSharAI = true
                        }
                    }) {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                            Text("SharAI")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccentHover],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                                .fill(Color.appSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.02)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Theme.panelShadow, radius: 16, x: 0, y: 4)
                        .shadow(color: Color.appAccent.opacity(hoverSharAI ? 0.5 : 0.0), radius: hoverSharAI ? 20 : 0)
                        .scaleEffect(hoverSharAI ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: Theme.animationFast)) { 
                            hoverSharAI = hovering 
                        }
                    }
                    #if os(iOS)
                    .simultaneousGesture(TapGesture().onEnded({
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.impactOccurred()
                    }))
                    #endif
                    .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .padding(.trailing, 24)
                .zIndex(0)
            }
        }
        .animation(.spring(response: Theme.animationNormal, dampingFraction: 0.8), value: showSharAI)
        .animation(.spring(response: Theme.animationNormal, dampingFraction: 0.8), value: aiEnabled)
        .onAppear {
            checkServerConnection()
        }
        .onChange(of: aiEnabled) { oldValue, newValue in
            if !newValue {
                showSharAI = false
            }
        }
        .overlay(
            Group {
                if showSettings {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                                showSettings = false
                            }
                        }
                        .transition(.opacity)
                    
                    SettingsView(isPresented: $showSettings, aiEnabled: $aiEnabled)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                
                if vm.showUnsavedWarning {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    UnsavedWarningDialog(vm: vm)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                
                if showFolderSourcePicker {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                                showFolderSourcePicker = false
                            }
                        }
                        .transition(.opacity)
                    
                    FolderSourcePicker(
                        isPresented: $showFolderSourcePicker,
                        onLocalSelected: {
                            vm.openFolder()
                        },
                        onServerSelected: {
                            openServerBrowser()
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                
                if showServerBrowser {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                                showServerBrowser = false
                            }
                        }
                        .transition(.opacity)
                    
                    ServerBrowserView(isPresented: $showServerBrowser)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
        )
        .background(
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        Color.appAccent.opacity(0.06),
                        Color.appBackground.opacity(0)
                    ],
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 800
                )
                .ignoresSafeArea()
                .blur(radius: 60)
            }
        )
        #if os(iOS)
        .fileImporter(
            isPresented: $vm.showFolderImporter,
            allowedContentTypes: [UTType.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    vm.setRootFromPickedURL(url)
                }
            case .failure(let error):
                print("Folder import error: \(error)")
            }
        }
        #endif
        .onAppear {
            checkServerConnection()
        }
    }
    
    private func checkServerConnection() {
        guard ServerManager.shared.isServerLoggedIn() else {
            isServerConnected = false
            return
        }
        
        ServerManager.shared.testServerConnection { isOnline in
            isServerConnected = isOnline
        }
    }
    
    private func openServerBrowser() {
        showFolderSourcePicker = false
        withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
            showServerBrowser = true
        }
    }
}

struct FolderSourcePicker: View {
    @Binding var isPresented: Bool
    let onLocalSelected: () -> Void
    let onServerSelected: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            VStack(spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
                
                Text("Open Folder")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Choose where to open from")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
            }
            
            VStack(spacing: Theme.spacingM) {
                Button(action: {
                    isPresented = false
                    onLocalSelected()
                }) {
                    HStack(spacing: Theme.spacingM) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "laptopcomputer")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Local Folder")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.appTextPrimary)
                            
                            Text("Open from this device")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .padding(Theme.spacingL)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(Color.appSurfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    isPresented = false
                    onServerSelected()
                }) {
                    HStack(spacing: Theme.spacingM) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "server.rack")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.green)
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Server Folder")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.appTextPrimary)
                            
                            Text("Browse files on your server")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .padding(Theme.spacingL)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(Color.appSurfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Button(action: {
                withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(Color.appSurfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.spacingXXL)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Theme.panelShadow, radius: 32, x: 0, y: 16)
    }
}

#Preview {
    ContentView().environmentObject(WorkspaceViewModel())
}

struct UnsavedWarningDialog: View {
    @ObservedObject var vm: WorkspaceViewModel
    
    var fileName: String {
        guard let fileToClose = vm.fileToClose,
              let file = vm.openFiles.first(where: { $0.id == fileToClose }) else {
            return "this file"
        }
        return file.title
    }
    
    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            VStack(spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.orange)
                }
                
                VStack(spacing: Theme.spacingS) {
                    Text("Unsaved Changes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    
                    Text("Do you want to save changes to \(fileName)?")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacingM)
                }
            }
            
            VStack(spacing: Theme.spacingM) {
                Button(action: {
                    withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                        if let fileToClose = vm.fileToClose {
                            vm.saveAndCloseFile(fileToClose)
                        }
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appAccent)
                        )
                }
                .buttonStyle(.plain)
                
                HStack(spacing: Theme.spacingM) {
                    Button(action: {
                        withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                            vm.cancelClose()
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                    .fill(Color.appSurfaceElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                            .stroke(Color.appBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                            if let fileToClose = vm.fileToClose {
                                vm.performCloseFile(fileToClose)
                            }
                        }
                    }) {
                        Text("Discard")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.spacingXXL)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: Theme.panelShadow, radius: 32, x: 0, y: 16)
        )
    }
}
