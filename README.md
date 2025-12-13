# Shareify Code

I wanted to code on my iPad without a flaky web editor, so I built a native SwiftUI editor with an AI copilot and a little server bridge. There is also a Next.js port of the bits I use the most. If it breaks, you get to keep both pieces.

## What you actually get

- iPadOS/macOS app with real syntax highlighting (Highlightr), tabs, and a file tree.
- SharAI: chat that can read your current file and spit out edits/refactors using Hack Club AI.
- Remote server mode: browse/edit files over a JWT-auth bridge with optional RSA/AES encryption.
- Web flavor in `web/` that keeps login, explorer, tabs, and SharAI for quick desktop use.

## Install (native app)

Tested on Xcode 15+, macOS 14/iOS 17.

```bash
git clone https://github.com/bbarni2020/shareify-code.git
cd shareify-code/app/Shareify\ Code
open Shareify\ Code.xcodeproj
```

Config: drop an `AI_API_KEY` for Hack Club AI into `Config/Secrets.xcconfig` (or export it as an env var). The app talks to `ai.deakteri.club` (proxy to ai.hackclub.com). Then Cmd+R.

## Install (web port)

Needs Node 18-ish.

```bash
cd web
npm install
npm run dev
```

Open http://localhost:3000. API routes proxy to the bridge/command servers so the browser avoids CORS.

## How stuff works (short tour)

- File tree is backed by a simple `FileNode` model; tabs live in `WorkspaceViewModel`. Unsaved changes warn you because I lost a file once.
- Server mode does a two-step: bridge login → server JWT → encrypted commands (RSA key exchange + AES-GCM). Falls back to plaintext if the server says no.
- SharAI uses `Models/model.md` as its prompt, can parse action blocks (EDIT/INSERT/REWRITE) and apply them to the current buffer.
- AI availability is toggled via the remote `info/ai.json` so I can kill it fast if the upstream goes down.

## Quirks and rough edges

- Dark mode only; theme switching is still on the wishlist.
- Large files can lag; there is no real-time file watcher.
- Server URLs are hardcoded today; should move to config soon.
- Web build skips RSA for now; text files only, binary shows a stub.

## Roadmap / todo I keep in my head

- Git bits: diffs, commits, maybe blame.
- Better syntax highlighting (tree-sitter?), code completion, find-in-project.
- Terminal pane and multi-window on macOS.
- Web: RSA session setup, image/video previews, drag-drop/rename niceties.

## Changelog-ish

- 0.2 native: multiple AI models + action buttons + better reconnect.
- 0.1 web: first port, just enough to browse/edit and chat.

## Notes from development

- I use this daily; if something feels opinionated, it probably is.
- The encryption dance is standard RSA-2048 + AES-256-GCM. Key pair generated client-side; server returns session key encrypted with the public key. Works, but took forever to debug.
- If you tweak `Models/model.md`, you can completely change SharAI's vibe.

## License / contact

MIT. If you build on this, ping @bbarni2020. Feedback and PRs welcome; I try to reply fast but I won't promise CI is green every day.
