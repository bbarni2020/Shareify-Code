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
    @Published var isServerFolder = false
    @Published var serverFolderPath: String?
    @Published var serverRootNode: ServerFileNode?
    @Published var expandedServerPaths: Set<String> = []
    
    private var serverFolderCache: [String: [ServerFileNode]] = [:]
    private var serverFileContentCache: [String: String] = [:]

    struct OpenFile: Identifiable, Hashable {
        var id: String { url.path }
        let url: URL
        var customTitle: String?
        var title: String { customTitle ?? url.lastPathComponent }
        var content: String
        var isDirty: Bool = false
        var isLoading: Bool = false
        var cursorLine: Int = 1
        var cursorColumn: Int = 1
    }

    @Published var openFiles: [OpenFile] = []
    @Published var activeFileID: String?
    @Published var fileToClose: String?
    @Published var showUnsavedWarning = false
    
    init() {
        loadCacheFromUserDefaults()
    }

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
        isServerFolder = false
        serverFolderPath = nil
        serverRootNode = nil
        expandedServerPaths = []

        saveOpenFilesCache()
        
        openFiles = []
        activeFileID = nil
        
        rootURL = url
        rootNode = FileNode.makeRoot(from: url, showHidden: showHiddenFiles)
        expanded = [url.path]

        UserDefaults.standard.set(url.path, forKey: "lastLocalFolderPath")
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
            if openFiles[idx].isDirty {
                fileToClose = id
                showUnsavedWarning = true
            } else {
                performCloseFile(id)
            }
        }
    }
    
    func performCloseFile(_ id: String) {
        if let idx = openFiles.firstIndex(where: { $0.id == id }) {
            openFiles.remove(at: idx)
            if activeFileID == id {
                activeFileID = openFiles.last?.id
            }
        }
        fileToClose = nil
        showUnsavedWarning = false
    }
    
    func saveAndCloseFile(_ id: String) {
        if let idx = openFiles.firstIndex(where: { $0.id == id }) {
            let f = openFiles[idx]
            do {
                try f.content.write(to: f.url, atomically: true, encoding: .utf8)
                openFiles[idx].isDirty = false
                performCloseFile(id)
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func cancelClose() {
        fileToClose = nil
        showUnsavedWarning = false
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
    
    func executeAction(_ action: AIAction) -> Result<String, Error> {
        switch action.type {
        case .edit(let old, let new):
            return executeEditAction(old: old, new: new)
            
        case .rewrite(let file, let content):
            return executeRewriteAction(file: file, content: content)
            
        case .insert(let after, let content):
            return executeInsertAction(after: after, content: content)
            
        case .terminal(let command, let reason):
            return .success("Terminal command ready: \(command)\nReason: \(reason)")
            
        case .search(let pattern, let reason):
            return .success("Search pattern: \(pattern)\nReason: \(reason)")
        }
    }
    
    private func executeEditAction(old: String, new: String) -> Result<String, Error> {
        guard let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) else {
            return .failure(NSError(domain: "AIAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active file"]))
        }
        
        let currentContent = openFiles[idx].content
        
        guard currentContent.contains(old) else {
            return .failure(NSError(domain: "AIAction", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find the code to replace. The file may have been modified."]))
        }
        
        let newContent = currentContent.replacingOccurrences(of: old, with: new)
        openFiles[idx].content = newContent
        openFiles[idx].isDirty = true
        
        return .success("Code successfully updated in \(openFiles[idx].title)")
    }
    
    private func executeRewriteAction(file: String, content: String) -> Result<String, Error> {
        guard let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) else {
            return .failure(NSError(domain: "AIAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active file"]))
        }
        
        if openFiles[idx].title != file {
            return .failure(NSError(domain: "AIAction", code: 3, userInfo: [NSLocalizedDescriptionKey: "File name mismatch. Expected \(openFiles[idx].title) but got \(file)"]))
        }
        
        openFiles[idx].content = content
        openFiles[idx].isDirty = true
        
        return .success("File \(file) completely rewritten")
    }
    
    private func executeInsertAction(after: String, content: String) -> Result<String, Error> {
        guard let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) else {
            return .failure(NSError(domain: "AIAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active file"]))
        }
        
        let currentContent = openFiles[idx].content
        
        guard let range = currentContent.range(of: after) else {
            return .failure(NSError(domain: "AIAction", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find the anchor point in the file"]))
        }
        
        let insertIndex = range.upperBound
        var newContent = currentContent
        newContent.insert(contentsOf: "\n\(content)", at: insertIndex)
        
        openFiles[idx].content = newContent
        openFiles[idx].isDirty = true
        
        return .success("Code successfully inserted in \(openFiles[idx].title)")
    }
    
    func loadServerFolder(path: String, files: [ServerFileNode]) {
        rootURL = nil
        self.rootNode = nil
        expanded = []

        saveOpenFilesCache()

        openFiles = []
        activeFileID = nil

        isServerFolder = true
        serverFolderPath = path
        
        let serverRoot = ServerFileNode(
            name: path.split(separator: "/").last.map(String.init) ?? "Root",
            path: path,
            isFolder: true,
            children: files
        )
        
        serverRootNode = serverRoot
        serverFolderCache[path] = files
        expandedServerPaths = [path]

        UserDefaults.standard.set(path, forKey: "lastServerFolderPath")
        saveCacheToUserDefaults()
    }
    
    func loadServerChildren(for node: ServerFileNode, completion: @escaping ([ServerFileNode]) -> Void) {
        if let cached = serverFolderCache[node.path] {
            completion(cached)
            return
        }
        
        let requestBody: [String: Any] = ["path": node.path]
        
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
                    
                    let children = fileNames.map { fileName in
                        ServerFileNode(
                            name: fileName,
                            path: node.path + "/" + fileName,
                            isFolder: !fileName.contains("."),
                            children: nil
                        )
                    }
                    
                    self.serverFolderCache[node.path] = children
                    self.saveCacheToUserDefaults()
                    completion(children)
                    
                case .failure(let error):
                    print("Failed to load server children: \(error)")
                    completion([])
                }
            }
        }
    }
    
    func openServerFile(_ file: ServerFileNode) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("server_\(file.path.replacingOccurrences(of: "/", with: "_"))")
        let serverTitle = "server\(file.path)"
 
        if openFiles.contains(where: { $0.id == tempURL.path }) {
            activeFileID = tempURL.path
            return
        }

        if let cachedContent = serverFileContentCache[file.path] {
            let openFile = OpenFile(
                url: tempURL,
                customTitle: serverTitle,
                content: cachedContent,
                isDirty: false,
                isLoading: false
            )
            openFiles.append(openFile)
            activeFileID = openFile.id
            return
        }

        let loadingFile = OpenFile(
            url: tempURL,
            customTitle: serverTitle,
            content: "Loading...",
            isDirty: false,
            isLoading: true
        )
        openFiles.append(loadingFile)
        activeFileID = loadingFile.id

        let command = "/get_file?file_path=\(file.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? file.path)"
        ServerManager.shared.executeServerCommand(command: command, method: "GET", body: [:], waitTime: 5) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let json = response as? [String: Any],
                       let status = json["status"] as? String, status == "File content retrieved",
                       let content = json["content"] as? String,
                       let type = json["type"] as? String, type == "text" {

                        self.serverFileContentCache[file.path] = content
                        self.saveCacheToUserDefaults()
                        
                        if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                            self.openFiles[idx].content = content
                            self.openFiles[idx].isLoading = false
                            try? content.write(to: tempURL, atomically: true, encoding: .utf8)
                        }
                    } else {
                        if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                            self.openFiles.remove(at: idx)
                            if self.activeFileID == tempURL.path {
                                self.activeFileID = self.openFiles.last?.id
                            }
                        }
                    }
                case .failure(let error):
                    print("Failed to open server file: \(error)")
                    if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                        self.openFiles.remove(at: idx)
                        if self.activeFileID == tempURL.path {
                            self.activeFileID = self.openFiles.last?.id
                        }
                    }
                }
            }
        }
    }
    
    private func saveCacheToUserDefaults() {
        if let folderData = try? JSONEncoder().encode(serverFolderCache) {
            UserDefaults.standard.set(folderData, forKey: "serverFolderCache")
        }
        if let contentData = try? JSONEncoder().encode(serverFileContentCache) {
            UserDefaults.standard.set(contentData, forKey: "serverFileContentCache")
        }
    }
    
    private func saveOpenFilesCache() {
        let openFilePaths = openFiles.map { $0.url.path }
        UserDefaults.standard.set(openFilePaths, forKey: "openFilePaths")
        UserDefaults.standard.set(activeFileID, forKey: "activeFileID")
        
        if isServerFolder {
            UserDefaults.standard.set(true, forKey: "wasServerFolder")
        } else {
            UserDefaults.standard.set(false, forKey: "wasServerFolder")
        }
    }
    
    func loadCacheFromUserDefaults() {
        if let folderData = UserDefaults.standard.data(forKey: "serverFolderCache"),
           let cache = try? JSONDecoder().decode([String: [ServerFileNode]].self, from: folderData) {
            serverFolderCache = cache
        }
        if let contentData = UserDefaults.standard.data(forKey: "serverFileContentCache"),
           let cache = try? JSONDecoder().decode([String: String].self, from: contentData) {
            serverFileContentCache = cache
        }

        let wasServerFolder = UserDefaults.standard.bool(forKey: "wasServerFolder")
        
        if wasServerFolder {
            if let lastServerPath = UserDefaults.standard.string(forKey: "lastServerFolderPath"),
               let cachedFiles = serverFolderCache[lastServerPath] {
                let serverRoot = ServerFileNode(
                    name: lastServerPath.split(separator: "/").last.map(String.init) ?? "Root",
                    path: lastServerPath,
                    isFolder: true,
                    children: cachedFiles
                )
                
                isServerFolder = true
                serverFolderPath = lastServerPath
                serverRootNode = serverRoot
                expandedServerPaths = [lastServerPath]
            }
        } else {
            if let lastLocalPath = UserDefaults.standard.string(forKey: "lastLocalFolderPath") {
                let url = URL(fileURLWithPath: lastLocalPath)
                if FileManager.default.fileExists(atPath: lastLocalPath) {
                    rootURL = url
                    rootNode = FileNode.makeRoot(from: url, showHidden: showHiddenFiles)
                    expanded = [url.path]
                }
            }
        }
    }
}

struct ServerFileNode: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let isFolder: Bool
    var children: [ServerFileNode]?
    
    init(name: String, path: String, isFolder: Bool, children: [ServerFileNode]? = nil) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.isFolder = isFolder
        self.children = children
    }
    
    static func == (lhs: ServerFileNode, rhs: ServerFileNode) -> Bool {
        lhs.path == rhs.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}
