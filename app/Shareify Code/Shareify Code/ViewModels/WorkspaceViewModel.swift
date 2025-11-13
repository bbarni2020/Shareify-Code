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
    @Published var isLoadingServerFolder = false
    
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
        var binaryData: Data?
        var isServerFile: Bool = false
        
        var fileType: FileType {
            let ext = url.pathExtension.lowercased()
            if ["png", "jpg", "jpeg", "gif", "svg", "bmp", "webp", "ico", "heic"].contains(ext) {
                return .image
            } else if ["mp4", "mov", "avi", "mkv", "m4v", "webm"].contains(ext) {
                return .video
            } else if ["mp3", "wav", "m4a", "aac", "flac", "ogg"].contains(ext) {
                return .audio
            } else if ext == "pdf" {
                return .pdf
            } else {
                return .text
            }
        }
        
        enum FileType {
            case text
            case image
            case video
            case audio
            case pdf
        }
    }
    
    struct Note: Identifiable, Codable {
        let id: UUID
        var title: String
        var drawingData: Data
        var createdAt: Date
        var modifiedAt: Date
        
        init(id: UUID = UUID(), title: String, drawingData: Data = Data(), createdAt: Date = Date(), modifiedAt: Date = Date()) {
            self.id = id
            self.title = title
            self.drawingData = drawingData
            self.createdAt = createdAt
            self.modifiedAt = modifiedAt
        }
    }

    @Published var openFiles: [OpenFile] = []
    @Published var activeFileID: String?
    @Published var fileToClose: String?
    @Published var showUnsavedWarning = false
    @Published var notes: [Note] = []
    @Published var showNotesView = false
    
    init() {
        loadCacheFromUserDefaults()
        loadNotes()
        checkServerAvailabilityForCache()
    }
    
    private func checkServerAvailabilityForCache() {
        if isServerFolder, let _ = serverFolderPath {
            ServerManager.shared.testServerConnection { isOnline in
                DispatchQueue.main.async {
                    if !isOnline {
                        self.clearServerFolderAndShowDefault()
                    }
                }
            }
        }
    }
    
    private func clearServerFolderAndShowDefault() {
        rootURL = nil
        rootNode = nil
        expanded = []
        isServerFolder = false
        serverFolderPath = nil
        serverRootNode = nil
        expandedServerPaths = []
        openFiles = []
        activeFileID = nil
        
        UserDefaults.standard.removeObject(forKey: "lastServerFolderPath")
        UserDefaults.standard.set(false, forKey: "wasServerFolder")
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
        rootURL = nil
        rootNode = nil
        expanded = []
        isServerFolder = false
        serverFolderPath = nil
        serverRootNode = nil
        expandedServerPaths = []

        saveOpenFilesCache()
        
        openFiles = []
        activeFileID = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.rootURL = url
            self.rootNode = FileNode.makeRoot(from: url, showHidden: self.showHiddenFiles)
            self.expanded = [url.path]
            
            UserDefaults.standard.set(url.path, forKey: "lastLocalFolderPath")
        }
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
        
        if isServerFolder {
            createServerFile(name: name, in: parentNode)
            return
        }
        
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
        
        if isServerFolder {
            createServerFolder(name: name, in: parentNode)
            return
        }
        
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
    
    func deleteFile(_ node: FileNode) {
        if isServerFolder {
            deleteServerFile(node)
            return
        }
        
        #if os(iOS)
        let accessing = node.url.startAccessingSecurityScopedResource()
        defer { if accessing { node.url.stopAccessingSecurityScopedResource() } }
        #endif
        
        do {
            try FileManager.default.removeItem(at: node.url)
            
            if let idx = openFiles.firstIndex(where: { $0.url == node.url }) {
                openFiles.remove(at: idx)
                if activeFileID == node.url.path {
                    activeFileID = openFiles.last?.id
                }
            }
            
            if let rootURL {
                rootNode = FileNode.makeRoot(from: rootURL, showHidden: showHiddenFiles)
            }
        } catch {
            print("Delete failed: \(error)")
        }
    }
    
    func deleteServerFileNode(_ node: ServerFileNode) {
        guard isServerFolder else { return }
        
        let command = node.isFolder ? "/api/delete_folder" : "/api/delete_file"
        let requestBody: [String: Any] = ["path": node.path]
        
        ServerManager.shared.executeServerCommand(command: command, method: "POST", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("server_\(node.path.replacingOccurrences(of: "/", with: "_"))")
                    
                    if let idx = self.openFiles.firstIndex(where: { $0.url.path == tempURL.path }) {
                        self.openFiles.remove(at: idx)
                        if self.activeFileID == tempURL.path {
                            self.activeFileID = self.openFiles.last?.id
                        }
                    }
                    
                    self.serverFileContentCache.removeValue(forKey: node.path)
                    
                    if let serverPath = self.serverFolderPath {
                        self.serverFolderCache.removeValue(forKey: serverPath)
                        self.refreshServerFolder()
                    }
                    
                case .failure(let error):
                    print("Failed to delete server file/folder: \(error)")
                }
            }
        }
    }
    
    private func deleteServerFile(_ node: FileNode) {
        guard isServerFolder, let customTitle = openFiles.first(where: { $0.url.path.contains(node.url.lastPathComponent) })?.customTitle else { return }
        
        let filePath = customTitle.replacingOccurrences(of: "server", with: "")
        
        let requestBody: [String: Any] = ["path": filePath]
        
        ServerManager.shared.executeServerCommand(command: "/api/delete_file", method: "POST", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    if let idx = self.openFiles.firstIndex(where: { $0.url == node.url }) {
                        self.openFiles.remove(at: idx)
                        if self.activeFileID == node.url.path {
                            self.activeFileID = self.openFiles.last?.id
                        }
                    }
                    
                    self.serverFileContentCache.removeValue(forKey: filePath)
                    
                    if let serverPath = self.serverFolderPath {
                        self.serverFolderCache.removeValue(forKey: serverPath)
                        self.refreshServerFolder()
                    }
                    
                case .failure(let error):
                    print("Failed to delete server file: \(error)")
                }
            }
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
        
        let ext = url.pathExtension.lowercased()
        let binaryExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "ico", "heic",
                               "mp4", "mov", "avi", "mkv", "m4v", "webm",
                               "mp3", "wav", "m4a", "aac", "flac", "ogg",
                               "pdf"]
        
        if binaryExtensions.contains(ext) {
            let binaryData = try? Data(contentsOf: url)
            let file = OpenFile(url: url, content: "", binaryData: binaryData)
            openFiles.append(file)
            activeFileID = file.id
        } else {
            let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let file = OpenFile(url: url, content: content)
            openFiles.append(file)
            activeFileID = file.id
        }
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
        
        if f.customTitle?.hasPrefix("server") == true {
            saveServerFile(f)
            return
        }
        
        do {
            try f.content.write(to: f.url, atomically: true, encoding: .utf8)
            openFiles[idx].isDirty = false
        } catch {
            print("Save error: \(error)")
        }
    }
    
    func executeAction(_ action: AIAction) -> Result<String, Error> {
        switch action.type {
        case .edit(let old, let new, let file):
            return executeEditAction(old: old, new: new, file: file)
            
        case .rewrite(let file, let content):
            return executeRewriteAction(file: file, content: content)
            
        case .insert(let after, let content, let file):
            return executeInsertAction(after: after, content: content, file: file)
            
        case .create(let file, let content):
            return executeCreateAction(file: file, content: content)
            
        case .terminal(let command, let reason):
            return .success("Terminal command ready: \(command)\nReason: \(reason)")
            
        case .search(let pattern, let reason):
            return .success("Search pattern: \(pattern)\nReason: \(reason)")
        }
    }
    
    struct ActionPreview {
        let title: String
        let file: String?
        let before: String?
        let after: String
    }
    
    func previewAction(_ action: AIAction) -> Result<ActionPreview, Error> {
        switch action.type {
        case .edit(let old, let new, let file):
            var targetURL: URL?
            if let file, let url = resolveURL(for: file) { targetURL = url }
            else if let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) { targetURL = openFiles[idx].url }
            guard let url = targetURL, let idx = openOrFindIndex(for: url) else {
                return .failure(NSError(domain: "AIAction", code: 10, userInfo: [NSLocalizedDescriptionKey: "Target file not found"]))
            }
            let before = openFiles[idx].content
            guard before.contains(old) else {
                return .failure(NSError(domain: "AIAction", code: 11, userInfo: [NSLocalizedDescriptionKey: "Old snippet not found"]))
            }
            let after = before.replacingOccurrences(of: old, with: new)
            return .success(ActionPreview(title: "Edit Preview", file: url.lastPathComponent, before: before, after: after))
        case .insert(let after, let content, let file):
            var targetURL: URL?
            if let file, let url = resolveURL(for: file) { targetURL = url }
            else if let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) { targetURL = openFiles[idx].url }
            guard let url = targetURL, let idx = openOrFindIndex(for: url) else {
                return .failure(NSError(domain: "AIAction", code: 12, userInfo: [NSLocalizedDescriptionKey: "Target file not found"]))
            }
            let before = openFiles[idx].content
            guard let range = before.range(of: after) else {
                return .failure(NSError(domain: "AIAction", code: 13, userInfo: [NSLocalizedDescriptionKey: "Anchor not found"]))
            }
            let insertIndex = range.upperBound
            var newText = before
            newText.insert(contentsOf: "\n\(content)", at: insertIndex)
            return .success(ActionPreview(title: "Insert Preview", file: url.lastPathComponent, before: before, after: newText))
        case .rewrite(let file, let content):
            if let url = resolveURL(for: file), let idx = openOrFindIndex(for: url) {
                let before = openFiles[idx].content
                return .success(ActionPreview(title: "Rewrite Preview", file: url.lastPathComponent, before: before, after: content))
            }
            return .success(ActionPreview(title: "Rewrite Preview (new file)", file: file, before: nil, after: content))
        case .create(let file, let content):
            return .success(ActionPreview(title: "Create File Preview", file: file, before: nil, after: content))
        case .terminal(let command, let reason):
            let text = "Command: \(command)\nReason: \(reason)"
            return .success(ActionPreview(title: "Terminal", file: nil, before: nil, after: text))
        case .search(let pattern, let reason):
            let text = "Pattern: \(pattern)\nReason: \(reason)"
            return .success(ActionPreview(title: "Search", file: nil, before: nil, after: text))
        }
    }
    
    private func resolveURL(for fileSpec: String) -> URL? {
        let fm = FileManager.default
        if fileSpec.hasPrefix("/") {
            let url = URL(fileURLWithPath: fileSpec)
            return fm.fileExists(atPath: url.path) ? url : nil
        }
        if let root = rootURL {
            let url = root.appendingPathComponent(fileSpec)
            if fm.fileExists(atPath: url.path) { return url }
        }
        if let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) {
            let base = openFiles[idx].url.deletingLastPathComponent()
            let url = base.appendingPathComponent(fileSpec)
            if fm.fileExists(atPath: url.path) { return url }
        }
        if let url = openFiles.first(where: { $0.url.lastPathComponent == fileSpec })?.url {
            return url
        }
        return nil
    }
    
    private func openOrFindIndex(for url: URL) -> Int? {
        if let idx = openFiles.firstIndex(where: { $0.url == url }) { return idx }
        openFile(url)
        return openFiles.firstIndex(where: { $0.url == url })
    }
    
    private func executeEditAction(old: String, new: String, file: String?) -> Result<String, Error> {
        var targetIdx: Int?
        if let file, let url = resolveURL(for: file), let idx = openOrFindIndex(for: url) {
            targetIdx = idx
        } else if let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) {
            targetIdx = idx
        }
        guard let idx = targetIdx else {
            return .failure(NSError(domain: "AIAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "Target file not found"]))
        }
        let currentContent = openFiles[idx].content
        guard currentContent.contains(old) else {
            return .failure(NSError(domain: "AIAction", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find the code to replace."]))
        }
        let newContent = currentContent.replacingOccurrences(of: old, with: new)
        openFiles[idx].content = newContent
        openFiles[idx].isDirty = true
        persistFile(at: idx)
        return .success("Code updated in \(openFiles[idx].title)")
    }
    
    private func executeRewriteAction(file: String, content: String) -> Result<String, Error> {
        let fm = FileManager.default
        if let url = resolveURL(for: file), let idx = openOrFindIndex(for: url) {
            openFiles[idx].content = content
            openFiles[idx].isDirty = true
            persistFile(at: idx)
            return .success("File \(openFiles[idx].title) rewritten")
        }
        guard let base = rootURL ?? openFiles.first?.url.deletingLastPathComponent() else {
            return .failure(NSError(domain: "AIAction", code: 4, userInfo: [NSLocalizedDescriptionKey: "No workspace root"]))
        }
        let targetURL = base.appendingPathComponent(file)
        do {
            try fm.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: targetURL, atomically: true, encoding: .utf8)
            openFile(targetURL)
            return .success("File \(targetURL.lastPathComponent) created and written")
        } catch {
            return .failure(error)
        }
    }
    
    private func executeInsertAction(after: String, content: String, file: String?) -> Result<String, Error> {
        var targetIdx: Int?
        if let file, let url = resolveURL(for: file), let idx = openOrFindIndex(for: url) {
            targetIdx = idx
        } else if let id = activeFileID, let idx = openFiles.firstIndex(where: { $0.id == id }) {
            targetIdx = idx
        }
        guard let idx = targetIdx else {
            return .failure(NSError(domain: "AIAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "Target file not found"]))
        }
        let currentContent = openFiles[idx].content
        guard let range = currentContent.range(of: after) else {
            return .failure(NSError(domain: "AIAction", code: 2, userInfo: [NSLocalizedDescriptionKey: "Anchor not found"]))
        }
        let insertIndex = range.upperBound
        var newContent = currentContent
        newContent.insert(contentsOf: "\n\(content)", at: insertIndex)
        openFiles[idx].content = newContent
        openFiles[idx].isDirty = true
        persistFile(at: idx)
        return .success("Code inserted in \(openFiles[idx].title)")
    }
    
    private func executeCreateAction(file: String, content: String) -> Result<String, Error> {
        guard let base = rootURL ?? openFiles.first?.url.deletingLastPathComponent() else {
            return .failure(NSError(domain: "AIAction", code: 4, userInfo: [NSLocalizedDescriptionKey: "No workspace root"]))
        }
        let fm = FileManager.default
        let targetURL = base.appendingPathComponent(file)
        do {
            try fm.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !fm.fileExists(atPath: targetURL.path) {
                fm.createFile(atPath: targetURL.path, contents: nil)
            }
            try content.write(to: targetURL, atomically: true, encoding: .utf8)
            openFile(targetURL)
            return .success("File created: \(file)")
        } catch {
            return .failure(error)
        }
    }

    private func persistFile(at idx: Int) {
        let f = openFiles[idx]
        if f.customTitle?.hasPrefix("server") == true {
            saveServerFile(f)
            return
        }
        do {
            try f.content.write(to: f.url, atomically: true, encoding: .utf8)
            openFiles[idx].isDirty = false
        } catch {
            print("Save error: \(error)")
        }
    }
    
    func loadServerFolder(path: String, files: [ServerFileNode]) {
        rootURL = nil
        rootNode = nil
        expanded = []
        isServerFolder = false
        serverFolderPath = nil
        serverRootNode = nil
        expandedServerPaths = []

        saveOpenFilesCache()

        openFiles = []
        activeFileID = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isServerFolder = true
            self.serverFolderPath = path
            
            let serverRoot = ServerFileNode(
                name: path.split(separator: "/").last.map(String.init) ?? "Root",
                path: path,
                isFolder: true,
                children: files
            )
            
            self.serverRootNode = serverRoot
            self.serverFolderCache[path] = files
            self.expandedServerPaths = [path]
            self.isLoadingServerFolder = false

            UserDefaults.standard.set(path, forKey: "lastServerFolderPath")
            self.saveCacheToUserDefaults()
        }
    }
    
    func setServerFolderLoading(path: String) {
        rootURL = nil
        rootNode = nil
        expanded = []
        isServerFolder = true
        serverFolderPath = path
        serverRootNode = nil
        expandedServerPaths = []
        isLoadingServerFolder = true
        
        saveOpenFilesCache()
        openFiles = []
        activeFileID = nil
    }
    
    func clearServerFolderLoading() {
        isLoadingServerFolder = false
        isServerFolder = false
        serverFolderPath = nil
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
                    if let cachedFallback = self.serverFolderCache[node.path] {
                        completion(cachedFallback)
                    } else {
                        completion([])
                    }
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
                isLoading: false,
                isServerFile: true
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
            isLoading: true,
            isServerFile: true
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
                       let type = json["type"] as? String {
                        
                        if type == "text" {
                            self.serverFileContentCache[file.path] = content
                            self.saveCacheToUserDefaults()
                            
                            if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                                self.openFiles[idx].content = content
                                self.openFiles[idx].isLoading = false
                                try? content.write(to: tempURL, atomically: true, encoding: .utf8)
                            }
                        } else if type == "binary" {
                            if let binaryData = Data(base64Encoded: content) {
                                try? binaryData.write(to: tempURL)
                                
                                if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                                    self.openFiles[idx].binaryData = binaryData
                                    self.openFiles[idx].isLoading = false
                                }
                            } else {
                                if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                                    self.openFiles.remove(at: idx)
                                    if self.activeFileID == tempURL.path {
                                        self.activeFileID = self.openFiles.last?.id
                                    }
                                }
                            }
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
                    
                    if let cachedContent = self.serverFileContentCache[file.path] {
                        if let idx = self.openFiles.firstIndex(where: { $0.id == tempURL.path }) {
                            self.openFiles[idx].content = cachedContent
                            self.openFiles[idx].isLoading = false
                            try? cachedContent.write(to: tempURL, atomically: true, encoding: .utf8)
                        }
                    } else {
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
    
    private func createServerFile(name: String, in parentNode: FileNode?) {
        guard let serverPath = serverFolderPath else { return }
        
        let path = serverPath.hasSuffix("/") ? serverPath : serverPath + "/"
        
        let requestBody: [String: Any] = [
            "file_name": name,
            "path": path,
            "file_content": ""
        ]
        
        ServerManager.shared.executeServerCommand(command: "/new_file", method: "POST", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.serverFolderCache.removeValue(forKey: serverPath)
                    self.refreshServerFolder()
                case .failure(let error):
                    print("Failed to create server file: \(error)")
                }
            }
        }
    }
    
    private func createServerFolder(name: String, in parentNode: FileNode?) {
        guard let serverPath = serverFolderPath else { return }
        
        let path = serverPath.hasSuffix("/") ? serverPath : serverPath + "/"
        
        let requestBody: [String: Any] = [
            "folder_name": name,
            "path": path
        ]
        
        ServerManager.shared.executeServerCommand(command: "/create_folder", method: "POST", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.serverFolderCache.removeValue(forKey: serverPath)
                    self.refreshServerFolder()
                case .failure(let error):
                    print("Failed to create server folder: \(error)")
                }
            }
        }
    }
    
    private func saveServerFile(_ file: OpenFile) {
        guard let serverTitle = file.customTitle, serverTitle.hasPrefix("server") else { return }
        
        let filePath = serverTitle.replacingOccurrences(of: "server", with: "")
        
        let requestBody: [String: Any] = [
            "path": filePath,
            "file_content": file.content
        ]
        
        ServerManager.shared.executeServerCommand(command: "/edit_file", method: "POST", body: requestBody, waitTime: 3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    if let idx = self.openFiles.firstIndex(where: { $0.id == file.id }) {
                        self.openFiles[idx].isDirty = false
                    }
                    self.serverFileContentCache[filePath] = file.content
                    self.saveCacheToUserDefaults()
                    print("Server file saved successfully")
                case .failure(let error):
                    print("Failed to save server file: \(error)")
                }
            }
        }
    }
    
    private func refreshServerFolder() {
        guard let serverPath = serverFolderPath else { return }
        
        let requestBody: [String: Any] = ["path": serverPath]
        
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
                            path: serverPath + "/" + fileName,
                            isFolder: !fileName.contains("."),
                            children: nil
                        )
                    }
                    
                    self.serverFolderCache[serverPath] = children
                    
                    let serverRoot = ServerFileNode(
                        name: serverPath.split(separator: "/").last.map(String.init) ?? "Root",
                        path: serverPath,
                        isFolder: true,
                        children: children
                    )
                    
                    self.serverRootNode = serverRoot
                    self.saveCacheToUserDefaults()
                    
                case .failure(let error):
                    print("Failed to refresh server folder: \(error)")
                }
            }
        }
    }
    
    func createNote(title: String) {
        let note = Note(title: title)
        notes.append(note)
        saveNotes()
    }
    
    func updateNote(_ note: Note, drawingData: Data) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].drawingData = drawingData
            notes[idx].modifiedAt = Date()
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "saved_notes")
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "saved_notes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
    
    func shareServerFile(_ file: OpenFile) {
        #if os(iOS)
        guard file.isServerFile else { return }
        
        let activityVC = UIActivityViewController(activityItems: [file.url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        guard file.isServerFile else { return }
        
        let picker = NSSharingServicePicker(items: [file.url])
        
        if let window = NSApp.keyWindow {
            let rect = NSRect(x: window.frame.midX, y: window.frame.midY, width: 0, height: 0)
            picker.show(relativeTo: rect, of: window.contentView!, preferredEdge: .minY)
        }
        #endif
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
