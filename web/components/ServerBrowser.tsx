"use client"
import { useEffect, useState } from 'react'
import { useStore } from '../lib/store'

export default function ServerBrowser() {
  const open = useStore(s => s.serverBrowserOpen)
  const setOpen = useStore(s => s.setServerBrowserOpen)
  const loadChildren = useStore(s => s.loadChildren)
  const setServerFolder = useStore(s => s.setServerFolder)
  const [path, setPath] = useState<string[]>([])
  const [items, setItems] = useState<{ name: string; isFolder: boolean }[]>([])
  const [loading, setLoading] = useState(false)
  const [selected, setSelected] = useState<string | null>(null)

  useEffect(() => { if (open) fetchItems() }, [open, path.join('/')])

  async function fetchItems() {
    setLoading(true)
    try {
      const p = path.join('/')
      const kids = await loadChildren(p)
      setItems(kids.filter(k=>k.isFolder).map(k => ({ name: k.name, isFolder: k.isFolder })))
    } catch { setItems([]) } finally { setLoading(false) }
  }

  function openFolder(name: string) {
    setPath([...path, name])
    setSelected(null)
  }

  async function choose() {
    if (!selected) return
    const full = [...path, selected].join('/')
    await setServerFolder(full)
    setOpen(false)
    setPath([])
    setSelected(null)
  }

  if (!open) return null
  const displayPath = path.length ? path : ['Root']

  return (
    <div className="modal" onClick={() => setOpen(false)}>
      <div className="modalCard" onClick={e=>e.stopPropagation()}>
        <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--border)' }}>
          <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>Server Browser</div>
          <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Navigate and select a folder to open</div>
        </div>
        <div className="breadcrumbs">
          {displayPath.map((seg, i) => (
            <div key={i} style={{ display:'flex', alignItems:'center', gap:8 }}>
              <div className="badge" style={{ fontSize: 13, fontWeight: 500 }}>{seg}</div>
              {i<displayPath.length-1 && <div style={{ color: 'var(--text-tertiary)' }}>→</div>}
            </div>
          ))}
        </div>
        <div className="list" style={{ minHeight: 300 }}>
          {loading ? (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 200, flexDirection: 'column', gap: 12 }}>
              <div style={{ width: 32, height: 32, border: '3px solid var(--border)', borderTop: '3px solid var(--accent)', borderRadius: '50%', animation: 'spin 1s linear infinite' }}></div>
              <div style={{ color: 'var(--text-secondary)' }}>Loading folders...</div>
            </div>
          ) : items.length === 0 ? (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 200, color: 'var(--text-secondary)' }}>No folders found</div>
          ) : items.map((it, idx) => (
            <div key={idx} className="row" onDoubleClick={()=>openFolder(it.name)} onClick={()=>setSelected(selected===it.name? null: it.name)} style={{ background: selected===it.name? 'var(--accent-muted)': undefined, borderColor: selected===it.name? 'var(--accent)': 'var(--border-subtle)', borderLeft: selected===it.name? '3px solid var(--accent)': '3px solid transparent', paddingLeft: selected===it.name? 13: 16 }}>
              <div style={{ fontSize: 20 }}>📁</div>
              <div style={{ flex:1, fontWeight: 500 }}>{it.name}</div>
              <button className="btn" style={{ fontSize: 12, padding: '6px 12px' }} onClick={(e)=>{ e.stopPropagation(); openFolder(it.name) }}>→</button>
            </div>
          ))}
        </div>
        <div style={{ padding: 16, display:'flex', gap:12, borderTop:'1px solid var(--border)', background: 'var(--elev)' }}>
          <button className="btn" style={{ flex: 1 }} onClick={()=>setOpen(false)}>Cancel</button>
          <button className="btn primary" style={{ flex: 2 }} onClick={choose} disabled={!selected}>Open Selected Folder</button>
        </div>
      </div>
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  )
}
