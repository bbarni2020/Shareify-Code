package com.shareify.code.ui.views

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.shareify.code.models.*
import com.shareify.code.ui.theme.AppColors
import com.shareify.code.ui.theme.AppDimensions
import com.shareify.code.viewmodels.WorkspaceViewModel
import kotlinx.coroutines.launch

data class Message(
    val role: String,
    val content: String,
    val actions: List<AIAction> = emptyList()
)

@Composable
fun SharAIView(
    workspaceViewModel: WorkspaceViewModel,
    isOpen: Boolean,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    var messages by remember { mutableStateOf<List<Message>>(emptyList()) }
    var inputText by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var includeContext by remember { mutableStateOf(true) }
    var selectedModel by remember { mutableStateOf("meta-llama/llama-4-maverick") }
    
    val aiService = AIService.getInstance()
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    
    if (!isOpen) return
    
    Box(
        modifier = modifier
            .fillMaxHeight()
            .width(400.dp)
            .padding(end = AppDimensions.SpacingL.dp, top = AppDimensions.SpacingL.dp, bottom = AppDimensions.SpacingL.dp)
            .clip(RoundedCornerShape(AppDimensions.RadiusXL.dp))
            .background(AppColors.Surface)
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(AppDimensions.SpacingL.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.AutoAwesome,
                        contentDescription = null,
                        tint = AppColors.Accent,
                        modifier = Modifier.size(24.dp)
                    )
                    
                    Text(
                        text = "SharAI",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = AppColors.TextPrimary
                    )
                }
                
                IconButton(
                    onClick = onClose,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Close",
                        tint = AppColors.TextSecondary
                    )
                }
            }
            
            Divider(color = AppColors.Border, thickness = 1.dp)
            
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(AppDimensions.SpacingL.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
                ) {
                    Checkbox(
                        checked = includeContext,
                        onCheckedChange = { includeContext = it },
                        colors = CheckboxDefaults.colors(
                            checkedColor = AppColors.Accent,
                            uncheckedColor = AppColors.Border
                        )
                    )
                    
                    Text(
                        text = "Include file",
                        fontSize = 12.sp,
                        color = AppColors.TextSecondary
                    )
                }
            }
            
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = AppDimensions.SpacingL.dp),
                verticalArrangement = Arrangement.spacedBy(AppDimensions.SpacingM.dp)
            ) {
                items(messages) { message ->
                    MessageBubble(
                        message = message,
                        onActionClick = { action ->
                            val result = workspaceViewModel.executeAction(action)
                            result.onSuccess { successMsg ->
                                messages = messages + Message("assistant", successMsg)
                            }.onFailure { error ->
                                messages = messages + Message("assistant", "Error: ${error.message}")
                            }
                        }
                    )
                }
                
                if (isLoading) {
                    item {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(AppDimensions.SpacingM.dp),
                            horizontalArrangement = Arrangement.Start
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = AppColors.Accent,
                                strokeWidth = 2.dp
                            )
                        }
                    }
                }
            }
            
            Divider(color = AppColors.Border, thickness = 1.dp)
            
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(AppDimensions.SpacingL.dp),
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
            ) {
                TextField(
                    value = inputText,
                    onValueChange = { inputText = it },
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = 40.dp, max = 120.dp),
                    placeholder = {
                        Text(
                            "Ask SharAI...",
                            fontSize = 13.sp,
                            color = AppColors.TextTertiary
                        )
                    },
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = AppColors.SurfaceElevated,
                        unfocusedContainerColor = AppColors.SurfaceElevated,
                        focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                        unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                        focusedTextColor = AppColors.TextPrimary,
                        unfocusedTextColor = AppColors.TextPrimary
                    ),
                    shape = RoundedCornerShape(AppDimensions.RadiusM.dp),
                    textStyle = androidx.compose.ui.text.TextStyle(
                        fontSize = 13.sp
                    )
                )
                
                IconButton(
                    onClick = {
                        if (inputText.isNotBlank() && !isLoading) {
                            val userMessage = inputText
                            inputText = ""
                            
                            val contextMessage = if (includeContext) {
                                workspaceViewModel.openFiles
                                    .firstOrNull { it.id == workspaceViewModel.activeFileID }
                                    ?.let { "\n\nCurrent file: ${it.title}\n```\n${it.content}\n```" }
                                    ?: ""
                            } else ""
                            
                            messages = messages + Message("user", userMessage)
                            isLoading = true
                            
                            scope.launch {
                                val chatMessages = messages.map { ChatMessage(it.role, it.content) }
                                val result = aiService.sendMessage(
                                    messages = chatMessages + ChatMessage("user", userMessage + contextMessage),
                                    model = selectedModel
                                )
                                
                                result.onSuccess { response ->
                                    val actions = AIAction.parseActions(response)
                                    messages = messages + Message("assistant", response, actions)
                                    
                                    scope.launch {
                                        listState.animateScrollToItem(messages.size - 1)
                                    }
                                }.onFailure { error ->
                                    messages = messages + Message("assistant", "Error: ${error.message}")
                                }
                                
                                isLoading = false
                            }
                        }
                    },
                    enabled = inputText.isNotBlank() && !isLoading,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(if (inputText.isNotBlank()) AppColors.Accent else AppColors.Border)
                ) {
                    Icon(
                        Icons.Default.Send,
                        contentDescription = "Send",
                        tint = if (inputText.isNotBlank()) androidx.compose.ui.graphics.Color.White else AppColors.TextTertiary
                    )
                }
            }
        }
    }
}

@Composable
fun MessageBubble(
    message: Message,
    onActionClick: (AIAction) -> Unit
) {
    val isUser = message.role == "user"
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = AppDimensions.SpacingS.dp),
        horizontalAlignment = if (isUser) Alignment.End else Alignment.Start
    ) {
        Box(
            modifier = Modifier
                .widthIn(max = 320.dp)
                .clip(RoundedCornerShape(AppDimensions.RadiusM.dp))
                .background(if (isUser) AppColors.Accent else AppColors.SurfaceElevated)
                .padding(AppDimensions.SpacingM.dp)
        ) {
            Text(
                text = message.content,
                fontSize = 13.sp,
                color = if (isUser) androidx.compose.ui.graphics.Color.White else AppColors.TextPrimary,
                lineHeight = 18.sp,
                fontFamily = if (!isUser && message.content.contains("```")) FontFamily.Monospace else FontFamily.Default
            )
        }
        
        if (message.actions.isNotEmpty()) {
            Spacer(modifier = Modifier.height(AppDimensions.SpacingS.dp))
            
            Column(
                verticalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
            ) {
                message.actions.forEach { action ->
                    Button(
                        onClick = { onActionClick(action) },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = AppColors.Success,
                            contentColor = androidx.compose.ui.graphics.Color.White
                        ),
                        modifier = Modifier.height(32.dp),
                        shape = RoundedCornerShape(AppDimensions.RadiusM.dp)
                    ) {
                        Icon(
                            Icons.Default.PlayArrow,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(AppDimensions.SpacingS.dp))
                        Text(
                            "Apply Action",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }
    }
}
