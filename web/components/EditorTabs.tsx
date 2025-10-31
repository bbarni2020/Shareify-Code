"use client"
import { useStore } from '../lib/store'
import CodeEditor from './CodeEditor'

export default function EditorTabs() {
  const files = useStore(s => s.openFiles)
  const activeId = useStore(s => s.activeId)
  const setActive = useStore(s => s.setActive)
  const closeTab = useStore(s => s.closeTab)
  const saveServerFile = useStore(s => s.saveServerFile)

  const active = files.find(f => f.id === activeId)

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%', background: 'var(--bg)' }}>
      <div style={{ display: 'flex', height: 35, alignItems: 'center', borderBottom: '1px solid var(--border)' }}>
        {files.length > 0 ? (
          <div className="tabs" style={{ flex: 1 }}>
            {files.map(f => (
              <div key={f.id} className={`tab ${f.id===activeId? 'active':''}`} onClick={()=>setActive(f.id)}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  {f.isDirty && <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--text)' }}></div>}
                  {f.title}
                </span>
                <button onClick={(e)=>{ e.stopPropagation(); closeTab(f.id) }}>×</button>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ padding: '0 12px', fontSize: 13, color: 'var(--text-secondary)' }}>No files open</div>
        )}
        
        {active?.isServerFile && active.isDirty && (
          <div style={{ padding: '0 12px', display: 'flex', gap: 8, alignItems: 'center', borderLeft: '1px solid var(--border)' }}>
            <button 
              className="btn primary" 
              onClick={()=>saveServerFile(active.path, active.content)}
              style={{ fontSize: 11, padding: '4px 10px', height: 24 }}
            >
              Save
            </button>
          </div>
        )}
      </div>
      
      <div style={{ flex:1, minHeight:0, overflow: 'hidden' }}>
        {active ? (
          active.binaryData ? (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', flexDirection: 'column', gap: 16, color: 'var(--text-secondary)' }}>
              <div style={{ fontSize: 48, opacity: 0.3 }}>📦</div>
              <div style={{ fontSize: 13 }}>Binary file cannot be displayed</div>
            </div>
          ) : (
            <CodeEditor value={active.content} onChange={(v)=>{
              useStore.setState(s => ({ openFiles: s.openFiles.map(o => o.id===active.id? { ...o, content: v, isDirty: true }: o) }))
            }} fileName={active.title} />
          )
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', flexDirection: 'column', gap: 16, color: 'var(--text-secondary)', padding: 32 }}>
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" opacity="0.3">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="16" y1="13" x2="8" y2="13"/>
              <line x1="16" y1="17" x2="8" y2="17"/>
              <polyline points="10 9 9 9 8 9"/>
            </svg>
            <div style={{ fontSize: 13, textAlign: 'center', lineHeight: 1.6 }}>
              No file selected<br/>
              <span style={{ fontSize: 12, color: 'var(--text-tertiary)' }}>Open a file from the Explorer to start editing</span>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
