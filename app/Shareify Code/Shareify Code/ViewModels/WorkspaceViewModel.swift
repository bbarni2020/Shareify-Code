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
    @Published var selectedNode: FileNode?

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

    func collapseAll() {
        if let rootURL { expanded = [rootURL.path] } else { expanded = [] }
    }

    func expandAll() {
        guard let root = rootNode else { return }
        var set: Set<String> = []
        collectDirectories(from: root, into: &set)
        expanded = set
    }

    private func collectDirectories(from node: FileNode, into set: inout Set<String>) {
        if node.isDirectory { set.insert(node.id) }
        let children = node.children ?? FileNode.loadChildren(of: node.url, showHidden: showHiddenFiles)
        for child in children where child.isDirectory {
            collectDirectories(from: child, into: &set)
        }
    }

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
        _ = url.startAccessingSecurityScopedResource()
        
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: "lastOpenedFolder")
        } catch {
            print("Failed to create bookmark: \(error)")
        }
        #endif
        loadRoot(url)
    }

    func refreshNode(_ node: FileNode) {
        guard node.isDirectory else { return }
        if let rootURL {
            rootNode = FileNode.makeRoot(from: rootURL, showHidden: showHiddenFiles)
        }
        objectWillChange.send()
    }
    
    func createFile(name: String, in parentNode: FileNode?) {
        guard !name.isEmpty else { return }
        let parent = parentNode ?? (rootNode != nil ? FileNode(url: rootURL!, isDirectory: true) : nil)
        guard let parent = parent, parent.isDirectory else { return }
        
        #if os(iOS)
        let accessing = parent.url.startAccessingSecurityScopedResource()
        defer { if accessing { parent.url.stopAccessingSecurityScopedResource() } }
        #endif
        
        let fileURL = parent.url.appendingPathComponent(name)
        if FileManager.default.createFile(atPath: fileURL.path, contents: Data()) {
            expanded.insert(parent.id)
            refreshNode(parent)
        }
    }
    
    func createFolder(name: String, in parentNode: FileNode?) {
        guard !name.isEmpty else { return }
        let parent = parentNode ?? (rootNode != nil ? FileNode(url: rootURL!, isDirectory: true) : nil)
        guard let parent = parent, parent.isDirectory else { return }
        
        #if os(iOS)
        let accessing = parent.url.startAccessingSecurityScopedResource()
        defer { if accessing { parent.url.stopAccessingSecurityScopedResource() } }
        #endif
        
        let folderURL = parent.url.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            expanded.insert(parent.id)
            refreshNode(parent)
        } catch {
            print("Folder creation failed: \(error)")
        }
    }

    func toggleExpanded(_ node: FileNode) {
        guard node.isDirectory else { return }
        if expanded.contains(node.id) {
            expanded.remove(node.id)
        } else {
            expanded.insert(node.id)
            if node.children == nil {
                if let rootURL { 
                    rootNode = FileNode.makeRoot(from: rootURL, showHidden: showHiddenFiles) 
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
