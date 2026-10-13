<template>
  <div class="p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto">
    <!-- header -->
    <div class="flex flex-wrap items-center justify-between gap-4 mb-6 anim-fade-up">
      <div>
        <h1 class="text-2xl font-extrabold tracking-tight text-white">Dashboard</h1>
        <p class="text-sm text-muted mt-1">
          {{ greeting }}, {{ auth.displayName || 'there' }} — here is your team at a glance.
        </p>
      </div>
      <div class="w-56"><TeamSwitcher @change="reload" /></div>
    </div>

    <div v-if="!loading && loadError" role="alert">
      <EmptyState icon="alert" title="Couldn't load the dashboard" :subtitle="loadError">
        <button type="button" class="btn-primary" @click="reload">Try again</button>
      </EmptyState>
    </div>

    <EmptyState
      v-else-if="!loading && !team.currentTeamId"
      icon="users"
      title="No team yet"
      subtitle="You're not on a team yet. An admin creates teams and adds members in the Supabase dashboard."
    />

    <template v-else>
    <!-- stat cards -->
    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
      <Skeleton v-for="i in 4" :key="i" cls="h-32" />
    </div>
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
      <StatCard icon="folder" label="Active projects" :value="stats.activeProjects" accent="#7c6cf0" stagger="stagger-1" />
      <StatCard icon="check" label="Tasks completed" :value="stats.tasksCompleted" accent="#3fb950" stagger="stagger-2" />
      <StatCard icon="users" label="Team members" :value="stats.members" accent="#2f81f7" stagger="stagger-3" />
      <StatCard icon="board" label="Productivity" :value="stats.productivity" suffix="%" accent="#f0b45e" stagger="stagger-4" />
    </div>

    <!-- charts + activity -->
    <div class="grid grid-cols-1 xl:grid-cols-3 gap-4">
      <div class="xl:col-span-2 grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div class="bg-card border border-border rounded-2xl p-5 anim-fade-up stagger-2">
          <h2 class="font-bold text-white mb-1">Tasks by status</h2>
          <p class="text-xs text-muted mb-4">Across all team projects</p>
          <Skeleton v-if="loading" cls="h-32" />
          <DonutChart v-else :items="statusBreakdown" />
        </div>
        <div class="bg-card border border-border rounded-2xl p-5 anim-fade-up stagger-3">
          <h2 class="font-bold text-white mb-1">Completed this week</h2>
          <p class="text-xs text-muted mb-4">Tasks finished per day, last 7 days</p>
          <Skeleton v-if="loading" cls="h-36" />
          <WeeklyBars v-else :days="weekly" />
        </div>
      </div>

      <div class="bg-card border border-border rounded-2xl p-5 anim-fade-up stagger-4">
        <div class="flex items-center justify-between mb-2">
          <h2 class="font-bold text-white">Activity</h2>
          <span class="text-xs text-muted">Latest 15</span>
        </div>
        <Skeleton v-if="loading" cls="h-64" />
        <div v-else class="max-h-[420px] overflow-y-auto pr-1">
          <ActivityFeed :activities="activities" />
        </div>
      </div>
    </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import { useTeamStore } from '../stores/team.js'
import { useProjectStore } from '../stores/projects.js'
import { useTaskStore } from '../stores/tasks.js'
import { STATUSES } from '../lib/meta.js'
import StatCard from '../components/StatCard.vue'
import DonutChart from '../components/DonutChart.vue'
import WeeklyBars from '../components/WeeklyBars.vue'
import ActivityFeed from '../components/ActivityFeed.vue'
import TeamSwitcher from '../components/TeamSwitcher.vue'
import Skeleton from '../components/Skeleton.vue'
import EmptyState from '../components/EmptyState.vue'

const auth = useAuthStore()
const team = useTeamStore()
const projectStore = useProjectStore()
const taskStore = useTaskStore()

const loading = ref(true)
const loadError = ref('')
const stats = ref({ activeProjects: 0, tasksCompleted: 0, members: 0, productivity: 0 })
const statusBreakdown = ref([])
const weekly = ref([])
const activities = ref([])

const greeting = computed(() => {
  const h = new Date().getHours()
  if (h < 12) return 'Good morning'
  if (h < 18) return 'Good afternoon'
  return 'Good evening'
})

async function reload() {
  loading.value = true
  loadError.value = ''
  try {
    await team.fetchTeams()
    if (!team.currentTeamId) return
    await Promise.all([
      projectStore.fetchProjects(team.currentTeamId),
      team.fetchMembers(),
    ])

    const projectIds = projectStore.projects.map((p) => p.id)
    const allTasks = await taskStore.fetchTeamTasks(projectIds)
    const taskIds = allTasks.map((t) => t.id)
    const { total, done } = await taskStore.fetchSubtaskStats(taskIds)

    stats.value = {
      activeProjects: projectStore.projects.filter((p) => p.status === 'active').length,
      tasksCompleted: allTasks.filter((t) => t.status === 'done').length,
      members: team.members.length,
      productivity: total ? Math.round((done / total) * 100) : 0,
    }

    statusBreakdown.value = STATUSES.map((s) => ({
      ...s,
      count: allTasks.filter((t) => t.status === s.id).length,
    }))

    // Last 7 days of completions from completed_at
    const days = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setHours(0, 0, 0, 0)
      d.setDate(d.getDate() - i)
      const key = d.toDateString()
      days.push({
        key,
        label: d.toLocaleDateString(undefined, { weekday: 'narrow' }),
        full: d.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' }),
        count: allTasks.filter((t) => t.completed_at && new Date(t.completed_at).toDateString() === key).length,
      })
    }
    weekly.value = days

    activities.value = await taskStore.fetchRecentActivity(team.currentTeamId)
  } catch (e) {
    loadError.value = e?.message || 'Could not load the dashboard.'
  } finally {
    loading.value = false
  }
}

onMounted(reload)
watch(
  () => team.currentTeamId,
  (id, prev) => {
    if (id && id !== prev) reload()
  }
)
</script>
