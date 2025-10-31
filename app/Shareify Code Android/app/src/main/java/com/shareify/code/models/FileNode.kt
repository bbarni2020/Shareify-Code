package com.shareify.code.models

import java.io.File
import java.util.UUID

data class FileNode(
    val id: String = UUID.randomUUID().toString(),
    val url: File,
    val name: String = url.name,
    val isDirectory: Boolean = url.isDirectory,
    var children: List<FileNode>? = null
) {
    companion object {
        fun makeRoot(from: File, showHidden: Boolean = false): FileNode {
            val root = FileNode(url = from)
            root.children = loadChildren(from, showHidden)
            return root
        }

        fun loadChildren(of: File, showHidden: Boolean = false): List<FileNode> {
            if (!of.isDirectory) return emptyList()
            
            val files = of.listFiles()?.filter { file ->
                showHidden || !file.name.startsWith(".")
            } ?: emptyList()
            
            return files.sortedWith(compareBy<File> { !it.isDirectory }.thenBy { it.name })
                .map { file ->
                    val node = FileNode(url = file)
                    if (file.isDirectory) {
                        node.children = loadChildren(file, showHidden)
                    }
                    node
                }
        }
    }
}

data class ServerFileNode(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val path: String,
    val isFolder: Boolean,
    var children: List<ServerFileNode>? = null
)

data class OpenFile(
    val url: File,
    var customTitle: String? = null,
    var content: String,
    var isDirty: Boolean = false,
    var isLoading: Boolean = false,
    var cursorLine: Int = 1,
    var cursorColumn: Int = 1,
    var binaryData: ByteArray? = null,
    var isServerFile: Boolean = false
) {
    val id: String get() = url.path
    val title: String get() = customTitle ?: url.name
    
    val fileType: FileType
        get() {
            val ext = url.extension.lowercase()
            return when {
                ext in listOf("png", "jpg", "jpeg", "gif", "svg", "bmp", "webp", "ico", "heic") -> FileType.IMAGE
                ext in listOf("mp4", "mov", "avi", "mkv", "m4v", "webm") -> FileType.VIDEO
                ext in listOf("mp3", "wav", "m4a", "aac", "flac", "ogg") -> FileType.AUDIO
                ext == "pdf" -> FileType.PDF
                else -> FileType.TEXT
            }
        }
    
    enum class FileType {
        TEXT, IMAGE, VIDEO, AUDIO, PDF
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as OpenFile

        if (url != other.url) return false
        if (customTitle != other.customTitle) return false
        if (content != other.content) return false
        if (isDirty != other.isDirty) return false
        if (isLoading != other.isLoading) return false
        if (binaryData != null) {
            if (other.binaryData == null) return false
            if (!binaryData.contentEquals(other.binaryData)) return false
        } else if (other.binaryData != null) return false
        if (isServerFile != other.isServerFile) return false

        return true
    }

    override fun hashCode(): Int {
        var result = url.hashCode()
        result = 31 * result + (customTitle?.hashCode() ?: 0)
        result = 31 * result + content.hashCode()
        result = 31 * result + isDirty.hashCode()
        result = 31 * result + isLoading.hashCode()
        result = 31 * result + (binaryData?.contentHashCode() ?: 0)
        result = 31 * result + isServerFile.hashCode()
        return result
    }
}
