"use client"
import { useEffect, useRef, useState } from 'react'
import { useStore } from '../lib/store'

export default function AIChat() {
  const messages = useStore(s => s.aiMessages)
  const sendAi = useStore(s => s.sendAi)
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => { listRef.current?.scrollTo({ top: 1e6 }) }, [messages.length])

  async function onSend() {
    if (!input.trim()) return
    setLoading(true)
    await sendAi(input)
    setInput('')
    setLoading(false)
  }

  return (
    <div className="chat">
      <div className="sectionTitle">AI ASSISTANT</div>
      <div ref={listRef} className="messages" style={{ padding: 12 }}>
        {messages.length === 0 ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', flexDirection: 'column', gap: 12, color: 'var(--text-secondary)', padding: 16 }}>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" opacity="0.3">
              <path d="M12 8V4H8"/>
              <rect x="8" y="2" width="8" height="4" rx="1" ry="1"/>
              <rect x="6" y="6" width="12" height="14" rx="2" ry="2"/>
              <path d="M9 12h6"/>
              <path d="M9 15h6"/>
            </svg>
            <div style={{ fontSize: 12, textAlign: 'center', lineHeight: 1.6 }}>
              AI Assistant Ready<br/>
              <span style={{ fontSize: 11, color: 'var(--text-tertiary)' }}>Ask questions about your code</span>
            </div>
          </div>
        ) : (
          messages.map((m, i) => (
            <div key={i} className="message">
              <div className="role">{m.role === 'user' ? 'YOU' : m.role === 'assistant' ? 'AI' : m.role.toUpperCase()}</div>
              <div className="bubble" style={{ fontSize: 12, lineHeight: 1.6 }}>{m.content}</div>
            </div>
          ))
        )}
      </div>
      <div style={{ display:'flex', gap:8, padding:12, borderTop:'1px solid var(--border)', background: 'var(--panel)' }}>
        <input 
          className="input" 
          placeholder="Ask AI..." 
          value={input} 
          onChange={e=>setInput(e.target.value)} 
          onKeyDown={e=>{ if (e.key==='Enter' && !e.shiftKey) { e.preventDefault(); onSend() } }} 
          disabled={loading} 
          style={{ flex: 1, fontSize: 12 }} 
        />
        <button 
          className="btn primary" 
          onClick={onSend} 
          disabled={loading || !input.trim()} 
          style={{ width: 32, height: 32, padding: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
        >
          {loading ? '...' : '→'}
        </button>
      </div>
    </div>
  )
}
