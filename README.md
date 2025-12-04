# Shareify Code

This is a SwiftUI code editor I built to scratch my own itch: I wanted to actually code on my iPad without using a clunky web editor or juggling a dozen apps. It's got AI help and can talk to a remote server.


## The Gist

*   **Native Editor:** It's a real iPadOS/macOS app, not a web wrapper.
*   **AI Buddy (SharAI):** An AI chat that can see your code and suggest edits. It's wired up to `ai.deakteri.club`.
*   **Server Mode:** Lets you browse and edit files on a remote machine.

## Getting it Running

It's a standard Xcode project.

1.  `git clone https://github.com/bbarni2020/shareify-code.git`
2.  `cd shareify-code/app/Shareify\ Code`
3.  `open Shareify\ Code.xcodeproj` and hit Cmd+R.

You'll need Xcode 15+ and you have to drop an `AI_API_KEY` for `https://ai.hackclub.com` into an `xcconfig` file or set it as an environment variable for the AI stuff to work.

## Notes from Development

- It's dark mode only because we don't like light.
- There are more detailed READMEs inside the `app` and `web` folders if you're curious.
