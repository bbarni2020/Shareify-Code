import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  const body = await req.json()
  const r = await fetch('https://bridge.bbarni.hackclub.app/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: body.email, password: body.password })
  })
  const text = await r.text()
  const isJson = (() => { try { JSON.parse(text); return true } catch { return false } })()
  const data = isJson ? JSON.parse(text) : { error: text }
  return NextResponse.json(data, { status: r.status })
}
