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
                if let url = urls.first { vm.setRootFromPickedURL(url) }
            case .failure(let error):
                print("Folder import error: \(error)")
            }
        }
        #endif
    }
}

#Preview {
    ContentView().environmentObject(WorkspaceViewModel())
}
