import { defineStore } from 'pinia'
import { supabase } from '../lib/supabase.js'
import { useAuthStore } from './auth.js'
import { useProjectStore } from './projects.js'
import { logActivity } from '../lib/activity.js'
import { toast } from '../lib/toast.js'

export const useTaskStore = defineStore('tasks', {
  state: () => ({
    tasks: [], // tasks for the currently selected project
    subtasks: {}, // taskId -> subtask[]
    comments: {}, // taskId -> comment[]
    profilesCache: {}, // userId -> profile
    currentProjectId: null,
    loading: false,
    channel: null,
  }),

  getters: {
    byStatus: (s) => (status) =>
      s.tasks
        .filter((t) => t.status === status)
        .sort((a, b) => (a.position ?? 0) - (b.position ?? 0)),
    subtasksOf: (s) => (taskId) => s.subtasks[taskId] ?? [],
    commentsOf: (s) => (taskId) => s.comments[taskId] ?? [],
    profileOf: (s) => (userId) => (userId ? s.profilesCache[userId] ?? null : null),
  },

  actions: {
    teamIdForCurrentProject() {
      const proj = useProjectStore().projects.find((p) => p.id === this.currentProjectId)
      return proj?.team_id ?? null
    },

    async ensureProfiles(ids) {
      if (!supabase) return
      const missing = [...new Set((ids ?? []).filter(Boolean))].filter((id) => !this.profilesCache[id])
      if (!missing.length) return
      const { data } = await supabase.from('profiles').select('id, name, email, avatar_color').in('id', missing)
      for (const p of data ?? []) this.profilesCache[p.id] = p
    },

    // ---------- reads ----------
    async fetchTasks(projectId) {
      if (!supabase || !projectId) return
      this.loading = true
      this.currentProjectId = projectId
      try {
        const { data, error } = await supabase
          .from('tasks')
          .select('*')
          .eq('project_id', projectId)
          .order('position', { ascending: true })
        if (error) throw error
        this.tasks = data ?? []
        await this.ensureProfiles(this.tasks.flatMap((t) => [t.assignee_id, t.created_by]))
      } finally {
        this.loading = false
      }
      this.subscribe(projectId)
    },

    async fetchSubtasks(taskId) {
      if (!supabase || !taskId) return
      const { data, error } = await supabase
        .from('subtasks')
        .select('*')
        .eq('task_id', taskId)
        .order('position', { ascending: true })
      if (error) throw error
      this.subtasks[taskId] = data ?? []
    },

    async fetchComments(taskId) {
      if (!supabase || !taskId) return
      const { data, error } = await supabase
        .from('comments')
        .select('*')
        .eq('task_id', taskId)
        .order('created_at', { ascending: true })
      if (error) throw error
      this.comments[taskId] = data ?? []
      await this.ensureProfiles(this.comments[taskId].map((c) => c.user_id))
    },

    async fetchTeamTasks(projectIds) {
      if (!supabase || !projectIds?.length) return []
      const { data } = await supabase
        .from('tasks')
        .select('id, project_id, status, completed_at')
        .in('project_id', projectIds)
      return data ?? []
    },

    async fetchSubtaskStats(taskIds) {
      if (!supabase || !taskIds?.length) return { total: 0, done: 0 }
      const { data } = await supabase.from('subtasks').select('id, done').in('task_id', taskIds)
      const list = data ?? []
      return { total: list.length, done: list.filter((s) => s.done).length }
    },

    async fetchRecentActivity(teamId, limit = 15) {
      if (!supabase || !teamId) return []
      const { data } = await supabase
        .from('activities')
        .select('*')
        .eq('team_id', teamId)
        .order('created_at', { ascending: false })
        .limit(limit)
      const ids = [...new Set((data ?? []).map((a) => a.user_id).filter(Boolean))]
      let map = {}
      if (ids.length) {
        const { data: profs } = await supabase.from('profiles').select('id, name, avatar_color').in('id', ids)
        map = Object.fromEntries((profs ?? []).map((p) => [p.id, p]))
      }
      return (data ?? []).map((a) => ({ ...a, user: map[a.user_id] ?? null }))
    },

    // ---------- realtime ----------
    subscribe(projectId) {
      if (!supabase) return
      this.unsubscribe()
      const ch = supabase
        .channel(`teamos-tasks-${projectId}`)
        .on(
          'postgres_changes',
          { event: '*', schema: 'public', table: 'tasks', filter: `project_id=eq.${projectId}` },
          () => this.refreshTasks()
        )
        .on('postgres_changes', { event: '*', schema: 'public', table: 'subtasks' }, (payload) => {
          const tid = payload.new?.task_id ?? payload.old?.task_id
          if (tid && this.tasks.some((t) => t.id === tid)) this.fetchSubtasks(tid)
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'comments' }, (payload) => {
          const tid = payload.new?.task_id ?? payload.old?.task_id
          if (tid && this.tasks.some((t) => t.id === tid)) this.fetchComments(tid)
        })
        .subscribe()
      this.channel = ch
    },

    unsubscribe() {
      if (this.channel && supabase) {
        supabase.removeChannel(this.channel)
        this.channel = null
      }
    },

    async refreshTasks() {
      if (!supabase || !this.currentProjectId) return
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .eq('project_id', this.currentProjectId)
        .order('position', { ascending: true })
      if (error) return
      this.tasks = data ?? []
      await this.ensureProfiles(this.tasks.flatMap((t) => [t.assignee_id, t.created_by]))
    },

    // ---------- mutations ----------
    async createTask(payload) {
      const auth = useAuthStore()
      const pos = this.tasks
        .filter((t) => t.project_id === payload.project_id && t.status === payload.status)
        .reduce((m, t) => Math.max(m, t.position ?? 0), -1)
      const { data, error } = await supabase
        .from('tasks')
        .insert({
          project_id: payload.project_id,
          title: payload.title,
          description: payload.description || null,
          status: payload.status,
          priority: payload.priority,
          assignee_id: payload.assignee_id || null,
          due_date: payload.due_date || null,
          tags: payload.tags ?? [],
          position: pos + 1,
          created_by: auth.user?.id ?? null,
        })
        .select()
        .single()
      if (error) throw error
      if (data.project_id === this.currentProjectId) this.tasks.push(data)
      const proj = useProjectStore().projects.find((p) => p.id === data.project_id)
      logActivity({
        team_id: proj?.team_id,
        user_id: auth.user?.id,
        action: 'task.created',
        subject_type: 'task',
        subject_id: data.id,
        meta: { task_title: data.title },
      })
      return data
    },

    async updateTask(id, patch, { log = true } = {}) {
      const { data, error } = await supabase
        .from('tasks')
        .update({ ...patch, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      const i = this.tasks.findIndex((t) => t.id === id)
      if (i >= 0) this.tasks[i] = data
      await this.ensureProfiles([data.assignee_id])
      if (log) {
        const auth = useAuthStore()
        logActivity({
          team_id: this.teamIdForCurrentProject(),
          user_id: auth.user?.id,
          action: 'task.updated',
          subject_type: 'task',
          subject_id: id,
          meta: { task_title: data.title },
        })
      }
      return data
    },

    /** Persist a drag-and-drop reorder. `columns` = { status: [taskIds in display order] }. */
    async applyOrder(columns) {
      const changed = []
      for (const [status, ids] of Object.entries(columns)) {
        ids.forEach((id, idx) => {
          const t = this.tasks.find((t) => t.id === id)
          if (t && (t.status !== status || (t.position ?? 0) !== idx)) {
            changed.push({ task: t, from: t.status, to: status })
            t.status = status
            t.position = idx
          }
        })
      }
      if (!changed.length) return
      try {
        const results = await Promise.all(
          changed.map(({ task }) =>
            supabase
              .from('tasks')
              .update({ status: task.status, position: task.position, updated_at: new Date().toISOString() })
              .eq('id', task.id)
          )
        )
        const failed = results.find((r) => r.error)
        if (failed) throw failed.error
        const auth = useAuthStore()
        const teamId = this.teamIdForCurrentProject()
        for (const { task, from, to } of changed) {
          if (from === to) continue
          logActivity({
            team_id: teamId,
            user_id: auth.user?.id,
            action: 'task.moved',
            subject_type: 'task',
            subject_id: task.id,
            meta: { from, to, task_title: task.title },
          })
          if (to === 'done') {
            logActivity({
              team_id: teamId,
              user_id: auth.user?.id,
              action: 'task.completed',
              subject_type: 'task',
              subject_id: task.id,
              meta: { task_title: task.title },
            })
          }
        }
      } catch (err) {
        toast.error('Could not save board changes. Reloaded latest state.')
        await this.refreshTasks()
      }
    },

    async deleteTask(id) {
      const task = this.tasks.find((t) => t.id === id)
      const { error } = await supabase.from('tasks').delete().eq('id', id)
      if (error) throw error
      this.tasks = this.tasks.filter((t) => t.id !== id)
      delete this.subtasks[id]
      delete this.comments[id]
      return task
    },

    // ---------- subtasks ----------
    async addSubtask(taskId, title) {
      const list = this.subtasks[taskId] ?? []
      const pos = list.reduce((m, s) => Math.max(m, s.position ?? 0), -1)
      const { data, error } = await supabase
        .from('subtasks')
        .insert({ task_id: taskId, title, done: false, position: pos + 1 })
        .select()
        .single()
      if (error) throw error
      this.subtasks[taskId] = [...list, data]
      return data
    },

    async toggleSubtask(taskId, subtaskId, done) {
      const { data, error } = await supabase
        .from('subtasks')
        .update({ done })
        .eq('id', subtaskId)
        .select()
        .single()
      if (error) throw error
      const list = this.subtasks[taskId] ?? []
      this.subtasks[taskId] = list.map((s) => (s.id === subtaskId ? data : s))
    },

    async deleteSubtask(taskId, subtaskId) {
      const { error } = await supabase.from('subtasks').delete().eq('id', subtaskId)
      if (error) throw error
      this.subtasks[taskId] = (this.subtasks[taskId] ?? []).filter((s) => s.id !== subtaskId)
    },

    // ---------- comments ----------
    async addComment(taskId, body) {
      const auth = useAuthStore()
      const { data, error } = await supabase
        .from('comments')
        .insert({ task_id: taskId, user_id: auth.user?.id ?? null, body })
        .select()
        .single()
      if (error) throw error
      this.comments[taskId] = [...(this.comments[taskId] ?? []), data]
      const task = this.tasks.find((t) => t.id === taskId)
      logActivity({
        team_id: this.teamIdForCurrentProject(),
        user_id: auth.user?.id,
        action: 'task.commented',
        subject_type: 'task',
        subject_id: taskId,
        meta: { task_title: task?.title ?? '' },
      })
      return data
    },
  },
})
