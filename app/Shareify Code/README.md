# Shareify Code

A native iPadOS code editor with AI assistance and remote server support. Built this because I wanted to code on my iPad without constantly switching apps or dealing with web-based editors.

## What's This?

It's a SwiftUI-based code editor that lets you:
- Edit code with proper syntax highlighting (thanks to Highlightr)
- Connect to a remote server to access your files anywhere
- Chat with an AI assistant (SharAI) that actually understands your code
- Work with a file tree just like VS Code
- End-to-end encrypted server connections (because security matters)

The AI part is kinda cool - it can suggest edits, write new code, or even refactor entire files. It's powered by multiple models (Llama 4, GPT-OSS, Kimi K2) through Hack Club's AI API.

## Features

**Code Editor**
- Syntax highlighting for common languages (Swift, Python, JS, etc.)
- Multiple file tabs
- Unsaved changes warnings (learned this the hard way)
- Line numbers and code folding

**SharAI Assistant**
- Context-aware code help - it can see your current file
- Multiple AI models to choose from
- Action blocks that let it directly edit your code
- Persistent chat history (saves in UserDefaults)

**Server Integration**
- Browse and edit files on your remote server
- E2E encryption using RSA + AES session keys
- Auto-reconnect when tokens expire
- Works with the Shareify server backend (separate repo)

**UI/UX**
- Dark mode only (fight me)
- Glass morphism effects where it makes sense
- Smooth animations with spring physics
- Custom theme system

## Installation

You'll need:
- Xcode 15+
- macOS 14+ or iOS 17+
- A Hack Club AI API access (free at ai.hackclub.com)

Clone and build:
```bash
git clone https://github.com/bbarni2020/shareify-code.git
cd shareify-code/app/Shareify\ Code
open Shareify\ Code.xcodeproj
```

Hit Cmd+R and you're good.

## How It Works

### Local Files
Open a folder using Cmd+O. It recursively loads all files into a tree structure (`FileNode` model) and you can click around like a normal editor.

### Server Mode
You need to login to the bridge server first (currently at `bridge.bbarni.hackclub.app`), which gives you a JWT token. Then you can authenticate to your Shareify server instance, which gives you another JWT. Yeah, it's two-step auth but it keeps things secure.

The server communication goes through `ServerManager.swift` - every command is an HTTP POST with encrypted payloads when possible.

### AI Chat
SharAI lives in `SharAIView.swift`. When you ask it something:
1. Optionally includes your current file's content as context
2. Sends everything to the AI API with the system prompt from `model.md`
3. Parses the response for special action blocks (EDIT, REWRITE, INSERT, etc.)
4. Shows those as interactive buttons you can click to apply

The action parsing is in `AIAction.swift` - it looks for XML-style tags in the AI's response.

## Project Structure

```
Shareify Code/
├── Models/          # Data structures and business logic
│   ├── FileNode.swift         # File tree representation
│   ├── ServerManager.swift    # Remote server API
│   ├── AIService.swift        # Hack Club AI integration
│   ├── CryptoManager.swift    # E2E encryption stuff
│   └── AIAction.swift         # Action parser for AI responses
├── ViewModels/
│   └── WorkspaceViewModel.swift  # Main state management
├── Views/
│   ├── ContentView.swift      # Root view with layout
│   ├── ExplorerView.swift     # File tree sidebar
│   ├── EditorView.swift       # Tabbed editor interface
│   ├── CodeEditorView.swift   # Actual text editing
│   ├── SharAIView.swift       # AI chat panel
│   ├── ServerBrowserView.swift
│   └── SettingsView.swift
└── Utils/
    ├── SyntaxHighlighter.swift
    ├── Theme.swift            # Colors and spacing
    └── PlatformColors.swift   # iOS/macOS compatibility
```

## Configuration

The AI availability is controlled by a remote JSON file:
```
https://raw.githubusercontent.com/bbarni2020/Shareify-Code/refs/heads/main/info/ai.json
```

It checks this on launch to enable/disable the SharAI features. Useful for killswitching if something breaks.

Server URLs are hardcoded in `ServerManager.swift` (I know, I know - should be in a config file).

## Known Issues

- Theme switching isn't implemented (dark mode only for now)
- File watching isn't real-time - you need to refresh manually if files change
- Large files can make the editor a bit sluggish
- Syntax highlighting doesn't support every language yet
- No git integration (coming soon™)

## Roadmap

- [ ] Git support (diff view, commits, etc.)
- [ ] Better syntax highlighting with tree-sitter
- [ ] Code completion
- [ ] Find/replace across files
- [ ] Multiple windows on macOS
- [ ] Terminal integration
- [ ] Plugin system maybe?

## Contributing

If you want to hack on this, cool. Open an issue first so we can chat about what you're thinking. The codebase is pretty straightforward SwiftUI + MVVM.

Code style: I use 4 spaces, not tabs. SwiftLint config coming eventually.

## Tech Stack

- SwiftUI for all UI
- Highlightr (CodeMirror) for syntax highlighting
- Async/await for networking
- CryptoKit for encryption
- UserDefaults for persistence (yeah I should use CoreData or something)

## License

MIT - do whatever you want with it. If you build something cool on top of this, let me know!

## Credits

Built by Balogh Barnabás (@bbarni2020)

Uses:
- [Hack Club AI](https://ai.hackclub.com) for the AI models
- [Highlightr](https://github.com/raspu/Highlightr) for syntax highlighting

## Notes

The encryption implementation uses RSA-2048 for key exchange and AES-256-GCM for actual data. Client generates a key pair, sends public key to server, server encrypts a session key with it, client decrypts and uses that for the rest of the session. Pretty standard but took forever to debug.

The AI system prompt is in `Models/model.md` - it's basically instructions for how SharAI should behave. You can edit it to change the AI's personality or capabilities.

If you're running your own Shareify server, the protocol expects these endpoints:
- `/user/login` - POST with username/password
- `/cloud/establish_session` - POST with public key
- Any other command via the proxy with `encrypted_payload`

There's probably bugs I haven't found yet. If it breaks, you get to keep both pieces 😅
