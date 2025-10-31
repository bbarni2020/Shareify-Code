"use client"
import { useState } from 'react'
import { useStore } from '../lib/store'

export default function LoginBridge() {
  const loginBridge = useStore(s => s.loginBridge)
  const jwt = useStore(s => s.jwtToken)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [err, setErr] = useState('')

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErr('')
    setLoading(true)
    try { await loginBridge(email, password) } catch (e: any) { setErr(e.message || 'failed') } finally { setLoading(false) }
  }

  return (
    <div style={{ borderBottom: '1px solid var(--border-subtle)' }}>
      <div className="sectionTitle">Bridge Login</div>
      {jwt ? (
        <div className="row" style={{ background: 'var(--accent-muted)', borderColor: 'var(--accent)' }}>
          <div style={{ width: 24, height: 24, borderRadius: '50%', background: 'var(--success)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12 }}>✓</div>
          <div style={{ flex: 1, fontWeight: 500 }}>Connected</div>
          <div className="badge" style={{ background: 'var(--success)', color: '#fff', border: 'none' }}>Active</div>
        </div>
      ) : (
        <form onSubmit={onSubmit} style={{ padding: 16, display:'flex', flexDirection: 'column', gap: 12 }}>
          <input className="input" placeholder="Email address" value={email} onChange={e=>setEmail(e.target.value)} autoComplete="email" />
          <input className="input" placeholder="Password" type="password" value={password} onChange={e=>setPassword(e.target.value)} autoComplete="current-password" />
          <button className="btn primary" disabled={loading} type="submit">{loading? 'Connecting...' : 'Connect'}</button>
          {err && <div style={{ padding: 10, borderRadius: 8, background: 'rgba(248, 81, 73, 0.15)', border: '1px solid var(--danger)', color: 'var(--danger)', fontSize: 13 }}>{err}</div>}
        </form>
      )}
    </div>
  )
}
