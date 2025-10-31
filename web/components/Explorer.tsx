"use client"
import { useEffect } from 'react'
import { useStore } from '../lib/store'
import { ServerFileNode } from '../lib/types'

function Node({ n, depth }: { n: ServerFileNode; depth: number }) {
  const loadChildren = useStore(s => s.loadChildren)
  const openFile = useStore(s => s.openServerFile)
  const expanded = useStore(s => s.expandedPaths)
  const setExpanded = useStore.setState

  const isOpen = expanded.has(n.path)

  useEffect(() => { if (n.isFolder && isOpen && !n.children) loadChildren(n.path) }, [isOpen, n.path])

  const getIcon = () => {
    if (n.isFolder) return isOpen ? '▼' : '▶'
    const ext = n.name.split('.').pop()?.toLowerCase()
    if (ext === 'js' || ext === 'jsx') return '📄'
    if (ext === 'ts' || ext === 'tsx') return '📘'
    if (ext === 'py') return '🐍'
    if (ext === 'json') return '📋'
    if (ext === 'md') return '📝'
    return '📄'
  }

  return (
    <div>
      <div className="row" style={{ paddingLeft: 8 + depth * 16 }} onClick={() => {
        if (n.isFolder) {
          const next = new Set(expanded)
          if (next.has(n.path)) next.delete(n.path); else next.add(n.path)
          setExpanded({ expandedPaths: next })
        } else openFile(n.path)
      }}>
        <div style={{ width: 16, fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-tertiary)' }}>
          {getIcon()}
        </div>
        <div style={{ flex: 1, fontSize: 13, fontWeight: n.isFolder ? 500 : 400, overflow: 'hidden', textOverflow: 'ellipsis' }}>{n.name}</div>
      </div>
      {n.isFolder && isOpen && n.children?.map(c => (
        <Node key={c.path} n={c} depth={depth + 1} />
      ))}
    </div>
  )
}

export default function Explorer() {
  const root = useStore(s => s.serverRoot)
  if (!root) return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div className="sectionTitle">EXPLORER</div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', flex: 1, gap: 12, padding: 16 }}>
        <div style={{ fontSize: 32, opacity: 0.3 }}>📂</div>
        <div style={{ color: 'var(--text-secondary)', fontSize: 12, textAlign: 'center', lineHeight: 1.5 }}>
          No folder opened<br/>
          <span style={{ color: 'var(--text-tertiary)' }}>Click "Open Folder" to get started</span>
        </div>
      </div>
    </div>
  )
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div className="sectionTitle">EXPLORER</div>
      <div className="list">
        <Node n={root} depth={0} />
      </div>
    </div>
  )
}
