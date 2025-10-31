import { NextResponse } from 'next/server'

export async function GET() {
  const r = await fetch('https://ai.hackclub.com/models')
  const text = await r.text()
  const isJson = (() => { try { JSON.parse(text); return true } catch { return false } })()
  const data = isJson ? JSON.parse(text) : { error: text }
  return NextResponse.json(data, { status: r.status })
}
