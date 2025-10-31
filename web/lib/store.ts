import { create } from 'zustand'
import { OpenFile, ServerFileNode, ChatMessage } from './types'
import { bridgeLogin, command, chat } from './api'

type State = {
  jwtToken: string | null
  userEmail: string | null
  userPassword: string | null
  shareifyJwt: string | null
  serverUsername: string | null
  serverPassword: string | null
  serverFolderPath: string | null
  serverRoot: ServerFileNode | null
  expandedPaths: Set<string>
  openFiles: OpenFile[]
  activeId: string | null
  showHidden: boolean
  serverBrowserOpen: boolean
  aiMessages: ChatMessage[]
  setJwt: (t: string | null) => void
  loginBridge: (email: string, password: string) => Promise<void>
  loginServer: (username: string, password: string) => Promise<void>
  setServerFolder: (path: string) => Promise<void>
  loadChildren: (path: string) => Promise<ServerFileNode[]>
  openServerFile: (path: string) => Promise<void>
  saveServerFile: (path: string, content: string) => Promise<void>
  createServerFile: (dir: string, name: string) => Promise<void>
  createServerFolder: (dir: string, name: string) => Promise<void>
  deleteServerNode: (path: string, isFolder: boolean) => Promise<void>
  setActive: (id: string) => void
  closeTab: (id: string) => void
  setServerBrowserOpen: (v: boolean) => void
  sendAi: (content: string, model?: string) => Promise<string>
}

function idFor(path: string) { return path }

export const useStore = create<State>((set: (partial: Partial<State> | ((s: State) => Partial<State>), replace?: boolean) => void, get: () => State) => ({
  jwtToken: typeof window !== 'undefined' ? localStorage.getItem('jwt_token') : null,
  userEmail: typeof window !== 'undefined' ? localStorage.getItem('user_email') : null,
  userPassword: typeof window !== 'undefined' ? localStorage.getItem('user_password') : null,
  shareifyJwt: typeof window !== 'undefined' ? localStorage.getItem('shareify_jwt') : null,
  serverUsername: typeof window !== 'undefined' ? localStorage.getItem('server_username') : null,
  serverPassword: typeof window !== 'undefined' ? localStorage.getItem('server_password') : null,
  serverFolderPath: typeof window !== 'undefined' ? localStorage.getItem('server_folder_path') : null,
  serverRoot: null,
  expandedPaths: new Set<string>(),
  openFiles: [],
  activeId: null,
  showHidden: false,
  serverBrowserOpen: false,
  aiMessages: [],
  setJwt: (t: string | null) => set(() => { if (typeof window !== 'undefined') t ? localStorage.setItem('jwt_token', t) : localStorage.removeItem('jwt_token'); return { jwtToken: t } }),
  async loginBridge(email: string, password: string) {
    const res = await bridgeLogin(email, password)
    localStorage.setItem('jwt_token', res.jwt_token)
    localStorage.setItem('user_email', email)
    localStorage.setItem('user_password', password)
    set({ jwtToken: res.jwt_token, userEmail: email, userPassword: password })
  },
  async loginServer(username: string, password: string) {
    const jwt = get().jwtToken
    if (!jwt) throw new Error('no jwt')
    const payload = { command: '/user/login', method: 'POST', wait_time: 5, body: { username, password } }
    const j = await command(jwt, null, payload)
    if (j.token) {
      localStorage.setItem('shareify_jwt', j.token)
      localStorage.setItem('server_username', username)
      localStorage.setItem('server_password', password)
      set({ shareifyJwt: j.token, serverUsername: username, serverPassword: password })
    } else throw new Error('no token')
  },
  async setServerFolder(path: string) {
    set({ serverFolderPath: path })
    localStorage.setItem('server_folder_path', path)
    const root: ServerFileNode = { id: path, name: path.split('/').pop() || 'Root', path, isFolder: true, children: [] }
    set({ serverRoot: root, expandedPaths: new Set([path]) })
    await get().loadChildren(path)
  },
  async loadChildren(path: string) {
    const jwt = get().jwtToken
    const sjwt = get().shareifyJwt
    if (!jwt) throw new Error('no jwt')
    const payload = { command: '/finder', method: 'GET', wait_time: 3, body: { path } }
    const r = await command(jwt, sjwt, payload)
    const items: string[] = Array.isArray(r) ? r : r.items || []
    const kids = items.map((name: string) => ({ id: `${path}/${name}`, name, path: `${path}/${name}`, isFolder: !name.includes('.') }))
  set((s: State) => {
      if (!s.serverRoot) return s
      function attach(n: ServerFileNode): ServerFileNode {
        if (n.path === path) return { ...n, children: kids }
        if (!n.children) return n
        return { ...n, children: n.children.map(attach) }
      }
      return { serverRoot: attach(s.serverRoot) }
    })
    return kids
  },
  async openServerFile(path: string) {
    const jwt = get().jwtToken
    const sjwt = get().shareifyJwt
    if (!jwt) throw new Error('no jwt')
    const id = idFor(path)
  const exists = get().openFiles.find((f: OpenFile) => f.id === id)
    if (exists) return set({ activeId: id })
    const payload = { command: `/get_file?file_path=${encodeURIComponent(path)}`, method: 'GET', wait_time: 5 }
    const r = await command(jwt, sjwt, payload)
    if (r && r.status === 'File content retrieved') {
      if (r.type === 'text') {
        const of: OpenFile = { id, path, title: path.split('/').pop() || path, content: r.content, isDirty: false, isLoading: false, isServerFile: true }
  set((s: State) => ({ openFiles: [...s.openFiles, of], activeId: id }))
      } else if (r.type === 'binary') {
        const of: OpenFile = { id, path, title: path.split('/').pop() || path, content: '', isDirty: false, isLoading: false, isServerFile: true, binaryData: r.content }
  set((s: State) => ({ openFiles: [...s.openFiles, of], activeId: id }))
      }
    }
  },
  async saveServerFile(path: string, content: string) {
    const jwt = get().jwtToken
    const sjwt = get().shareifyJwt
    if (!jwt) throw new Error('no jwt')
    const payload = { command: '/edit_file', method: 'POST', wait_time: 3, body: { path, file_content: content } }
    await command(jwt, sjwt, payload)
  set((s: State) => ({ openFiles: s.openFiles.map((f: OpenFile) => f.path === path ? { ...f, isDirty: false } : f) }))
  },
  async createServerFile(dir: string, name: string) {
    const jwt = get().jwtToken
    const sjwt = get().shareifyJwt
    if (!jwt) throw new Error('no jwt')
    const body = { file_name: name, path: dir.endsWith('/') ? dir : dir + '/', file_content: '' }
    await command(jwt, sjwt, { command: '/new_file', method: 'POST', wait_time: 3, body })
    await get().loadChildren(dir)
  },
  async createServerFolder(dir: string, name: string) {
    const jwt = get().jwtToken
    const sjwt = get().shareifyJwt
    if (!jwt) throw new Error('no jwt')
    const body = { folder_name: name, path: dir.endsWith('/') ? dir : dir + '/' }
    await command(jwt, sjwt, { command: '/create_folder', method: 'POST', wait_time: 3, body })
    await get().loadChildren(dir)
  },
  async deleteServerNode(path: string, isFolder: boolean) {
    const jwt = get().jwtToken
    const sjwt = get().shareifyJwt
    if (!jwt) throw new Error('no jwt')
    const cmd = isFolder ? '/api/delete_folder' : '/api/delete_file'
    await command(jwt, sjwt, { command: cmd, method: 'POST', wait_time: 3, body: { path } })
    const parent = path.split('/').slice(0,-1).join('/')
    await get().loadChildren(parent)
  },
  setActive: (id: string) => set({ activeId: id }),
  closeTab: (id: string) => set((s: State) => ({ openFiles: s.openFiles.filter((f: OpenFile) => f.id !== id), activeId: s.activeId === id ? s.openFiles.filter((f: OpenFile) => f.id !== id).slice(-1)[0]?.id || null : s.activeId })),
  setServerBrowserOpen: (v: boolean) => set({ serverBrowserOpen: v }),
  async sendAi(content: string, model?: string) {
    const messages = [...get().aiMessages, { role: 'user', content } as ChatMessage]
    set({ aiMessages: messages })
    const res = await chat(messages, model)
    const next = [...messages, { role: 'assistant', content: res.content } as ChatMessage]
    set({ aiMessages: next })
    return res.content
  }
}))
