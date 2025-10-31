export async function bridgeLogin(email: string, password: string) {
  const r = await fetch('/api/bridge/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) })
  if (!r.ok) throw new Error('bridge login failed')
  const j = await r.json()
  return j as { jwt_token: string }
}

export async function establishSession(jwt: string, clientId: string, publicKey: string) {
  const r = await fetch('/api/bridge/establish_session', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ jwt, clientId, publicKey }) })
  if (!r.ok) throw new Error('session failed')
  return r.json()
}

export async function command(jwt: string, shareifyJwt: string | null, payload: any) {
  const r = await fetch('/api/command', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ jwt, shareifyJwt, payload }) })
  if (!r.ok) throw new Error('command failed')
  return r.json()
}

export async function chat(messages: { role: string; content: string }[], model?: string) {
  const r = await fetch('/api/ai/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ messages, model }) })
  if (!r.ok) throw new Error('chat failed')
  const j = await r.json()
  return j as { content: string }
}

export async function models() {
  const r = await fetch('/api/ai/models')
  if (!r.ok) throw new Error('models failed')
  return r.json()
}
