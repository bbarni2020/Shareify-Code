# Shareify Code — web

This is a small web take on the iPad app. I kept the bits I use the most: bridge login, server login, server folder browser, file explorer, editor tabs, and SharAI on the right.

## Install / Run

I tested this on Node 18:

```sh
npm install
npm run dev
```

Then open http://localhost:3000.

## How it works

- All calls go through Next API routes to dodge CORS.
- Bridge login hits `https://bridge.bbarni.hackclub.app/login`.
- Server commands proxy to `https://command.bbarni.hackclub.app/` with the JWT and `X-Shareify-JWT` when you have it.
- AI chat proxies to Hack Club’s `ai.hackclub.com`.

Tokens live in localStorage. If it breaks, you get to keep both pieces.

## Known rough edges

- No RSA/E2E yet. The iPad falls back to plaintext too, so this works; I’ll wire it up later.
- File types: text edits are in, binary just shows a stub for now.
- Finder assumes the server’s `/finder` returns folders when there’s no dot in the name.

## Quick tour

- Left sidebar: logins
- Center: server browser → explorer → tabs + editor
- Right: SharAI

## To‑do

- RSA session setup
- Image/video preview
- Local folder picker using the File System Access API (nice in Chrome)
- Little quality-of-life stuff: rename, drag‑drop, etc.

## Changelog

- 0.1: initial web port. It’s messy but it works.
