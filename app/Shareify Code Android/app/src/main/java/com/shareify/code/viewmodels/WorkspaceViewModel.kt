package com.shareify.code.viewmodels

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shareify.code.models.*
import kotlinx.coroutines.launch
import java.io.File

class WorkspaceViewModel(private val context: Context) : ViewModel() {
    var rootURL by mutableStateOf<File?>(null)
        private set
    
    var rootNode by mutableStateOf<FileNode?>(null)
        private set
    
    var expanded by mutableStateOf<Set<String>>(emptySet())
        private set
    
    var showHiddenFiles by mutableStateOf(false)
        private set
    
    var selectedNode by mutableStateOf<FileNode?>(null)
        private set
    
    var isServerFolder by mutableStateOf(false)
        private set
    
    var serverFolderPath by mutableStateOf<String?>(null)
        private set
    
    var serverRootNode by mutableStateOf<ServerFileNode?>(null)
        private set
    
    var expandedServerPaths by mutableStateOf<Set<String>>(emptySet())
        private set
    
    var isLoadingServerFolder by mutableStateOf(false)
        private set
    
    var openFiles by mutableStateOf<List<OpenFile>>(emptyList())
        private set
    
    var activeFileID by mutableStateOf<String?>(null)
        private set
    
    var fileToClose by mutableStateOf<String?>(null)
        private set
    
    var showUnsavedWarning by mutableStateOf(false)
        private set
    
    private val serverFolderCache = mutableMapOf<String, List<ServerFileNode>>()
    private val serverFileContentCache = mutableMapOf<String, String>()
    private val serverManager = ServerManager.getInstance(context)
    private val prefs = context.getSharedPreferences("workspace_prefs", Context.MODE_PRIVATE)
    
    init {
        loadCacheFromPrefs()
    }
    
    fun collapseAll() {
        expanded = rootURL?.path?.let { setOf(it) } ?: emptySet()
    }
    
    fun expandAll() {
        val root = rootNode ?: return
        val directories = mutableSetOf<String>()
        collectDirectories(root, directories)
        expanded = directories
    }
    
    private fun collectDirectories(node: FileNode, set: MutableSet<String>) {
        if (node.isDirectory) set.add(node.id)
        val children = node.children ?: FileNode.loadChildren(node.url, showHiddenFiles)
        children.forEach { child ->
            if (child.isDirectory) {
                collectDirectories(child, set)
            }
        }
    }
    
    fun loadRoot(url: File) {
        rootURL = null
        rootNode = null
        expanded = emptySet()
        isServerFolder = false
        serverFolderPath = null
        serverRootNode = null
        expandedServerPaths = emptySet()
        
        saveOpenFilesCache()
        openFiles = emptyList()
        activeFileID = null
        
        rootURL = url
        rootNode = FileNode.makeRoot(url, showHiddenFiles)
        expanded = setOf(url.path)
        
        prefs.edit().putString("lastLocalFolderPath", url.path).apply()
    }
    
    fun refreshNode(node: FileNode) {
        if (!node.isDirectory) return
        rootURL?.let { url ->
            rootNode = FileNode.makeRoot(url, showHiddenFiles)
        }
    }
    
    fun createFile(name: String, parentNode: FileNode?) {
        if (name.isEmpty()) return
        
        if (isServerFolder) {
            createServerFile(name, parentNode)
            return
        }
        
        val parent = parentNode ?: rootNode?.let { FileNode(url = rootURL!!, isDirectory = true) } ?: return
        if (!parent.isDirectory) return
        
        val fileURL = File(parent.url, name)
        if (fileURL.createNewFile()) {
            expanded = expanded + parent.id
            refreshNode(parent)
        }
    }
    
    fun createFolder(name: String, parentNode: FileNode?) {
        if (name.isEmpty()) return
        
        if (isServerFolder) {
            createServerFolder(name, parentNode)
            return
        }
        
        val parent = parentNode ?: rootNode?.let { FileNode(url = rootURL!!, isDirectory = true) } ?: return
        if (!parent.isDirectory) return
        
        val folderURL = File(parent.url, name)
        if (folderURL.mkdirs()) {
            expanded = expanded + parent.id
            refreshNode(parent)
        }
    }
    
    fun deleteFile(node: FileNode) {
        if (isServerFolder) {
            deleteServerFile(node)
            return
        }
        
        if (node.url.deleteRecursively()) {
            openFiles = openFiles.filterNot { it.url == node.url }
            if (activeFileID == node.url.path) {
                activeFileID = openFiles.lastOrNull()?.id
            }
            rootURL?.let { url ->
                rootNode = FileNode.makeRoot(url, showHiddenFiles)
            }
        }
    }
    
    fun deleteServerFileNode(node: ServerFileNode) {
        if (!isServerFolder) return
        
        val command = if (node.isFolder) "/api/delete_folder" else "/api/delete_file"
        val requestBody = mapOf("path" to node.path)
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand(command, "POST", requestBody, 3)
            result.onSuccess {
                val tempURL = File(context.cacheDir, "server_${node.path.replace("/", "_")}")
                
                openFiles = openFiles.filterNot { it.url.path == tempURL.path }
                if (activeFileID == tempURL.path) {
                    activeFileID = openFiles.lastOrNull()?.id
                }
                
                serverFileContentCache.remove(node.path)
                serverFolderPath?.let { path ->
                    serverFolderCache.remove(path)
                    refreshServerFolder()
                }
            }
        }
    }
    
    private fun deleteServerFile(node: FileNode) {
        val customTitle = openFiles.firstOrNull { it.url.path.contains(node.url.name) }?.customTitle ?: return
        val filePath = customTitle.replace("server", "")
        
        val requestBody = mapOf("path" to filePath)
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand("/api/delete_file", "POST", requestBody, 3)
            result.onSuccess {
                openFiles = openFiles.filterNot { it.url == node.url }
                if (activeFileID == node.url.path) {
                    activeFileID = openFiles.lastOrNull()?.id
                }
                
                serverFileContentCache.remove(filePath)
                serverFolderPath?.let { path ->
                    serverFolderCache.remove(path)
                    refreshServerFolder()
                }
            }
        }
    }
    
    fun toggleExpanded(node: FileNode) {
        if (!node.isDirectory) return
        expanded = if (node.id in expanded) {
            expanded - node.id
        } else {
            expanded + node.id
            rootURL?.let { url ->
                rootNode = FileNode.makeRoot(url, showHiddenFiles)
            }
            expanded + node.id
        }
    }
    
    fun openFile(url: File) {
        if (openFiles.any { it.url == url }) {
            activeFileID = openFiles.first { it.url == url }.id
            return
        }
        
        val ext = url.extension.lowercase()
        val binaryExtensions = listOf("png", "jpg", "jpeg", "gif", "bmp", "webp", "ico", "heic",
            "mp4", "mov", "avi", "mkv", "m4v", "webm",
            "mp3", "wav", "m4a", "aac", "flac", "ogg", "pdf")
        
        if (ext in binaryExtensions) {
            val binaryData = url.readBytes()
            val file = OpenFile(url = url, content = "", binaryData = binaryData)
            openFiles = openFiles + file
            activeFileID = file.id
        } else {
            val content = url.readText()
            val file = OpenFile(url = url, content = content)
            openFiles = openFiles + file
            activeFileID = file.id
        }
    }
    
    fun closeFile(id: String) {
        val file = openFiles.firstOrNull { it.id == id } ?: return
        if (file.isDirty) {
            fileToClose = id
            showUnsavedWarning = true
        } else {
            performCloseFile(id)
        }
    }
    
    fun performCloseFile(id: String) {
        openFiles = openFiles.filterNot { it.id == id }
        if (activeFileID == id) {
            activeFileID = openFiles.lastOrNull()?.id
        }
        fileToClose = null
        showUnsavedWarning = false
    }
    
    fun saveAndCloseFile(id: String) {
        val file = openFiles.firstOrNull { it.id == id } ?: return
        try {
            file.url.writeText(file.content)
            openFiles = openFiles.map {
                if (it.id == id) it.copy(isDirty = false) else it
            }
            performCloseFile(id)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    fun cancelClose() {
        fileToClose = null
        showUnsavedWarning = false
    }
    
    fun updateActiveContent(text: String) {
        val id = activeFileID ?: return
        openFiles = openFiles.map {
            if (it.id == id) it.copy(content = text, isDirty = true) else it
        }
    }
    
    fun saveActive() {
        val id = activeFileID ?: return
        val file = openFiles.firstOrNull { it.id == id } ?: return
        
        if (file.customTitle?.startsWith("server") == true) {
            saveServerFile(file)
            return
        }
        
        try {
            file.url.writeText(file.content)
            openFiles = openFiles.map {
                if (it.id == id) it.copy(isDirty = false) else it
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    fun executeAction(action: AIAction): Result<String> {
        return when (val type = action.type) {
            is AIAction.ActionType.Edit -> executeEditAction(type.old, type.new)
            is AIAction.ActionType.Rewrite -> executeRewriteAction(type.file, type.content)
            is AIAction.ActionType.Insert -> executeInsertAction(type.after, type.content)
            is AIAction.ActionType.Terminal -> Result.success("Terminal command ready: ${type.command}\nReason: ${type.reason}")
            is AIAction.ActionType.Search -> Result.success("Search pattern: ${type.pattern}\nReason: ${type.reason}")
        }
    }
    
    private fun executeEditAction(old: String, new: String): Result<String> {
        val id = activeFileID ?: return Result.failure(Exception("No active file"))
        val file = openFiles.firstOrNull { it.id == id } ?: return Result.failure(Exception("No active file"))
        
        if (!file.content.contains(old)) {
            return Result.failure(Exception("Could not find the code to replace"))
        }
        
        val newContent = file.content.replace(old, new)
        openFiles = openFiles.map {
            if (it.id == id) it.copy(content = newContent, isDirty = true) else it
        }
        
        return Result.success("Code successfully updated in ${file.title}")
    }
    
    private fun executeRewriteAction(fileName: String, content: String): Result<String> {
        val id = activeFileID ?: return Result.failure(Exception("No active file"))
        val file = openFiles.firstOrNull { it.id == id } ?: return Result.failure(Exception("No active file"))
        
        if (file.title != fileName) {
            return Result.failure(Exception("File name mismatch"))
        }
        
        openFiles = openFiles.map {
            if (it.id == id) it.copy(content = content, isDirty = true) else it
        }
        
        return Result.success("File $fileName completely rewritten")
    }
    
    private fun executeInsertAction(after: String, content: String): Result<String> {
        val id = activeFileID ?: return Result.failure(Exception("No active file"))
        val file = openFiles.firstOrNull { it.id == id } ?: return Result.failure(Exception("No active file"))
        
        val index = file.content.indexOf(after)
        if (index == -1) {
            return Result.failure(Exception("Could not find the anchor point"))
        }
        
        val insertIndex = index + after.length
        val newContent = file.content.substring(0, insertIndex) + "\n$content" + file.content.substring(insertIndex)
        
        openFiles = openFiles.map {
            if (it.id == id) it.copy(content = newContent, isDirty = true) else it
        }
        
        return Result.success("Code successfully inserted in ${file.title}")
    }
    
    fun loadServerFolder(path: String, files: List<ServerFileNode>) {
        rootURL = null
        rootNode = null
        expanded = emptySet()
        isServerFolder = false
        serverFolderPath = null
        serverRootNode = null
        expandedServerPaths = emptySet()
        
        saveOpenFilesCache()
        openFiles = emptyList()
        activeFileID = null
        
        isServerFolder = true
        serverFolderPath = path
        
        val serverRoot = ServerFileNode(
            name = path.split("/").lastOrNull() ?: "Root",
            path = path,
            isFolder = true,
            children = files
        )
        
        serverRootNode = serverRoot
        serverFolderCache[path] = files
        expandedServerPaths = setOf(path)
        isLoadingServerFolder = false
        
        prefs.edit().putString("lastServerFolderPath", path).apply()
        saveCacheToPrefs()
    }
    
    fun setServerFolderLoading(path: String) {
        rootURL = null
        rootNode = null
        expanded = emptySet()
        isServerFolder = true
        serverFolderPath = path
        serverRootNode = null
        expandedServerPaths = emptySet()
        isLoadingServerFolder = true
        
        saveOpenFilesCache()
        openFiles = emptyList()
        activeFileID = null
    }
    
    fun clearServerFolderLoading() {
        isLoadingServerFolder = false
        isServerFolder = false
        serverFolderPath = null
    }
    
    fun loadServerChildren(node: ServerFileNode, completion: (List<ServerFileNode>) -> Unit) {
        serverFolderCache[node.path]?.let {
            completion(it)
            return
        }
        
        val requestBody = mapOf("path" to node.path)
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand("/finder", "GET", requestBody, 3)
            result.onSuccess { response ->
                val fileNames = when (response) {
                    is Map<*, *> -> (response["items"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                    is List<*> -> response.mapNotNull { it as? String }
                    else -> emptyList()
                }
                
                val children = fileNames.map { fileName ->
                    ServerFileNode(
                        name = fileName,
                        path = "${node.path}/$fileName",
                        isFolder = !fileName.contains("."),
                        children = null
                    )
                }
                
                serverFolderCache[node.path] = children
                saveCacheToPrefs()
                completion(children)
            }.onFailure {
                serverFolderCache[node.path]?.let { completion(it) } ?: completion(emptyList())
            }
        }
    }
    
    fun openServerFile(file: ServerFileNode) {
        val tempURL = File(context.cacheDir, "server_${file.path.replace("/", "_")}")
        val serverTitle = "server${file.path}"
        
        if (openFiles.any { it.id == tempURL.path }) {
            activeFileID = tempURL.path
            return
        }
        
        serverFileContentCache[file.path]?.let { cachedContent ->
            val openFile = OpenFile(
                url = tempURL,
                customTitle = serverTitle,
                content = cachedContent,
                isDirty = false,
                isLoading = false,
                isServerFile = true
            )
            openFiles = openFiles + openFile
            activeFileID = openFile.id
            return
        }
        
        val loadingFile = OpenFile(
            url = tempURL,
            customTitle = serverTitle,
            content = "Loading...",
            isDirty = false,
            isLoading = true,
            isServerFile = true
        )
        openFiles = openFiles + loadingFile
        activeFileID = loadingFile.id
        
        val command = "/get_file?file_path=${file.path}"
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand(command, "GET", emptyMap(), 5)
            result.onSuccess { response ->
                if (response is Map<*, *>) {
                    val status = response["status"] as? String
                    val content = response["content"] as? String
                    val type = response["type"] as? String
                    
                    if (status == "File content retrieved" && content != null && type == "text") {
                        serverFileContentCache[file.path] = content
                        saveCacheToPrefs()
                        
                        openFiles = openFiles.map {
                            if (it.id == tempURL.path) {
                                tempURL.writeText(content)
                                it.copy(content = content, isLoading = false)
                            } else it
                        }
                    } else {
                        openFiles = openFiles.filterNot { it.id == tempURL.path }
                        if (activeFileID == tempURL.path) {
                            activeFileID = openFiles.lastOrNull()?.id
                        }
                    }
                }
            }.onFailure {
                serverFileContentCache[file.path]?.let { cachedContent ->
                    openFiles = openFiles.map {
                        if (it.id == tempURL.path) {
                            tempURL.writeText(cachedContent)
                            it.copy(content = cachedContent, isLoading = false)
                        } else it
                    }
                } ?: run {
                    openFiles = openFiles.filterNot { it.id == tempURL.path }
                    if (activeFileID == tempURL.path) {
                        activeFileID = openFiles.lastOrNull()?.id
                    }
                }
            }
        }
    }
    
    private fun saveCacheToPrefs() {
    }
    
    private fun saveOpenFilesCache() {
        val openFilePaths = openFiles.map { it.url.path }
        prefs.edit()
            .putStringSet("openFilePaths", openFilePaths.toSet())
            .putString("activeFileID", activeFileID)
            .putBoolean("wasServerFolder", isServerFolder)
            .apply()
    }
    
    private fun loadCacheFromPrefs() {
        val wasServerFolder = prefs.getBoolean("wasServerFolder", false)
        
        if (wasServerFolder) {
            val lastServerPath = prefs.getString("lastServerFolderPath", null)
            if (lastServerPath != null) {
                isServerFolder = true
                serverFolderPath = lastServerPath
            }
        } else {
            val lastLocalPath = prefs.getString("lastLocalFolderPath", null)
            if (lastLocalPath != null) {
                val url = File(lastLocalPath)
                if (url.exists()) {
                    rootURL = url
                    rootNode = FileNode.makeRoot(url, showHiddenFiles)
                    expanded = setOf(url.path)
                }
            }
        }
    }
    
    private fun createServerFile(name: String, parentNode: FileNode?) {
        val serverPath = serverFolderPath ?: return
        val path = if (serverPath.endsWith("/")) serverPath else "$serverPath/"
        
        val requestBody = mapOf(
            "file_name" to name,
            "path" to path,
            "file_content" to ""
        )
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand("/new_file", "POST", requestBody, 3)
            result.onSuccess {
                serverFolderCache.remove(serverPath)
                refreshServerFolder()
            }
        }
    }
    
    private fun createServerFolder(name: String, parentNode: FileNode?) {
        val serverPath = serverFolderPath ?: return
        val path = if (serverPath.endsWith("/")) serverPath else "$serverPath/"
        
        val requestBody = mapOf(
            "folder_name" to name,
            "path" to path
        )
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand("/create_folder", "POST", requestBody, 3)
            result.onSuccess {
                serverFolderCache.remove(serverPath)
                refreshServerFolder()
            }
        }
    }
    
    private fun saveServerFile(file: OpenFile) {
        val serverTitle = file.customTitle ?: return
        if (!serverTitle.startsWith("server")) return
        
        val filePath = serverTitle.replace("server", "")
        
        val requestBody = mapOf(
            "path" to filePath,
            "file_content" to file.content
        )
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand("/edit_file", "POST", requestBody, 3)
            result.onSuccess {
                openFiles = openFiles.map {
                    if (it.id == file.id) it.copy(isDirty = false) else it
                }
                serverFileContentCache[filePath] = file.content
                saveCacheToPrefs()
            }
        }
    }
    
    private fun refreshServerFolder() {
        val serverPath = serverFolderPath ?: return
        val requestBody = mapOf("path" to serverPath)
        
        viewModelScope.launch {
            val result = serverManager.executeServerCommand("/finder", "GET", requestBody, 3)
            result.onSuccess { response ->
                val fileNames = when (response) {
                    is Map<*, *> -> (response["items"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                    is List<*> -> response.mapNotNull { it as? String }
                    else -> emptyList()
                }
                
                val children = fileNames.map { fileName ->
                    ServerFileNode(
                        name = fileName,
                        path = "$serverPath/$fileName",
                        isFolder = !fileName.contains("."),
                        children = null
                    )
                }
                
                serverFolderCache[serverPath] = children
                
                val serverRoot = ServerFileNode(
                    name = serverPath.split("/").lastOrNull() ?: "Root",
                    path = serverPath,
                    isFolder = true,
                    children = children
                )
                
                serverRootNode = serverRoot
                saveCacheToPrefs()
            }
        }
    }
}
