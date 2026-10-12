import { defineStore } from 'pinia'
import { supabase } from '../lib/supabase.js'
import { useAuthStore } from './auth.js'
import { logActivity } from '../lib/activity.js'

// NOTE (schema-agent caveat): the teams INSERT RLS policy requires
// is_team_member(id), so a brand-new team can't be inserted from the client.
// This store intentionally has NO create-team action — teams are created by an
// admin in the Supabase dashboard. Switching between existing teams is fine.
export const useTeamStore = defineStore('team', {
  state: () => ({
    teams: [],
    currentTeamId: null,
    members: [],
    loading: false,
  }),

  getters: {
    currentTeam: (s) => s.teams.find((t) => t.id === s.currentTeamId) ?? null,
    myRole(state) {
      const auth = useAuthStore()
      const m = state.members.find((m) => m.user_id === auth.user?.id)
      return m?.role ?? null
    },
    canManage(state) {
      return ['owner', 'admin'].includes(this.myRole)
    },
  },

  actions: {
    async fetchTeams() {
      if (!supabase) return
      const auth = useAuthStore()
      if (!auth.user) return
      this.loading = true
      try {
        const { data, error } = await supabase
          .from('team_members')
          .select('team_id, teams(id, name, slug)')
          .eq('user_id', auth.user.id)
        if (error) throw error
        this.teams = (data ?? []).map((r) => r.teams).filter(Boolean)
        if (!this.teams.some((t) => t.id === this.currentTeamId)) {
          this.currentTeamId = this.teams[0]?.id ?? null
        }
      } finally {
        this.loading = false
      }
    },

    setCurrentTeam(id) {
      this.currentTeamId = id
      this.members = []
    },

    async fetchMembers() {
      if (!supabase || !this.currentTeamId) return
      const { data, error } = await supabase
        .from('team_members')
        .select('id, team_id, user_id, role, created_at')
        .eq('team_id', this.currentTeamId)
        .order('created_at', { ascending: true })
      if (error) throw error
      // Join profiles client-side (two queries) so we don't depend on FK constraint names.
      const ids = [...new Set((data ?? []).map((m) => m.user_id))]
      let profiles = {}
      if (ids.length) {
        const { data: profs } = await supabase
          .from('profiles')
          .select('id, email, name, avatar_color')
          .in('id', ids)
        profiles = Object.fromEntries((profs ?? []).map((p) => [p.id, p]))
      }
      this.members = (data ?? []).map((m) => ({ ...m, profile: profiles[m.user_id] ?? null }))
    },

    async updateRole(memberId, role) {
      const { error } = await supabase.from('team_members').update({ role }).eq('id', memberId)
      if (error) throw error
      const m = this.members.find((m) => m.id === memberId)
      if (m) m.role = role
    },

    async removeMember(memberId) {
      const { error } = await supabase.from('team_members').delete().eq('id', memberId)
      if (error) throw error
      this.members = this.members.filter((m) => m.id !== memberId)
    },

    async addMemberByEmail(email) {
      const clean = email.trim().toLowerCase()
      const { data: prof, error } = await supabase
        .from('profiles')
        .select('id, email, name')
        .eq('email', clean)
        .maybeSingle()
      if (error) throw error
      if (!prof) {
        throw new Error('No account found for that email. They need to sign up first, then you can add them here.')
      }
      if (this.members.some((m) => m.user_id === prof.id)) {
        throw new Error('This person is already a member of the team.')
      }
      const { error: insErr } = await supabase
        .from('team_members')
        .insert({ team_id: this.currentTeamId, user_id: prof.id, role: 'member' })
      if (insErr) throw insErr
      await this.fetchMembers()
      const auth = useAuthStore()
      logActivity({
        team_id: this.currentTeamId,
        user_id: auth.user?.id,
        action: 'team.member_added',
        subject_type: 'user',
        subject_id: prof.id,
        meta: { email: prof.email, name: prof.name },
      })
    },
  },
})
