package com.shareify.code.ui.views

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shareify.code.models.FileNode
import com.shareify.code.models.ServerFileNode
import com.shareify.code.ui.theme.AppColors
import com.shareify.code.ui.theme.AppDimensions
import com.shareify.code.viewmodels.WorkspaceViewModel

@Composable
fun ExplorerView(
    viewModel: WorkspaceViewModel,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxHeight()
            .width(280.dp)
            .background(AppColors.Surface)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(AppDimensions.SpacingL.dp)
                .padding(top = AppDimensions.SpacingS.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "EXPLORER",
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.TextSecondary,
                letterSpacing = 0.5.sp
            )
            
            Row(horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingXS.dp)) {
                IconButton(
                    onClick = { },
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        Icons.Default.CreateNewFolder,
                        contentDescription = "New Folder",
                        tint = AppColors.TextSecondary,
                        modifier = Modifier.size(18.dp)
                    )
                }
                
                IconButton(
                    onClick = { },
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        Icons.Default.NoteAdd,
                        contentDescription = "New File",
                        tint = AppColors.TextSecondary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
        
        Divider(color = AppColors.Border, thickness = 1.dp)
        
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = AppDimensions.SpacingS.dp)
        ) {
            if (viewModel.isServerFolder) {
                viewModel.serverRootNode?.let { root ->
                    item {
                        ServerFileTreeItem(
                            node = root,
                            level = 0,
                            expanded = viewModel.expandedServerPaths,
                            onToggle = { },
                            onClick = { },
                            viewModel = viewModel
                        )
                    }
                }
            } else {
                viewModel.rootNode?.let { root ->
                    item {
                        FileTreeItem(
                            node = root,
                            level = 0,
                            expanded = viewModel.expanded,
                            onToggle = { viewModel.toggleExpanded(it) },
                            onClick = { viewModel.openFile(it.url) },
                            selectedNode = viewModel.selectedNode
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun FileTreeItem(
    node: FileNode,
    level: Int,
    expanded: Set<String>,
    onToggle: (FileNode) -> Unit,
    onClick: (FileNode) -> Unit,
    selectedNode: FileNode?
) {
    val isExpanded = expanded.contains(node.id)
    val indentSize = (level * 16).dp
    
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    if (node.isDirectory) {
                        onToggle(node)
                    } else {
                        onClick(node)
                    }
                }
                .background(
                    if (selectedNode?.id == node.id) AppColors.SurfaceElevated
                    else androidx.compose.ui.graphics.Color.Transparent
                )
                .padding(
                    start = indentSize + AppDimensions.SpacingM.dp,
                    end = AppDimensions.SpacingM.dp,
                    top = 6.dp,
                    bottom = 6.dp
                ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
        ) {
            if (node.isDirectory) {
                Icon(
                    if (isExpanded) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowRight,
                    contentDescription = null,
                    tint = AppColors.TextSecondary,
                    modifier = Modifier.size(16.dp)
                )
                
                Icon(
                    if (isExpanded) Icons.Default.FolderOpen else Icons.Default.Folder,
                    contentDescription = null,
                    tint = AppColors.TextSecondary,
                    modifier = Modifier.size(16.dp)
                )
            } else {
                Spacer(modifier = Modifier.width(16.dp))
                Icon(
                    Icons.Default.InsertDriveFile,
                    contentDescription = null,
                    tint = AppColors.TextTertiary,
                    modifier = Modifier.size(14.dp)
                )
            }
            
            Text(
                text = node.name,
                fontSize = 13.sp,
                color = if (selectedNode?.id == node.id) AppColors.TextPrimary else AppColors.TextSecondary,
                fontWeight = if (selectedNode?.id == node.id) FontWeight.Medium else FontWeight.Normal,
                maxLines = 1
            )
        }
        
        if (node.isDirectory && isExpanded) {
            node.children?.forEach { child ->
                FileTreeItem(
                    node = child,
                    level = level + 1,
                    expanded = expanded,
                    onToggle = onToggle,
                    onClick = onClick,
                    selectedNode = selectedNode
                )
            }
        }
    }
}

@Composable
fun ServerFileTreeItem(
    node: ServerFileNode,
    level: Int,
    expanded: Set<String>,
    onToggle: (ServerFileNode) -> Unit,
    onClick: (ServerFileNode) -> Unit,
    viewModel: WorkspaceViewModel
) {
    val isExpanded = expanded.contains(node.path)
    val indentSize = (level * 16).dp
    
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    if (node.isFolder) {
                        onToggle(node)
                    } else {
                        onClick(node)
                    }
                }
                .padding(
                    start = indentSize + AppDimensions.SpacingM.dp,
                    end = AppDimensions.SpacingM.dp,
                    top = 6.dp,
                    bottom = 6.dp
                ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
        ) {
            if (node.isFolder) {
                Icon(
                    if (isExpanded) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowRight,
                    contentDescription = null,
                    tint = AppColors.TextSecondary,
                    modifier = Modifier.size(16.dp)
                )
                
                Icon(
                    if (isExpanded) Icons.Default.FolderOpen else Icons.Default.Folder,
                    contentDescription = null,
                    tint = AppColors.TextSecondary,
                    modifier = Modifier.size(16.dp)
                )
            } else {
                Spacer(modifier = Modifier.width(16.dp))
                Icon(
                    Icons.Default.InsertDriveFile,
                    contentDescription = null,
                    tint = AppColors.TextTertiary,
                    modifier = Modifier.size(14.dp)
                )
            }
            
            Text(
                text = node.name,
                fontSize = 13.sp,
                color = AppColors.TextSecondary,
                maxLines = 1
            )
        }
        
        if (node.isFolder && isExpanded) {
            node.children?.forEach { child ->
                ServerFileTreeItem(
                    node = child,
                    level = level + 1,
                    expanded = expanded,
                    onToggle = onToggle,
                    onClick = onClick,
                    viewModel = viewModel
                )
            }
        }
    }
}
