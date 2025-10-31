package com.shareify.code.ui.views

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shareify.code.ui.theme.AppColors
import com.shareify.code.ui.theme.AppDimensions
import com.shareify.code.viewmodels.WorkspaceViewModel

@Composable
fun EditorView(
    viewModel: WorkspaceViewModel,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        if (viewModel.openFiles.isNotEmpty()) {
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.Surface)
                    .padding(horizontal = AppDimensions.SpacingM.dp, vertical = AppDimensions.SpacingS.dp),
                horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingXS.dp)
            ) {
                items(viewModel.openFiles, key = { it.id }) { file ->
                    FileTab(
                        file = file,
                        isActive = viewModel.activeFileID == file.id,
                        onClick = { viewModel.activeFileID = file.id },
                        onClose = { viewModel.closeFile(file.id) }
                    )
                }
            }
            
            Divider(color = AppColors.Border, thickness = 1.dp)
            
            viewModel.openFiles.firstOrNull { it.id == viewModel.activeFileID }?.let { activeFile ->
                CodeEditorView(
                    file = activeFile,
                    onContentChange = { viewModel.updateActiveContent(it) },
                    modifier = Modifier.fillMaxSize()
                )
            }
        } else {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(AppDimensions.SpacingM.dp)
                ) {
                    Icon(
                        Icons.Default.InsertDriveFile,
                        contentDescription = null,
                        tint = AppColors.TextTertiary,
                        modifier = Modifier.size(64.dp)
                    )
                    
                    Text(
                        text = "No files open",
                        fontSize = 16.sp,
                        color = AppColors.TextSecondary,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Text(
                        text = "Select a file from the explorer to start editing",
                        fontSize = 13.sp,
                        color = AppColors.TextTertiary
                    )
                }
            }
        }
    }
}

@Composable
fun FileTab(
    file: com.shareify.code.models.OpenFile,
    isActive: Boolean,
    onClick: () -> Unit,
    onClose: () -> Unit
) {
    Row(
        modifier = Modifier
            .height(32.dp)
            .clip(RoundedCornerShape(AppDimensions.RadiusS.dp))
            .background(
                if (isActive) AppColors.SurfaceElevated else AppColors.Surface
            )
            .clickable(onClick = onClick)
            .padding(horizontal = AppDimensions.SpacingM.dp, vertical = AppDimensions.SpacingS.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
    ) {
        if (file.isDirty) {
            Icon(
                Icons.Default.Circle,
                contentDescription = "Unsaved",
                tint = AppColors.Warning,
                modifier = Modifier.size(8.dp)
            )
        }
        
        Text(
            text = file.title,
            fontSize = 12.sp,
            color = if (isActive) AppColors.TextPrimary else AppColors.TextSecondary,
            fontWeight = if (isActive) FontWeight.Medium else FontWeight.Normal,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.widthIn(max = 150.dp)
        )
        
        IconButton(
            onClick = onClose,
            modifier = Modifier.size(18.dp)
        ) {
            Icon(
                Icons.Default.Close,
                contentDescription = "Close",
                tint = AppColors.TextTertiary,
                modifier = Modifier.size(14.dp)
            )
        }
    }
}

@Composable
fun CodeEditorView(
    file: com.shareify.code.models.OpenFile,
    onContentChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var text by remember(file.id) { mutableStateOf(file.content) }
    
    LaunchedEffect(file.id) {
        text = file.content
    }
    
    LaunchedEffect(text) {
        if (text != file.content) {
            onContentChange(text)
        }
    }
    
    Box(
        modifier = modifier
            .background(AppColors.Background)
    ) {
        TextField(
            value = text,
            onValueChange = { text = it },
            modifier = Modifier
                .fillMaxSize()
                .padding(AppDimensions.SpacingL.dp),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = AppColors.Background,
                unfocusedContainerColor = AppColors.Background,
                disabledContainerColor = AppColors.Background,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
                focusedTextColor = AppColors.TextPrimary,
                unfocusedTextColor = AppColors.TextPrimary
            ),
            textStyle = androidx.compose.ui.text.TextStyle(
                fontFamily = FontFamily.Monospace,
                fontSize = 14.sp,
                lineHeight = 20.sp,
                color = AppColors.TextPrimary
            )
        )
    }
}
