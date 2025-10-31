import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  const body = await req.json()
  const r = await fetch('https://bridge.bbarni.hackclub.app/cloud/establish_session', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${body.jwt}`
    },
    body: JSON.stringify({ client_id: body.clientId, public_key: body.publicKey })
  })
  const text = await r.text()
  const isJson = (() => { try { JSON.parse(text); return true } catch { return false } })()
  const data = isJson ? JSON.parse(text) : { error: text }
  return NextResponse.json(data, { status: r.status })
}
