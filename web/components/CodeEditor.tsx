"use client"
import React from 'react'
import CodeMirror from '@uiw/react-codemirror'
import { oneDark } from '@codemirror/theme-one-dark'
import { javascript } from '@codemirror/lang-javascript'
import { python } from '@codemirror/lang-python'

function extToExtensions(name: string) {
  const ext = name.split('.').pop()?.toLowerCase()
  if (ext === 'js' || ext === 'ts' || ext === 'tsx' || ext === 'jsx') return [javascript({ typescript: ext?.includes('ts'), jsx: ext?.includes('x') })]
  if (ext === 'py') return [python()]
  return []
}

export default function CodeEditor({ value, onChange, fileName }: { value: string; onChange: (v: string) => void; fileName: string }) {
  return (
    <CodeMirror 
      value={value} 
      height="100%" 
      theme={oneDark} 
      extensions={extToExtensions(fileName)} 
      onChange={onChange} 
      basicSetup={{ 
        lineNumbers: true,
        highlightActiveLineGutter: true,
        highlightSpecialChars: true,
        foldGutter: true,
        drawSelection: true,
        dropCursor: true,
        allowMultipleSelections: true,
        indentOnInput: true,
        bracketMatching: true,
        closeBrackets: true,
        autocompletion: true,
        rectangularSelection: true,
        highlightActiveLine: true,
        highlightSelectionMatches: true
      }}
      style={{ height: '100%', fontSize: '13px', fontFamily: "'JetBrains Mono', 'Consolas', 'Monaco', monospace" }}
    />
  )
}
