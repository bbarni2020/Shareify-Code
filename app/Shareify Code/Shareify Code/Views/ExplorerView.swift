import SwiftUI

struct ExplorerView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @State private var showNewFileSheet = false
    @State private var showNewFolderSheet = false
    @State private var newFileName = ""
    @State private var newFolderName = ""
    @State private var searchQuery = ""
    @State private var showFolderSourcePicker = false
    @State private var showServerBrowser = false
    @State private var isServerOnline = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.spacingM) {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccentMuted],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Explorer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                }
                
                Spacer()
                
                HStack(spacing: Theme.spacingXS) {
                    ToolbarIconButton(icon: "doc.badge.plus") { showNewFileSheet = true }
                        .disabled(vm.rootNode == nil && !vm.isServerFolder)
                    ToolbarIconButton(icon: "folder.badge.plus") { showNewFolderSheet = true }
                        .disabled(vm.rootNode == nil && !vm.isServerFolder)
                    ToolbarIconButton(icon: "arrow.clockwise") {
                        if let root = vm.rootNode { vm.refreshNode(root) }
                    }
                    ToolbarIconButton(icon: vm.showHiddenFiles ? "eye.fill" : "eye.slash.fill") {
                        vm.showHiddenFiles.toggle()
                        if let root = vm.rootNode { vm.refreshNode(root) }
                    }
                }
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

            HStack(spacing: Theme.spacingS) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextTertiary)
                TextField("Search files...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: Theme.uiFontSize))
                    .foregroundStyle(Color.appTextPrimary)
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .fill(Color.appCodeBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingM)

            if vm.isServerFolder, let serverRoot = vm.serverRootNode {
                ScrollView {
                    ServerFileTreeNodeView(node: serverRoot, vm: vm, level: 0)
                        .padding(.vertical, Theme.spacingS)
                        .padding(.horizontal, Theme.spacingXS)
                }
            } else if vm.isLoadingServerFolder {
                VStack(spacing: Theme.spacingL) {
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.bottom, Theme.spacingM)
                    
                    Text("Loading server folder...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.appTextPrimary)
                    
                    Text("Please wait")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let root = vm.rootNode {
                ScrollViewReader { _ in
                    ScrollView {
                        FileTreeNodeView(node: root, vm: vm, searchQuery: searchQuery)
                            .padding(.vertical, Theme.spacingS)
                            .padding(.horizontal, Theme.spacingXS)
                    }
                }
            } else {
                VStack(spacing: Theme.spacingL) {
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.1))
                            .frame(width: 88, height: 88)
                            .overlay(
                                Circle()
                                    .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: "folder")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(Color.appAccent)
                    }
                    
                    VStack(spacing: Theme.spacingXS) {
                        Text("No folder open")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Open a folder to start editing")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    
                    Button(action: { 
                        if isServerOnline {
                            showFolderSourcePicker = true
                        } else {
                            vm.openFolder()
                        }
                    }) {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: "folder")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Open Folder")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appAccent)
                        )
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Choose folder source", isPresented: $showFolderSourcePicker) {
                        Button {
                            vm.openFolder()
                        } label: {
                            Text("Local / On Device")
                                .foregroundStyle(Color.white)
                        }
                        Button {
                            showServerBrowser = true
                        } label: {
                            Text("Server")
                                .foregroundStyle(Color.white)
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 280)
        .background(Color.appSurface)
        .sheet(isPresented: $showNewFileSheet) {
            NewItemSheet(
                title: "Create New File",
                icon: "doc.badge.plus",
                iconColor: .appAccent,
                placeholder: "filename.swift",
                itemName: $newFileName,
                onCreate: {
                    vm.createFile(name: newFileName, in: vm.selectedNode?.isDirectory == true ? vm.selectedNode : nil)
                    showNewFileSheet = false
                    newFileName = ""
                },
                onCancel: {
                    showNewFileSheet = false
                    newFileName = ""
                },
                targetFolder: vm.selectedNode?.isDirectory == true ? vm.selectedNode!.name : (vm.rootNode?.name ?? "Root")
            )
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewItemSheet(
                title: "Create New Folder",
                icon: "folder.badge.plus",
                iconColor: .orange,
                placeholder: "folder-name",
                itemName: $newFolderName,
                onCreate: {
                    vm.createFolder(name: newFolderName, in: vm.selectedNode?.isDirectory == true ? vm.selectedNode : nil)
                    showNewFolderSheet = false
                    newFolderName = ""
                },
                onCancel: {
                    showNewFolderSheet = false
                    newFolderName = ""
                },
                targetFolder: vm.selectedNode?.isDirectory == true ? vm.selectedNode!.name : (vm.rootNode?.name ?? "Root")
            )
        }
        .sheet(isPresented: $showServerBrowser) {
            ServerBrowserView(isPresented: $showServerBrowser)
                .environmentObject(vm)
        }
        .onAppear {
            checkServerConnection()
        }
    }
    
    private func checkServerConnection() {
        guard ServerManager.shared.isServerLoggedIn() else {
            isServerOnline = false
            return
        }
        
        ServerManager.shared.testServerConnection { isOnline in
            isServerOnline = isOnline
        }
    }
}

private struct ToolbarIconButton: View {
    let icon: String
    let action: () -> Void
    @State private var hover = false
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isEnabled ? Color.appTextPrimary : Color.appTextTertiary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusXS, style: .continuous)
                        .fill(hover && isEnabled ? Color.appSurfaceHover : Color.appSurfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusXS, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.easeInOut(duration: Theme.animationFast)) { hover = h }
        }
    }
}

private struct NewItemSheet: View {
    let title: String
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var itemName: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    var targetFolder: String = "Root"
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            VStack(spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("in: \(targetFolder)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextTertiary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingXS)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                            .fill(Color.appCodeBackground)
                    )
            }

            VStack(spacing: Theme.spacingS) {
                TextField(placeholder, text: $itemName)
                    .textFieldStyle(.plain)
                    .font(.system(size: Theme.uiFontSize))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(Color.appCodeBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .stroke(isTextFieldFocused ? iconColor.opacity(0.5) : Color.appBorder, lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !itemName.isEmpty { onCreate() }
                    }
                
                Text("Press Enter to create")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextTertiary)
            }

            HStack(spacing: Theme.spacingM) {
                Button(action: onCancel) {
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
                
                Button(action: onCreate) {
                    Text("Create")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(itemName.isEmpty ? Color.appTextTertiary : Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(itemName.isEmpty ? Color.appSurfaceElevated : iconColor)
                        )
                }
                .buttonStyle(.plain)
                .disabled(itemName.isEmpty)
            }
        }
        .padding(Theme.spacingXXL)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: Theme.panelShadow, radius: 32, x: 0, y: 16)
        )
        .onAppear { isTextFieldFocused = true }
    }
}

private struct FileTreeNodeView: View {
    let node: FileNode
    @ObservedObject var vm: WorkspaceViewModel
    var searchQuery: String
    
    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if isVisible(node) {
                row(node)
                if node.isDirectory, vm.expanded.contains(node.id) {
                    let children = childrenFor(node)
                    if !children.isEmpty {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(children, id: \.id) { child in
                                FileTreeNodeView(node: child, vm: vm, searchQuery: searchQuery)
                                    .padding(.leading, Theme.spacingL)
                            }
                        }
                    }
                }
            }
        }
    }

    private func row(_ node: FileNode) -> some View {
        HStack(spacing: Theme.spacingS) {
            if node.isDirectory {
                Image(systemName: vm.expanded.contains(node.id) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }

            Image(systemName: iconForFile(node))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(colorForFile(node))
                .frame(width: 18)

            Text(node.name)
                .font(.system(size: Theme.uiFontSize, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(
                    vm.activeFileID == node.url.path 
                        ? Color.appAccent 
                        : Color.appTextPrimary
                )
            
            Spacer(minLength: 0)
            
            if hover && !node.isDirectory {
                Button(action: { vm.deleteFile(node) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.red)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 1) {
            vm.selectedNode = node
            if node.isDirectory {
                withAnimation(.easeInOut(duration: Theme.animationFast)) {
                    vm.toggleExpanded(node)
                }
            } else {
                vm.openFile(node.url)
            }
        }
        .onHover { h in
            withAnimation(.easeInOut(duration: Theme.animationFast)) { hover = h }
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusXS, style: .continuous)
                .fill(
                    vm.activeFileID == node.url.path 
                        ? Color.appAccent.opacity(0.12)
                        : (hover ? Color.appSurfaceHover : Color.clear)
                )
        )
    }
    
    private func iconForFile(_ node: FileNode) -> String {
        if node.isDirectory {
            return vm.expanded.contains(node.id) ? "folder.fill" : "folder"
        }
        let ext = node.url.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) { return "photo.fill" }
        if ext == "pdf" { return "doc.richtext.fill" }
        let language = node.url.detectedLanguage
        return language.info.icon
    }
    
    private func colorForFile(_ node: FileNode) -> Color {
        if node.isDirectory { return .appAccent }
        let ext = node.url.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) { return .pink }
        if ext == "pdf" { return .red }
        let language = node.url.detectedLanguage
        return language.info.color
    }

    private func childrenFor(_ node: FileNode) -> [FileNode] {
        if node.url == vm.rootURL { return vm.rootNode?.children ?? [] }
        return FileNode.loadChildren(of: node.url, showHidden: vm.showHiddenFiles)
    }

    private func isVisible(_ node: FileNode) -> Bool {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return true }
        if node.name.localizedCaseInsensitiveContains(q) { return true }
        if node.isDirectory { return hasDescendantMatch(node, query: q) }
        return false
    }

    private func hasDescendantMatch(_ node: FileNode, query: String) -> Bool {
        for child in childrenFor(node) {
            if child.name.localizedCaseInsensitiveContains(query) { return true }
            if child.isDirectory && hasDescendantMatch(child, query: query) { return true }
        }
        return false
    }
}

struct ServerFileTreeNodeView: View {
    let node: ServerFileNode
    @ObservedObject var vm: WorkspaceViewModel
    let level: Int
    @State private var children: [ServerFileNode] = []
    @State private var isLoading = false
    @State private var hover = false
    
    var isExpanded: Bool {
        vm.expandedServerPaths.contains(node.path)
    }
    
    var isActiveFile: Bool {
        if node.isFolder { return false }
        let tempPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("server_\(node.path.replacingOccurrences(of: "/", with: "_"))")
            .path
        return vm.activeFileID == tempPath
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Theme.spacingS) {
                if node.isFolder {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.appTextTertiary)
                        .frame(width: 12)
                } else {
                    Spacer()
                        .frame(width: 12)
                }
                
                Image(systemName: iconForNode())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(colorForNode())
                    .frame(width: 20)
                
                Text(node.name)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
                
                if hover {
                    Button(action: { vm.deleteServerFileNode(node) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.red)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, CGFloat(level) * 16 + Theme.spacingM)
            .padding(.trailing, Theme.spacingM)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .fill(isActiveFile ? Color.appAccent.opacity(0.15) : (hover ? Color.appSurfaceHover : Color.clear))
            )
            .onTapGesture {
                if node.isFolder {
                    toggleFolder()
                } else {
                    vm.openServerFile(node)
                }
            }
            .onHover { h in
                withAnimation(.easeInOut(duration: Theme.animationFast)) { hover = h }
            }
            
            if node.isFolder && isExpanded {
                ForEach(children) { child in
                    ServerFileTreeNodeView(node: child, vm: vm, level: level + 1)
                }
            }
        }
        .onAppear {
            if node.isFolder && isExpanded {
                loadChildren()
            }
        }
    }
    
    private func toggleFolder() {
        if isExpanded {
            vm.expandedServerPaths.remove(node.path)
        } else {
            vm.expandedServerPaths.insert(node.path)
            loadChildren()
        }
    }
    
    private func loadChildren() {
        if let cached = node.children {
            children = cached
            return
        }
        
        isLoading = true
        vm.loadServerChildren(for: node) { loadedChildren in
            self.children = loadedChildren
            self.isLoading = false
        }
    }
    
    private func iconForNode() -> String {
        if node.isFolder {
            return isExpanded ? "folder.fill" : "folder"
        }
        let ext = (node.name as NSString).pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) { return "photo.fill" }
        if ext == "pdf" { return "doc.richtext.fill" }
        if ["swift", "js", "py", "java", "cpp", "c", "h"].contains(ext) { return "doc.text.fill" }
        return "doc"
    }
    
    private func colorForNode() -> Color {
        if node.isFolder { return .appAccent }
        let ext = (node.name as NSString).pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) { return .pink }
        if ext == "pdf" { return .red }
        if ext == "swift" { return .orange }
        if ext == "js" { return .yellow }
        if ext == "py" { return .blue }
        return .appTextSecondary
    }
}

struct ServerFileRowView: View {
    let file: ServerFileNode
    @ObservedObject var vm: WorkspaceViewModel
    
    var body: some View {
        Button(action: {
            if !file.isFolder {
                vm.openServerFile(file)
            }
        }) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: file.isFolder ? "folder.fill" : iconForFile(file.name))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(file.isFolder ? Color.appAccent : colorForFile(file.name))
                    .frame(width: 20)
                
                Text(file.name)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .fill(Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func openServerFile() {
        let requestBody: [String: Any] = [:]
        let command = "/get_file?file_path=\(file.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? file.path)"
        
        ServerManager.shared.executeServerCommand(command: command, method: "GET", body: requestBody, waitTime: 5) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let json = response as? [String: Any],
                       let status = json["status"] as? String, status == "File content retrieved",
                       let content = json["content"] as? String,
                       let type = json["type"] as? String {
                        
                        if type == "text" {
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
                            try? content.write(to: tempURL, atomically: true, encoding: .utf8)
                            
                            if vm.openFiles.contains(where: { $0.id == tempURL.path }) {
                                vm.activeFileID = tempURL.path
                            } else {
                                let openFile = WorkspaceViewModel.OpenFile(
                                    url: tempURL,
                                    content: content,
                                    isDirty: false
                                )
                                vm.openFiles.append(openFile)
                                vm.activeFileID = openFile.id
                            }
                        }
                    }
                case .failure(let error):
                    print("Failed to open server file: \(error)")
                }
            }
        }
    }
    
    private func iconForFile(_ fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) { return "photo.fill" }
        if ext == "pdf" { return "doc.richtext.fill" }
        return "doc.text.fill"
    }
    
    private func colorForFile(_ fileName: String) -> Color {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) { return .pink }
        if ext == "pdf" { return .red }
        return .appTextSecondary
    }
}
