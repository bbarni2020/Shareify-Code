//
//  WorkspaceViewModel.swift
//  Shareify Code
//

import Foundation
import SwiftUI
import Combine

#if os(macOS)
import AppKit
#endif

final class WorkspaceViewModel: ObservableObject {
    @Published var rootURL: URL?
    @Published var rootNode: FileNode?
    @Published var expanded: Set<String> = []
    @Published var showHiddenFiles = false
    @Published var showFolderImporter = false

    struct OpenFile: Identifiable, Hashable {
        var id: String { url.path }
        let url: URL
        var title: String { url.lastPathComponent }
        var content: String
        var isDirty: Bool = false
        var cursorLine: Int = 1
        var cursorColumn: Int = 1
    }

    @Published var openFiles: [OpenFile] = []
    @Published var activeFileID: String?

    func openFolder() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Open"
        if panel.runModal() == .OK, let url = panel.url {
            loadRoot(url)
        }
        #else
        showFolderImporter = true
        #endif
    }

    func loadRoot(_ url: URL) {
        rootURL = url
        rootNode = FileNode.makeRoot(from: url, showHidden: showHiddenFiles)
        expanded = [url.path]
    }

    func setRootFromPickedURL(_ url: URL) {
        #if os(iOS)
        let accessed = url.startAccessingSecurityScopedResource()
        _ = accessed
        #endif
        loadRoot(url)
    }

    func refreshNode(_ node: FileNode) {
        guard node.isDirectory else { return }
        if node.url == rootURL {
            rootNode?.children = FileNode.loadChildren(of: node.url, showHidden: showHiddenFiles)
        } else {
            if let rootURL { rootNode = FileNode.makeRoot(from: rootURL, showHidden: showHiddenFiles) }
        }
        objectWillChange.send()
    }

    func toggleExpanded(_ node: FileNode) {
        guard node.isDirectory else { return }
        if expanded.contains(node.id) {
            expanded.remove(node.id)
        } else {
            expanded.insert(node.id)
            if node.children == nil {
                if node.url == rootURL {
                    rootNode?.children = FileNode.loadChildren(of: node.url, showHidden: showHiddenFiles)
                } else {
                    if let rootURL { rootNode = FileNode.makeRoot(from: rootURL, showHidden: showHiddenFiles) }
                }
            }
        }
    }

    func openFile(_ url: URL) {
        if let existing = openFiles.firstIndex(where: { $0.url == url }) {
            activeFileID = openFiles[existing].id
            return
        }
    let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let file = OpenFile(url: url, content: content)
        openFiles.append(file)
        activeFileID = file.id
    }

    func closeFile(_ id: String) {
        if let idx = openFiles.firstIndex(where: { $0.id == id }) {
            openFiles.remove(at: idx)
            if activeFileID == id {
                activeFileID = openFiles.last?.id
            }
        }
    }

    func updateActiveContent(_ text: String) {
        guard let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) else { return }
        openFiles[idx].content = text
        openFiles[idx].isDirty = true
    }

    func saveActive() {
        guard let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) else { return }
        let f = openFiles[idx]
        do {
            try f.content.write(to: f.url, atomically: true, encoding: .utf8)
            openFiles[idx].isDirty = false
        } catch {
            print("Save error: \(error)")
        }
    }
}
