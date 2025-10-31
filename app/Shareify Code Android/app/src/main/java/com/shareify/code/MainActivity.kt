package com.shareify.code

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import com.google.accompanist.systemuicontroller.rememberSystemUiController
import com.shareify.code.ui.theme.AppColors
import com.shareify.code.ui.theme.AppDimensions
import com.shareify.code.ui.views.EditorView
import com.shareify.code.ui.views.ExplorerView
import com.shareify.code.ui.views.SharAIView
import com.shareify.code.viewmodels.WorkspaceViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        setContent {
            val systemUiController = rememberSystemUiController()
            
            SideEffect {
                systemUiController.setSystemBarsColor(
                    color = android.graphics.Color.TRANSPARENT,
                    darkIcons = false
                )
            }
            
            ShareifyCodeApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShareifyCodeApp() {
    val viewModel = remember { WorkspaceViewModel(androidx.compose.ui.platform.LocalContext.current) }
    var showSharAI by remember { mutableStateOf(false) }
    var aiEnabled by remember { mutableStateOf(true) }
    var isServerConnected by remember { mutableStateOf(false) }
    var isSignedIn by remember { mutableStateOf(false) }
    
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = AppColors.Accent,
            secondary = AppColors.AccentHover,
            background = AppColors.Background,
            surface = AppColors.Surface,
            error = AppColors.Error
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            AppColors.Accent.copy(alpha = 0.06f),
                            AppColors.Background.copy(alpha = 0f)
                        ),
                        center = androidx.compose.ui.geometry.Offset(
                            x = 1500f,
                            y = 0f
                        ),
                        radius = 1200f
                    )
                )
                .background(AppColors.Background)
                .statusBarsPadding()
        ) {
            Row(modifier = Modifier.fillMaxSize()) {
                ExplorerView(
                    viewModel = viewModel,
                    modifier = Modifier.fillMaxHeight()
                )
                
                Box(modifier = Modifier.weight(1f)) {
                    EditorView(
                        viewModel = viewModel,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
            
            Column(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(AppDimensions.SpacingL.dp)
            ) {
                if (!showSharAI) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp)
                    ) {
                        if (isServerConnected) {
                            Surface(
                                shape = CircleShape,
                                color = AppColors.Surface,
                                tonalElevation = 4.dp,
                                modifier = Modifier.padding(end = AppDimensions.SpacingS.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(
                                        horizontal = AppDimensions.SpacingM.dp,
                                        vertical = 6.dp
                                    ),
                                    horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingXS.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(8.dp)
                                            .clip(CircleShape)
                                            .background(AppColors.Success)
                                    )
                                    Text(
                                        "Server",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = AppColors.TextSecondary
                                    )
                                }
                            }
                        }
                        
                        IconButton(
                            onClick = { },
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(AppColors.Surface)
                        ) {
                            Icon(
                                Icons.Default.CreateNewFolder,
                                contentDescription = "Open Folder",
                                tint = AppColors.TextPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                        
                        IconButton(
                            onClick = { },
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(AppColors.Surface)
                        ) {
                            Icon(
                                Icons.Default.Settings,
                                contentDescription = "Settings",
                                tint = AppColors.TextPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                }
            }
            
            if (showSharAI && aiEnabled && isSignedIn) {
                SharAIView(
                    workspaceViewModel = viewModel,
                    isOpen = showSharAI,
                    onClose = { showSharAI = false },
                    modifier = Modifier.align(Alignment.CenterEnd)
                )
            }
            
            if (!showSharAI && aiEnabled && isSignedIn) {
                FloatingActionButton(
                    onClick = { showSharAI = true },
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(24.dp),
                    containerColor = AppColors.Surface,
                    contentColor = AppColors.Accent
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 20.dp),
                        horizontalArrangement = Arrangement.spacedBy(AppDimensions.SpacingS.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.AutoAwesome,
                            contentDescription = "SharAI",
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            "SharAI",
                            style = MaterialTheme.typography.labelLarge
                        )
                    }
                }
            }
        }
    }
}
