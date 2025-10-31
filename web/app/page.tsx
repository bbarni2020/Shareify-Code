"use client"
import { useState } from 'react'
import LoginBridge from '../components/LoginBridge'
import LoginServer from '../components/LoginServer'
import ServerBrowser from '../components/ServerBrowser'
import Explorer from '../components/Explorer'
import EditorTabs from '../components/EditorTabs'
import AIChat from '../components/AIChat'
import { useStore } from '../lib/store'

export default function Page() {
  const setServerBrowserOpen = useStore(s => s.setServerBrowserOpen)
  const serverFolderPath = useStore(s => s.serverFolderPath)
  const jwt = useStore(s => s.jwtToken)
  const shareifyJwt = useStore(s => s.shareifyJwt)
  const [showSidebar, setShowSidebar] = useState(true)
  const [showAIPanel, setShowAIPanel] = useState(true)

  if (!jwt || !shareifyJwt) {
    return (
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #0a0e14 0%, #1a1f2e 100%)',
        padding: 20
      }}>
        <div style={{ 
          width: '100%', 
          maxWidth: 480, 
          background: 'var(--panel)', 
          border: '1px solid var(--border)', 
          borderRadius: 16,
          overflow: 'hidden',
          boxShadow: 'var(--shadow-lg)'
        }}>
          <div style={{ padding: '32px 32px 24px', borderBottom: '1px solid var(--border)', textAlign: 'center' }}>
            <div style={{ fontSize: 32, fontWeight: 800, background: 'linear-gradient(135deg, var(--accent) 0%, #a371f7 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: 8 }}>
              Shareify Code
            </div>
            <div style={{ fontSize: 14, color: 'var(--text-secondary)' }}>
              Modern cloud-based code editor
            </div>
          </div>
          <div>
            <LoginBridge />
            {jwt && <LoginServer />}
          </div>
          {jwt && shareifyJwt && (
            <div style={{ padding: 20, background: 'var(--success)', color: '#fff', textAlign: 'center', fontWeight: 600 }}>
              ✓ Authentication successful
            </div>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="container">
      <div className="header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <button 
            className="btn" 
            onClick={() => setShowSidebar(!showSidebar)}
            style={{ padding: '8px 10px', fontSize: 16 }}
            title="Toggle Explorer"
          >
            ☰
          </button>
          <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--text)' }}>Shareify Code</div>
        </div>
        
        <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          {serverFolderPath && (
            <div style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: 8, 
              padding: '6px 12px', 
              background: 'var(--elev)', 
              borderRadius: 8,
              fontSize: 13,
              color: 'var(--text-secondary)'
            }}>
              <span>📁</span>
              <span style={{ fontWeight: 500, color: 'var(--text)' }}>{serverFolderPath.split('/').pop()}</span>
              <span style={{ color: 'var(--text-tertiary)' }}>{serverFolderPath}</span>
            </div>
          )}
        </div>

        <div className="split">
          <button className="btn" onClick={()=>setServerBrowserOpen(true)} style={{ fontSize: 13, padding: '8px 14px' }}>
            📁 Open Folder
          </button>
          <button 
            className="btn" 
            onClick={() => setShowAIPanel(!showAIPanel)}
            style={{ padding: '8px 14px', fontSize: 13 }}
            title="Toggle AI Panel"
          >
            {showAIPanel ? '→' : '←'} AI
          </button>
        </div>
      </div>
      
      <div className="main">
        {showSidebar && (
          <div className="sidebar" style={{ width: 280 }}>
            <Explorer />
          </div>
        )}
        
        <div className="center">
          <EditorTabs />
        </div>
        
        {showAIPanel && (
          <div className="rightbar" style={{ width: 380 }}>
            <AIChat />
          </div>
        )}
      </div>
      
      <ServerBrowser />
    </div>
  )
}
