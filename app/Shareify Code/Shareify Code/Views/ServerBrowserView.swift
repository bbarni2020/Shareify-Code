import SwiftUI

struct ServerBrowserView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var vm: WorkspaceViewModel
    @State private var currentPath: [String] = []
    @State private var items: [ServerFileItem] = []
    @State private var isLoading = false
    @State private var selectedFolder: String?
    
    struct ServerFileItem: Identifiable {
        let id = UUID()
        let name: String
        let isFolder: Bool
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                        if currentPath.isEmpty {
                            isPresented = false
                        } else {
                            _ = currentPath.popLast()
                            fetchItems()
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.appSurfaceElevated)
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Server Browser")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                        isPresented = false
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
            .background(Color.appSurface)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    let displayPath = currentPath.isEmpty ? ["Root"] : currentPath
                    ForEach(Array(displayPath.enumerated()), id: \.offset) { index, pathComponent in
                        HStack(spacing: 8) {
                            Text(pathComponent)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(index == displayPath.count - 1 ? Color.appTextPrimary : Color.appTextSecondary)
                            
                            if index < displayPath.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.appTextTertiary)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingL)
                .padding(.vertical, Theme.spacingS)
            }
            .background(Color.appSurfaceElevated)
            
            Divider()
                .background(Color.appBorder)
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.top, Theme.spacingM)
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(items.filter { $0.isFolder }) { item in
                            folderItemView(item: item)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(Theme.spacingM)
                }
                .transition(.opacity)
            }
            
            if selectedFolder != nil {
                Divider()
                    .background(Color.appBorder)
                    .transition(.opacity)
                
                HStack(spacing: Theme.spacingM) {
                    Button(action: {
                        withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                            selectedFolder = nil
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
                            openSelectedFolder()
                        }
                    }) {
                        Text("Open Folder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                    .fill(Color.appAccent)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(Theme.spacingL)
                .background(Color.appSurface)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 520, height: 600)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Theme.panelShadow, radius: 40, x: 0, y: 20)
        .onAppear {
            fetchItems()
        }
        .animation(.spring(response: Theme.animationNormal, dampingFraction: 0.8), value: selectedFolder)
        .animation(.spring(response: Theme.animationNormal, dampingFraction: 0.8), value: isLoading)
    }
    
    private func folderItemView(item: ServerFileItem) -> some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: "folder.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.appAccent)
                .frame(width: 32)
            
            Text(item.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if selectedFolder == item.name {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appAccent)
                    .transition(.scale.combined(with: .opacity))
            }
            
            Button(action: {
                withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                    currentPath.append(item.name)
                    selectedFolder = nil
                    fetchItems()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                .fill(selectedFolder == item.name ? Color.appAccent.opacity(0.1) : Color.appSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                .stroke(selectedFolder == item.name ? Color.appAccent.opacity(0.3) : Color.appBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                openFolderDirectly(item.name)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                if selectedFolder == item.name {
                    selectedFolder = nil
                } else {
                    selectedFolder = item.name
                }
            }
        }
    }
    
    private func fetchItems() {
        isLoading = true
        let pathString = currentPath.joined(separator: "/")
        let requestBody: [String: Any] = ["path": pathString]
        
        ServerManager.shared.executeServerCommand(command: "/finder", method: "GET", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    var fileNames: [String] = []
                    if let responseDict = response as? [String: Any],
                       let itemsArray = responseDict["items"] as? [String] {
                        fileNames = itemsArray
                    } else if let directArray = response as? [String] {
                        fileNames = directArray
                    }
                    
                    items = fileNames.map { fileName in
                        ServerFileItem(name: fileName, isFolder: !fileName.contains("."))
                    }
                case .failure(let error):
                    print("Failed to fetch items: \(error)")
                    items = []
                }
            }
        }
    }
    
    private func openSelectedFolder() {
        guard let folder = selectedFolder else { return }
        openFolderDirectly(folder)
    }
    
    private func openFolderDirectly(_ folderName: String) {
        let fullPath = (currentPath + [folderName]).joined(separator: "/")
        loadServerFolder(path: fullPath)
    }
    
    private func loadServerFolder(path: String) {
        isPresented = false
        
        vm.setServerFolderLoading(path: path)
        
        let requestBody: [String: Any] = ["path": path]
        
        ServerManager.shared.executeServerCommand(command: "/finder", method: "GET", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    var fileNames: [String] = []
                    if let responseDict = response as? [String: Any],
                       let itemsArray = responseDict["items"] as? [String] {
                        fileNames = itemsArray
                    } else if let directArray = response as? [String] {
                        fileNames = directArray
                    }
                    
                    let serverFiles = fileNames.map { fileName in
                        ServerFileNode(
                            name: fileName,
                            path: path + "/" + fileName,
                            isFolder: !fileName.contains(".")
                        )
                    }
                    
                    vm.loadServerFolder(path: path, files: serverFiles)
                    
                case .failure(let error):
                    print("Failed to load server folder: \(error)")
                    vm.clearServerFolderLoading()
                }
            }
        }
    }
}
