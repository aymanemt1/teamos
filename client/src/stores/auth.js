import { defineStore } from 'pinia'
import { supabase } from '../lib/supabase.js'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    profile: null,
    loading: true,
    initialized: false,
    _ready: null,
  }),

  getters: {
    isAuthed: (s) => !!s.user,
    displayName: (s) => s.profile?.name || s.user?.email || '',
  },

  actions: {
    init() {
      if (this._ready) return this._ready
      this._ready = (async () => {
        if (!supabase) {
          this.loading = false
          this.initialized = true
          return
        }
        const { data } = await supabase.auth.getSession()
        this.user = data.session?.user ?? null
        if (this.user) await this.fetchProfile()
        supabase.auth.onAuthStateChange(async (_event, session) => {
          this.user = session?.user ?? null
          if (this.user) await this.fetchProfile()
          else this.profile = null
        })
        this.loading = false
        this.initialized = true
      })()
      return this._ready
    },

    async fetchProfile() {
      if (!supabase || !this.user) return
      const { data } = await supabase.from('profiles').select('*').eq('id', this.user.id).single()
      this.profile = data ?? null
    },

    async signIn(email, password) {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error
    },

    async signUp(email, password, name) {
      // A DB trigger auto-creates the profiles row on signup; name travels via user_metadata.
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { name } },
      })
      if (error) throw error
    },

    async signOut() {
      if (supabase) await supabase.auth.signOut()
      this.user = null
      this.profile = null
    },
  },
})
