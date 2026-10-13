<template>
  <div class="p-4 sm:p-6 lg:p-8 max-w-[1600px] mx-auto h-[calc(100vh-0px)] flex flex-col">
    <!-- header -->
    <div class="flex flex-wrap items-center gap-3 mb-5 anim-fade-up shrink-0">
      <div>
        <h1 class="text-2xl font-extrabold tracking-tight text-white">Board</h1>
        <p class="text-sm text-muted mt-1">Drag cards between columns — everything saves live.</p>
      </div>
      <div class="ml-auto flex items-center gap-3">
        <div class="relative">
          <select
            v-model="selectedProjectId"
            class="field appearance-none pr-9 !py-2 text-sm font-semibold cursor-pointer min-w-[180px]"
            aria-label="Select project"
          >
            <option v-for="p in projectStore.active" :key="p.id" :value="p.id">
              {{ p.key }} — {{ p.name }}
            </option>
          </select>
          <Icon name="chevronDown" cls="w-4 h-4 text-muted absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
        </div>
        <button class="btn-primary" @click="openCreate('backlog')">
          <Icon name="plus" cls="w-4 h-4" /> New task
        </button>
      </div>
    </div>

    <!-- board -->
    <div v-if="loading" class="flex gap-4 flex-1 overflow-hidden">
      <Skeleton v-for="i in 4" :key="i" cls="flex-1 min-w-[260px] h-full" />
    </div>

    <div v-else-if="loadError" role="alert">
      <EmptyState icon="alert" title="Couldn't load the board" :subtitle="loadError">
        <button type="button" class="btn-primary" @click="load">Try again</button>
      </EmptyState>
    </div>

    <EmptyState
      v-else-if="!team.currentTeamId"
      icon="users"
      title="No team yet"
      subtitle="You're not on a team yet. An admin creates teams and adds members in the Supabase dashboard."
    />

    <EmptyState
      v-else-if="!projectStore.active.length"
      icon="folder"
      title="No active projects"
      subtitle="Create a project first, then tasks will live on this board."
    >
      <router-link to="/projects" class="btn-primary"><Icon name="plus" cls="w-4 h-4" /> Go to projects</router-link>
    </EmptyState>

    <div v-else class="flex gap-4 flex-1 min-h-0 overflow-x-auto pb-2 -mx-1 px-1">
      <section
        v-for="s in STATUSES"
        :key="s.id"
        class="flex-1 min-w-[270px] max-w-[380px] flex flex-col bg-base/60 border border-border rounded-2xl overflow-hidden anim-fade-up"
      >
        <header class="flex items-center gap-2 px-4 py-3 border-b border-border shrink-0">
          <span class="w-2.5 h-2.5 rounded-full" :style="{ backgroundColor: s.color }"></span>
          <h2 class="font-bold text-sm text-gray-200">{{ s.label }}</h2>
          <span class="text-xs text-muted bg-card border border-border rounded-full px-2 py-0.5 tabular-nums">
            {{ columns[s.id].length }}
          </span>
          <button
            class="ml-auto text-muted hover:text-accent transition-colors"
            @click="openCreate(s.id)"
            :aria-label="`Add task to ${s.label}`"
          >
            <Icon name="plus" cls="w-4 h-4" />
          </button>
        </header>

        <div
          :ref="(el) => (colEls[s.id] = el)"
          class="flex-1 overflow-y-auto p-3 space-y-2.5 min-h-[120px] transition-colors"
          :class="{ 'bg-accent/5': dropTarget.status === s.id }"
          @dragover.prevent="onDragOver($event, s.id)"
          @dragleave="onDragLeave(s.id)"
          @drop="onDrop($event, s.id)"
        >
          <template v-for="(task, i) in columns[s.id]" :key="task.id">
            <div
              v-if="dropTarget.status === s.id && dropTarget.index === i"
              class="drop-indicator"
            ></div>
            <div
              :data-task-id="task.id"
              draggable="true"
              @dragstart="onDragStart($event, task)"
              @dragend="onDragEnd"
              :class="{ 'dragging-card': draggedId === task.id }"
            >
              <TaskCard :task="task" :projectKey="currentProject?.key" @open="drawerTaskId = $event.id" />
            </div>
          </template>
          <div
            v-if="dropTarget.status === s.id && dropTarget.index === columns[s.id].length"
            class="drop-indicator"
          ></div>
          <p v-if="!columns[s.id].length && !draggedId" class="text-xs text-muted text-center py-6">
            No tasks yet
          </p>
        </div>
      </section>
    </div>

    <TaskModal
      :open="showModal"
      :projectId="selectedProjectId"
      :status="modalStatus"
      @close="showModal = false"
      @created="onTaskCreated"
    />
    <TaskDrawer :taskId="drawerTaskId" @close="drawerTaskId = null" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useTeamStore } from '../stores/team.js'
import { useProjectStore } from '../stores/projects.js'
import { useTaskStore } from '../stores/tasks.js'
import { STATUSES } from '../lib/meta.js'
import TaskCard from '../components/TaskCard.vue'
import TaskModal from '../components/TaskModal.vue'
import TaskDrawer from '../components/TaskDrawer.vue'
import Icon from '../components/Icon.vue'
import Skeleton from '../components/Skeleton.vue'
import EmptyState from '../components/EmptyState.vue'

const team = useTeamStore()
const projectStore = useProjectStore()
const taskStore = useTaskStore()

const loading = ref(true)
const loadError = ref('')
const selectedProjectId = ref('')
const showModal = ref(false)
const modalStatus = ref('backlog')
const drawerTaskId = ref(null)

const draggedId = ref(null)
const dropTarget = ref({ status: null, index: null })
const colEls = {}

const columns = computed(() => {
  const cols = {}
  for (const s of STATUSES) cols[s.id] = taskStore.byStatus(s.id)
  return cols
})
const currentProject = computed(() => projectStore.byId(selectedProjectId.value))

async function load() {
  loading.value = true
  loadError.value = ''
  try {
    await team.fetchTeams()
    if (!team.currentTeamId) return
    await projectStore.fetchProjects(team.currentTeamId)
    if (!projectStore.active.some((p) => p.id === selectedProjectId.value)) {
      selectedProjectId.value = projectStore.active[0]?.id ?? ''
    }
    if (selectedProjectId.value) await loadProject(selectedProjectId.value)
  } catch (e) {
    loadError.value = e?.message || 'Could not load the board.'
  } finally {
    loading.value = false
  }
}

async function loadProject(pid) {
  await taskStore.fetchTasks(pid)
  // Preload subtasks so cards can render progress bars.
  await Promise.all(taskStore.tasks.map((t) => taskStore.fetchSubtasks(t.id)))
}

function openCreate(status) {
  modalStatus.value = status
  showModal.value = true
}

async function onTaskCreated(task) {
  await taskStore.fetchSubtasks(task.id)
}

// ---------- drag and drop ----------
function onDragStart(e, task) {
  draggedId.value = task.id
  e.dataTransfer.effectAllowed = 'move'
  try {
    e.dataTransfer.setData('text/plain', task.id)
  } catch (_) {}
}

function onDragEnd() {
  draggedId.value = null
  dropTarget.value = { status: null, index: null }
}

function insertionIndex(e, status) {
  const el = colEls[status]
  if (!el) return columns.value[status].length
  const cards = [...el.querySelectorAll('[data-task-id]')].filter(
    (c) => c.dataset.taskId !== draggedId.value
  )
  for (let i = 0; i < cards.length; i++) {
    const r = cards[i].getBoundingClientRect()
    if (e.clientY < r.top + r.height / 2) return i
  }
  return cards.length
}

function onDragOver(e, status) {
  if (!draggedId.value) return
  dropTarget.value = { status, index: insertionIndex(e, status) }
}

function onDragLeave(status) {
  if (dropTarget.value.status === status) dropTarget.value = { status: null, index: null }
}

async function onDrop(e, status) {
  e.preventDefault()
  const id = draggedId.value
  draggedId.value = null
  const target = dropTarget.value
  dropTarget.value = { status: null, index: null }
  if (!id) return

  const index = target.status === status ? target.index : columns.value[status].length
  const next = {}
  for (const s of STATUSES) next[s.id] = columns.value[s.id].map((t) => t.id)
  for (const s of STATUSES) next[s.id] = next[s.id].filter((tid) => tid !== id)
  const clamped = Math.max(0, Math.min(index ?? next[status].length, next[status].length))
  next[status].splice(clamped, 0, id)

  await taskStore.applyOrder(next)
}

watch(selectedProjectId, (pid) => {
  if (pid) loadProject(pid)
})
watch(
  () => team.currentTeamId,
  (id, prev) => {
    if (id && id !== prev) {
      selectedProjectId.value = ''
      load()
    }
  }
)

onMounted(load)
onUnmounted(() => taskStore.unsubscribe())
</script>
