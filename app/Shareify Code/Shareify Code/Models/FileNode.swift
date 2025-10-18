//
//  FileNode.swift
//  Shareify Code
//

import Foundation

struct FileNode: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?

    var name: String { url.lastPathComponent }

    init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.url = url
        self.isDirectory = isDirectory
        self.children = children
    }

    static func makeRoot(from url: URL, showHidden: Bool = false) -> FileNode {
        var node = FileNode(url: url, isDirectory: true)
        node.children = loadChildren(of: url, showHidden: showHidden)
        return node
    }

    static func loadChildren(of url: URL, showHidden: Bool = false) -> [FileNode] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(at: url,
                                                     includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isHiddenKey],
                                                     options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants]) else { return [] }

        let filtered = urls.compactMap { child -> FileNode? in
            if !showHidden, child.lastPathComponent.hasPrefix(".") { return nil }
            if child.lastPathComponent == ".DS_Store" { return nil }
            let isDir = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return FileNode(url: child, isDirectory: isDir)
        }

        return filtered.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory && !b.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
