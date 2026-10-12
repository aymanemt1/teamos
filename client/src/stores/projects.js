import { defineStore } from 'pinia'
import { supabase } from '../lib/supabase.js'
import { useAuthStore } from './auth.js'
import { logActivity } from '../lib/activity.js'

export const useProjectStore = defineStore('projects', {
  state: () => ({
    projects: [],
    loading: false,
  }),

  getters: {
    active: (s) => s.projects.filter((p) => p.status === 'active'),
    byId: (s) => (id) => s.projects.find((p) => p.id === id),
  },

  actions: {
    async fetchProjects(teamId) {
      if (!supabase || !teamId) return
      this.loading = true
      try {
        const { data, error } = await supabase
          .from('projects')
          .select('*')
          .eq('team_id', teamId)
          .order('position', { ascending: true })
        if (error) throw error
        this.projects = data ?? []
      } finally {
        this.loading = false
      }
    },

    async createProject(teamId, payload) {
      const maxPos = this.projects.reduce((m, p) => Math.max(m, p.position ?? 0), -1)
      const { data, error } = await supabase
        .from('projects')
        .insert({ team_id: teamId, status: 'active', position: maxPos + 1, ...payload })
        .select()
        .single()
      if (error) throw error
      this.projects.push(data)
      const auth = useAuthStore()
      logActivity({
        team_id: teamId,
        user_id: auth.user?.id,
        action: 'project.created',
        subject_type: 'project',
        subject_id: data.id,
        meta: { name: data.name, key: data.key },
      })
      return data
    },

    async updateProject(id, patch) {
      const { data, error } = await supabase
        .from('projects')
        .update({ ...patch, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      const i = this.projects.findIndex((p) => p.id === id)
      if (i >= 0) this.projects[i] = data
      return data
    },

    async deleteProject(id) {
      const { error } = await supabase.from('projects').delete().eq('id', id)
      if (error) throw error
      this.projects = this.projects.filter((p) => p.id !== id)
    },
  },
})
