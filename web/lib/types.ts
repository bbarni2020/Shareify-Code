export type ServerFileNode = {
  id: string
  name: string
  path: string
  isFolder: boolean
  children?: ServerFileNode[]
}

export type OpenFile = {
  id: string
  path: string
  title: string
  content: string
  isDirty: boolean
  isLoading: boolean
  isServerFile: boolean
  binaryData?: string
}

export type ChatMessage = { role: 'system' | 'user' | 'assistant'; content: string }
