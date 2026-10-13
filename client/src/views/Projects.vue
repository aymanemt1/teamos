<template>
  <div class="p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto">
    <div class="flex flex-wrap items-center gap-3 mb-6 anim-fade-up">
      <div>
        <h1 class="text-2xl font-extrabold tracking-tight text-white">Projects</h1>
        <p class="text-sm text-muted mt-1">{{ projectStore.projects.length }} project(s) in this team</p>
      </div>
      <button class="btn-primary ml-auto" @click="openCreate">
        <Icon name="plus" cls="w-4 h-4" /> New project
      </button>
    </div>

    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
      <Skeleton v-for="i in 6" :key="i" cls="h-44" />
    </div>

    <EmptyState
      v-else-if="!projectStore.projects.length"
      icon="folder"
      title="No projects yet"
      subtitle="Create your first project to start organizing work."
    >
      <button class="btn-primary" @click="openCreate"><Icon name="plus" cls="w-4 h-4" /> New project</button>
    </EmptyState>

    <div v-else class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
      <article
        v-for="(p, i) in projectStore.projects"
        :key="p.id"
        class="anim-fade-up bg-card border border-border rounded-2xl overflow-hidden hover:border-[#3d444d] transition-colors group"
        :class="`stagger-${(i % 4) + 1}`"
      >
        <div class="h-1.5" :style="{ backgroundColor: p.color || '#7c6cf0' }"></div>
        <div class="p-5">
          <div class="flex items-center gap-2">
            <span
              class="text-[11px] font-bold tracking-wider rounded px-1.5 py-0.5"
              :style="{ color: p.color || '#7c6cf0', backgroundColor: (p.color || '#7c6cf0') + '1a' }"
            >
              {{ p.key }}
            </span>
            <span
              class="text-[11px] font-semibold rounded-full px-2 py-0.5"
              :class="p.status === 'active' ? 'bg-[#3fb950]/15 text-[#3fb950]' : 'bg-muted/15 text-muted'"
            >
              {{ p.status === 'active' ? 'Active' : 'Archived' }}
            </span>
            <div class="ml-auto flex items-center gap-1 opacity-100 transition-opacity min-[900px]:opacity-0 min-[900px]:group-hover:opacity-100 min-[900px]:group-focus-within:opacity-100">
              <button type="button" class="p-1.5 text-muted hover:text-white rounded-lg hover:bg-base focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent" @click="openEdit(p)" aria-label="Edit project">
                <Icon name="pencil" cls="w-4 h-4" />
              </button>
              <button
                type="button"
                class="p-1.5 text-muted hover:text-white rounded-lg hover:bg-base focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
                @click="toggleArchive(p)"
                :aria-label="p.status === 'active' ? 'Archive project' : 'Restore project'"
                :title="p.status === 'active' ? 'Archive' : 'Restore'"
              >
                <Icon name="archive" cls="w-4 h-4" />
              </button>
              <button type="button" class="p-1.5 text-muted hover:text-[#ff7b72] rounded-lg hover:bg-base focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent" @click="askDelete(p)" aria-label="Delete project">
                <Icon name="trash" cls="w-4 h-4" />
              </button>
            </div>
          </div>

          <h3 class="mt-3 font-bold text-white text-lg leading-snug">{{ p.name }}</h3>
          <p class="mt-1 text-sm text-muted line-clamp-2 min-h-[2.5rem]">{{ p.description || 'No description' }}</p>

          <div class="mt-4">
            <div class="flex items-center justify-between text-xs text-muted mb-1.5">
              <span>{{ counts[p.id]?.done ?? 0 }} of {{ counts[p.id]?.total ?? 0 }} tasks done</span>
              <span class="tabular-nums font-semibold">{{ pct(p.id) }}%</span>
            </div>
            <div class="h-1.5 rounded-full bg-base overflow-hidden">
              <div
                class="h-full rounded-full transition-all duration-500"
                :style="{ width: `${pct(p.id)}%`, backgroundColor: p.color || '#7c6cf0' }"
              ></div>
            </div>
          </div>

          <router-link
            to="/board"
            class="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-accent hover:underline"
          >
            Open board <Icon name="arrowRight" cls="w-4 h-4" />
          </router-link>
        </div>
      </article>
    </div>

    <ProjectModal :open="modalOpen" :project="editing" @close="modalOpen = false" @saved="loadCounts" />
    <ConfirmModal
      :open="confirmOpen"
      title="Delete project?"
      :message="`“${toDelete?.name}” and all of its tasks will be permanently removed.`"
      confirm-label="Delete project"
      @confirm="doDelete"
      @cancel="confirmOpen = false"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useTeamStore } from '../stores/team.js'
import { useProjectStore } from '../stores/projects.js'
import { useTaskStore } from '../stores/tasks.js'
import { toast } from '../lib/toast.js'
import ProjectModal from '../components/ProjectModal.vue'
import ConfirmModal from '../components/ConfirmModal.vue'
import Skeleton from '../components/Skeleton.vue'
import EmptyState from '../components/EmptyState.vue'
import Icon from '../components/Icon.vue'

const team = useTeamStore()
const projectStore = useProjectStore()
const taskStore = useTaskStore()

const loading = ref(true)
const modalOpen = ref(false)
const editing = ref(null)
const confirmOpen = ref(false)
const toDelete = ref(null)
const counts = ref({})

function pct(pid) {
  const c = counts.value[pid]
  if (!c || !c.total) return 0
  return Math.round((c.done / c.total) * 100)
}

async function loadCounts() {
  const ids = projectStore.projects.map((p) => p.id)
  const all = await taskStore.fetchTeamTasks(ids)
  const map = {}
  for (const t of all) {
    map[t.project_id] ??= { total: 0, done: 0 }
    map[t.project_id].total++
    if (t.status === 'done') map[t.project_id].done++
  }
  counts.value = map
}

async function load() {
  loading.value = true
  try {
    await team.fetchTeams()
    if (!team.currentTeamId) return
    await projectStore.fetchProjects(team.currentTeamId)
    await loadCounts()
  } finally {
    loading.value = false
  }
}

function openCreate() {
  editing.value = null
  modalOpen.value = true
}
function openEdit(p) {
  editing.value = p
  modalOpen.value = true
}

async function toggleArchive(p) {
  try {
    await projectStore.updateProject(p.id, { status: p.status === 'active' ? 'archived' : 'active' })
    toast.success(p.status === 'active' ? 'Project archived' : 'Project restored')
  } catch (e) {
    toast.error(e.message || 'Could not update the project.')
  }
}

function askDelete(p) {
  toDelete.value = p
  confirmOpen.value = true
}

async function doDelete() {
  confirmOpen.value = false
  try {
    await projectStore.deleteProject(toDelete.value.id)
    toast.success('Project deleted')
    await loadCounts()
  } catch (e) {
    toast.error(e.message || 'Could not delete the project.')
  } finally {
    toDelete.value = null
  }
}

onMounted(load)
watch(
  () => team.currentTeamId,
  (id, prev) => {
    if (id && id !== prev) load()
  }
)
</script>
