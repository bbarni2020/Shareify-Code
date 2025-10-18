//
//  ContentView.swift
//  Shareify Code
//
//  Created by Balogh Barnabás on 2025. 10. 18..
//

import SwiftUI
#if os(iOS)
import UniformTypeIdentifiers
#endif

struct ContentView: View {
    @EnvironmentObject private var vm: WorkspaceViewModel
    @State private var showSharAI = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Main content
            NavigationSplitView {
                ExplorerView(vm: vm)
            } detail: {
                EditorView(vm: vm)
            }
            
            // SharAI Panel - slides in from right
            if showSharAI {
                SharAIView(vm: vm, isOpen: $showSharAI)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
            }
            
            // Floating SharAI button (when panel is closed)
            if !showSharAI {
                VStack {
                    Spacer()
                    Button(action: { showSharAI = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            Text("SharAI")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.5), .pink.opacity(0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .padding(.trailing, 20)
                .zIndex(0)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showSharAI)
        #if os(iOS)
        .fileImporter(isPresented: $vm.showFolderImporter, allowedContentTypes: [UTType.folder], allowsMultipleSelection: false) { result in
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
