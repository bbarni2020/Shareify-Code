//
//  ExplorerView.swift
//  Shareify Code
//


import SwiftUI

struct ExplorerView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @State private var showNewFileSheet = false
    @State private var showNewFolderSheet = false
    @State private var newFileName = ""
    @State private var newFolderName = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Explorer")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)

                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Button(action: { showNewFileSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.callout)
                                Text("File")
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(vm.rootNode != nil ? Color.appAccent.opacity(0.15) : Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(vm.rootNode != nil ? Color.appAccent.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.rootNode == nil)
                        .opacity(vm.rootNode == nil ? 0.5 : 1.0)

                        Button(action: { showNewFolderSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.callout)
                                Text("Folder")
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(vm.rootNode != nil ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(vm.rootNode != nil ? Color.orange.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.rootNode == nil)
                        .opacity(vm.rootNode == nil ? 0.5 : 1.0)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: { if let root = vm.rootNode { vm.refreshNode(root) } }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .glassButtonStyleIfAvailable()

                        Button(action: vm.openFolder) {
                            Image(systemName: "folder")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .glassButtonStyleIfAvailable()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }
            .glassLikeBackground()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Divider()

            if let root = vm.rootNode {
                ScrollViewReader { _ in
                    ScrollView {
                        FileTreeNodeView(node: root, vm: vm)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("No Folder Open")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                    Button(action: vm.openFolder) {
                        Label("Open Folder", systemImage: "folder")
                            .font(.title2)
                    }
                    .glassButtonStyleIfAvailable()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 320)
        .background(Color.clear)
        .sheet(isPresented: $showNewFileSheet) {
            NewItemSheet(
                title: "Create New File",
                icon: "doc.badge.plus",
                iconColor: .appAccent,
                placeholder: "filename.swift",
                itemName: $newFileName,
                onCreate: {
                    if let root = vm.rootURL, !newFileName.isEmpty {
                        let url = root.appendingPathComponent(newFileName)
                        FileManager.default.createFile(atPath: url.path, contents: nil)
                        vm.refreshNode(FileNode(url: root, isDirectory: true))
                    }
                    showNewFileSheet = false
                    newFileName = ""
                },
                onCancel: {
                    showNewFileSheet = false
                    newFileName = ""
                }
            )
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewItemSheet(
                title: "Create New Folder",
                icon: "folder.badge.plus",
                iconColor: .orange,
                placeholder: "my-folder",
                itemName: $newFolderName,
                onCreate: {
                    if let root = vm.rootURL, !newFolderName.isEmpty {
                        let url = root.appendingPathComponent(newFolderName)
                        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                        vm.refreshNode(FileNode(url: root, isDirectory: true))
                    }
                    showNewFolderSheet = false
                    newFolderName = ""
                },
                onCancel: {
                    showNewFolderSheet = false
                    newFolderName = ""
                }
            )
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
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(20)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.1))
                    )
                
                Text(title)
                    .font(.title2.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $itemName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isTextFieldFocused ? iconColor : Color.clear, lineWidth: 2)
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !itemName.isEmpty {
                            onCreate()
                        }
                    }
            }
            
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray5))
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: onCreate) {
                    Text("Create")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: itemName.isEmpty ? [.gray] : [iconColor, iconColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(itemName.isEmpty)
                .opacity(itemName.isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

private struct FileTreeNodeView: View {
    let node: FileNode
    @ObservedObject var vm: WorkspaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            row(node)
            if node.isDirectory, vm.expanded.contains(node.id) {
                let children = childrenFor(node)
                if !children.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(children, id: \.id) { child in
                            FileTreeNodeView(node: child, vm: vm)
                                .padding(.leading, 12)
                        }
                    }
                }
            }
        }
    }

    private func row(_ node: FileNode) -> some View {
        HStack(spacing: 8) {
            if node.isDirectory {
                Image(systemName: vm.expanded.contains(node.id) ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }

            Image(systemName: iconForFile(node))
                .font(.body)
                .foregroundStyle(colorForFile(node))
                .frame(width: 20)

            Text(node.name)
                .font(.system(.body, design: .rounded))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 1) {
            if node.isDirectory {
                vm.toggleExpanded(node)
            } else {
                vm.openFile(node.url)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(vm.activeFileID == node.url.path ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }
    
    private func iconForFile(_ node: FileNode) -> String {
        if node.isDirectory {
            return vm.expanded.contains(node.id) ? "folder.fill" : "folder"
        }

        let ext = node.url.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) {
            return "photo"
        }

        if ext == "pdf" { return "doc.richtext" }

        let language = node.url.detectedLanguage
        return language.info.icon
    }
    
    private func colorForFile(_ node: FileNode) -> Color {
        if node.isDirectory {
            return .appAccent
        }

        let ext = node.url.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "ico", "bmp", "webp"]
        if imageExtensions.contains(ext) {
            return .pink
        }
        
        if ext == "pdf" { return .red }

        let language = node.url.detectedLanguage
        return language.info.color
    }

    private func childrenFor(_ node: FileNode) -> [FileNode] {
        if node.url == vm.rootURL {
            return vm.rootNode?.children ?? []
        }
        return FileNode.loadChildren(of: node.url, showHidden: vm.showHiddenFiles)
    }
}
