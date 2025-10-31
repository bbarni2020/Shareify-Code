# Shareify Code - Android

Android tablet version of Shareify Code, built with Jetpack Compose and Kotlin. It's basically the same thing as the iOS version but for Android tablets.

## What is this?

This is a native code editor for Android tablets. Got tired of not having a decent editor on Android, so here we go. Works offline, connects to remote servers, has AI assistance through Hack Club's API.

## Features

**Code Editor**
- Syntax highlighting (using CodeView library)
- Multiple file tabs
- Unsaved changes warnings
- File tree navigation

**SharAI Assistant**
- Same AI assistant as iOS version
- Context-aware - sees your current file
- Multiple models (Llama 4, GPT-OSS, Kimi K2)
- Action blocks that can edit your code directly
- Chat history persists

**Server Integration**
- Browse files on remote servers
- End-to-end encryption (RSA + AES)
- Auto-reconnect on token expiry
- Works with the Shareify server backend

**UI/UX**
- Dark mode (obviously)
- Material Design 3
- Smooth animations
- Tablet-optimized layouts

## Requirements

- Android SDK 26+ (Android 8.0 Oreo)
- Target SDK 34 (Android 14)
- Gradle 8.1.4
- Kotlin 1.9.20

## Building

Open the project in Android Studio:
```bash
cd "Shareify Code Android"
./gradlew build
```

Or just hit Run in Android Studio. It should work.

## How It Works

### Local Files
Use the folder picker to open a directory. Loads everything into a tree structure (`FileNode`), displays it in the explorer, click to edit.

### Server Mode
Two-step authentication - first to the bridge server, then to your Shareify instance. All communication goes through `ServerManager.kt` with encrypted payloads when possible.

### AI Chat
Lives in `SharAIView.kt`. Sends your message + optionally current file content to Hack Club's AI API. Parses responses for action blocks (EDIT, REWRITE, INSERT, etc.) and shows them as buttons you can tap to apply changes.

## Project Structure

```
app/src/main/
├── java/com/shareify/code/
│   ├── models/              # Data and business logic
│   │   ├── FileNode.kt      # File tree representation
│   │   ├── ServerManager.kt # Remote server API
│   │   ├── AIService.kt     # Hack Club AI integration
│   │   ├── CryptoManager.kt # E2E encryption
│   │   └── AIAction.kt      # Action parser
│   ├── viewmodels/
│   │   └── WorkspaceViewModel.kt  # State management
│   ├── ui/
│   │   ├── theme/
│   │   │   └── Theme.kt     # Colors and dimensions
│   │   └── views/
│   │       ├── ExplorerView.kt    # File tree
│   │       ├── EditorView.kt      # Tabs + editor
│   │       └── SharAIView.kt      # AI chat
│   └── MainActivity.kt      # Entry point
└── res/                     # Resources
```

## Configuration

AI availability is controlled remotely:
```
https://raw.githubusercontent.com/bbarni2020/Shareify-Code/refs/heads/main/info/ai.json
```

Server URLs are in `ServerManager.kt` - yeah I should move them to a config file but whatever.

## Known Issues

- File watcher isn't real-time
- Large files can be slow
- Syntax highlighting doesn't cover every language yet
- No git integration (yet)

## Differences from iOS Version

- Uses Material Design instead of iOS design language
- Built with Jetpack Compose instead of SwiftUI
- Uses OkHttp for networking instead of URLSession
- Android Keystore for encryption instead of Keychain
- Different file picker (Android's storage access framework)

## Tech Stack

- **Jetpack Compose** for UI
- **Material Design 3** for design system
- **OkHttp** for networking
- **CodeView** for syntax highlighting
- **Coroutines** for async operations
- **ViewModel** for state management
- **Android Keystore** for encryption
- **SharedPreferences** for local storage

## License

MIT - do whatever. If you make something cool, let me know.

## Credits

Made by Balogh Barnabás (@bbarni2020)

Uses:
- [Hack Club AI](https://ai.hackclub.com) for AI models
- [CodeView](https://github.com/AmrDeveloper/CodeView) for syntax highlighting
- [OkHttp](https://square.github.io/okhttp/) for HTTP
- [Accompanist](https://google.github.io/accompanist/) for system UI control

## Notes

The encryption is the same as iOS - RSA-2048 for key exchange, AES-256-GCM for data. Client generates keys using Android Keystore, sends public key to server, server encrypts a session key, client decrypts and uses it for the rest of the session.

AI system prompt is in `AISystemPrompt.kt` - edit it to change how SharAI behaves.

If you're running your own Shareify server, it expects the same endpoints as the iOS version. Check `ServerManager.kt` for details.

There's probably bugs. PRs welcome.
