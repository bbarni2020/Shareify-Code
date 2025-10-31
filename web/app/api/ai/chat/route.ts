import { NextResponse } from 'next/server'

const systemPrompt = `You are SharAI, an AI assistant for Shareify Code, a web code editor. You help developers write, debug, and improve code. Be concise and provide working examples.`

export async function POST(req: Request) {
  const body = await req.json()
  const messages = [{ role: 'system', content: systemPrompt }, ...(body.messages || [])]
  const r = await fetch('https://ai.hackclub.com/chat/completions', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ messages, model: body.model || 'meta-llama/llama-4-maverick', temperature: 0.7 })
  })
  if (!r.ok) return NextResponse.json({ error: await r.text() }, { status: r.status })
  const j = await r.json()
  const content = j?.choices?.[0]?.message?.content || ''
  return NextResponse.json({ content })
}
