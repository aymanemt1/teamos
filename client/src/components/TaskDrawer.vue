<template>
  <teleport to="body">
    <div v-if="taskId" class="fixed inset-0 z-[80]">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="close"></div>
      <aside
        class="anim-drawer absolute right-0 top-0 h-full w-full max-w-md bg-card border-l border-border shadow-pop flex flex-col"
      >
        <div v-if="task" class="flex-1 overflow-y-auto">
          <!-- header -->
          <div class="flex items-start justify-between p-5 border-b border-border sticky top-0 bg-card z-10">
            <div class="min-w-0">
              <div class="flex items-center gap-2 text-xs">
                <span
                  v-if="project"
                  class="font-bold tracking-wider text-accent bg-accent/10 rounded px-1.5 py-0.5"
                >
                  {{ project.key }}
                </span>
                <span class="text-muted">{{ statusOf(task.status).label }}</span>
              </div>
              <input
                v-model="form.title"
                class="mt-2 w-full bg-transparent text-lg font-bold text-white outline-none border-b border-transparent focus:border-accent transition-colors"
                maxlength="200"
              />
            </div>
            <button class="text-muted hover:text-white transition-colors ml-3 shrink-0" @click="close" aria-label="Close">
              <Icon name="x" cls="w-5 h-5" />
            </button>
          </div>

          <div class="p-5 space-y-5">
            <!-- fields -->
            <div>
              <label class="label">Description</label>
              <textarea v-model="form.description" class="field" rows="3" placeholder="Add more detail..."></textarea>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="label">Status</label>
                <select v-model="form.status" class="field">
                  <option v-for="s in STATUSES" :key="s.id" :value="s.id">{{ s.label }}</option>
                </select>
              </div>
              <div>
                <label class="label">Priority</label>
                <select v-model="form.priority" class="field">
                  <option v-for="p in PRIORITIES" :key="p.id" :value="p.id">{{ p.label }}</option>
                </select>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="label">Assignee</label>
                <select v-model="form.assignee_id" class="field">
                  <option value="">Unassigned</option>
                  <option v-for="m in team.members" :key="m.user_id" :value="m.user_id">
                    {{ m.profile?.name || m.profile?.email || 'Unknown' }}
                  </option>
                </select>
              </div>
              <div>
                <label class="label">Due date</label>
                <input v-model="form.due_date" type="date" class="field" />
              </div>
            </div>

            <div>
              <label class="label">Tags <span class="normal-case font-normal">(comma separated)</span></label>
              <input v-model="tagsInput" class="field" placeholder="design, urgent, backend" />
            </div>

            <button class="btn-primary w-full" :disabled="saving" @click="save">
              {{ saving ? 'Saving...' : 'Save changes' }}
            </button>

            <!-- subtasks -->
            <div class="bg-base border border-border rounded-xl p-4">
              <div class="flex items-center justify-between mb-3">
                <h4 class="font-semibold text-sm text-gray-200 flex items-center gap-2">
                  <Icon name="list" cls="w-4 h-4 text-muted" /> Subtasks
                </h4>
                <span class="text-xs text-muted tabular-nums">{{ subDone }}/{{ subtasks.length }}</span>
              </div>
              <div class="h-1.5 rounded-full bg-card overflow-hidden mb-3">
                <div
                  class="h-full rounded-full bg-accent transition-all duration-500"
                  :style="{ width: subtasks.length ? `${Math.round((subDone / subtasks.length) * 100)}%` : '0%' }"
                ></div>
              </div>
              <ul class="space-y-1.5">
                <li
                  v-for="s in subtasks"
                  :key="s.id"
                  class="flex items-center gap-2.5 group rounded-lg px-2 py-1.5 hover:bg-card focus-within:bg-card transition-colors"
                >
                  <button
                    type="button"
                    @click="toggleSub(s)"
                    class="w-5 h-5 rounded-md border flex items-center justify-center shrink-0 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
                    :class="s.done ? 'bg-accent border-accent text-white' : 'border-border text-transparent hover:border-accent'"
                    :aria-label="s.done ? 'Mark not done' : 'Mark done'"
                  >
                    <Icon name="check" cls="w-3.5 h-3.5" :stroke-width="3" />
                  </button>
                  <span class="flex-1 text-sm" :class="s.done ? 'line-through text-muted' : 'text-gray-200'">
                    {{ s.title }}
                  </span>
                  <button
                    type="button"
                    @click="removeSub(s.id)"
                    class="text-muted hover:text-[#ff7b72] rounded opacity-100 transition-all min-[900px]:opacity-0 min-[900px]:group-hover:opacity-100 min-[900px]:group-focus-within:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
                    aria-label="Delete subtask"
                  >
                    <Icon name="trash" cls="w-4 h-4" />
                  </button>
                </li>
              </ul>
              <form @submit.prevent="addSub" class="flex gap-2 mt-3">
                <input v-model="newSub" class="field !py-2 text-sm" placeholder="Add a subtask..." maxlength="160" />
                <button type="submit" class="btn-ghost !py-2 shrink-0" :disabled="!newSub.trim()">
                  <Icon name="plus" cls="w-4 h-4" />
                </button>
              </form>
            </div>

            <!-- comments -->
            <div class="bg-base border border-border rounded-xl p-4">
              <h4 class="font-semibold text-sm text-gray-200 flex items-center gap-2 mb-3">
                <Icon name="chat" cls="w-4 h-4 text-muted" /> Comments
                <span class="text-xs text-muted font-normal">({{ comments.length }})</span>
              </h4>
              <ul class="space-y-3 max-h-64 overflow-y-auto">
                <li v-for="c in comments" :key="c.id" class="flex gap-2.5">
                  <Avatar
                    :name="tasks.profileOf(c.user_id)?.name"
                    :email="tasks.profileOf(c.user_id)?.email"
                    :color="tasks.profileOf(c.user_id)?.avatar_color || '#30363d'"
                    size="xs"
                  />
                  <div class="flex-1 min-w-0 bg-card border border-border rounded-lg px-3 py-2">
                    <div class="flex items-baseline justify-between gap-2">
                      <span class="text-xs font-semibold text-gray-200 truncate">
                        {{ tasks.profileOf(c.user_id)?.name || tasks.profileOf(c.user_id)?.email || 'Unknown' }}
                      </span>
                      <span class="text-[11px] text-muted shrink-0">{{ timeAgo(c.created_at) }}</span>
                    </div>
                    <p class="text-sm text-gray-300 mt-1 whitespace-pre-wrap break-words">{{ c.body }}</p>
                  </div>
                </li>
                <li v-if="!comments.length" class="text-sm text-muted">No comments yet</li>
              </ul>
              <form @submit.prevent="addComment" class="flex gap-2 mt-3">
                <input v-model="newComment" class="field !py-2 text-sm" placeholder="Write a comment..." maxlength="2000" />
                <button type="submit" class="btn-primary !py-2 shrink-0" :disabled="!newComment.trim() || commenting">
                  Post
                </button>
              </form>
            </div>

            <!-- danger zone -->
            <div class="pt-1">
              <button class="btn-danger w-full" @click="confirmOpen = true">
                <Icon name="trash" cls="w-4 h-4" /> Delete task
              </button>
              <p class="text-[11px] text-muted text-center mt-2">
                Created {{ timeAgo(task.created_at) }}
                <span v-if="task.completed_at"> · Completed {{ timeAgo(task.completed_at) }}</span>
              </p>
            </div>
          </div>
        </div>

        <div v-else class="flex-1 flex items-center justify-center">
          <p class="text-muted text-sm">Loading task...</p>
        </div>
      </aside>
    </div>

    <ConfirmModal
      :open="confirmOpen"
      title="Delete task?"
      :message="`“${task?.title}” and its subtasks and comments will be permanently removed.`"
      confirm-label="Delete task"
      @confirm="doDelete"
      @cancel="confirmOpen = false"
    />
  </teleport>
</template>

<script setup>
import { reactive, ref, computed, watch } from 'vue'
import { useTaskStore } from '../stores/tasks.js'
import { useProjectStore } from '../stores/projects.js'
import { useTeamStore } from '../stores/team.js'
import { STATUSES, PRIORITIES, statusOf } from '../lib/meta.js'
import { timeAgo } from '../lib/time.js'
import { toast } from '../lib/toast.js'
import Icon from './Icon.vue'
import Avatar from './Avatar.vue'
import ConfirmModal from './ConfirmModal.vue'

const props = defineProps({
  taskId: { type: String, default: null },
})

const emit = defineEmits(['close'])

const tasks = useTaskStore()
const projects = useProjectStore()
const team = useTeamStore()

const task = computed(() => tasks.tasks.find((t) => t.id === props.taskId) ?? null)
const project = computed(() => (task.value ? projects.byId(task.value.project_id) : null))
const subtasks = computed(() => tasks.subtasksOf(props.taskId))
const comments = computed(() => tasks.commentsOf(props.taskId))
const subDone = computed(() => subtasks.value.filter((s) => s.done).length)

const form = reactive({ title: '', description: '', status: 'backlog', priority: 'medium', assignee_id: '', due_date: '' })
const tagsInput = ref('')
const saving = ref(false)
const newSub = ref('')
const newComment = ref('')
const commenting = ref(false)
const confirmOpen = ref(false)

watch(
  () => props.taskId,
  async (id) => {
    if (!id) return
    await Promise.all([tasks.fetchSubtasks(id), tasks.fetchComments(id)])
    syncForm()
  },
  { immediate: true }
)

function syncForm() {
  if (!task.value) return
  form.title = task.value.title ?? ''
  form.description = task.value.description ?? ''
  form.status = task.value.status ?? 'backlog'
  form.priority = task.value.priority ?? 'medium'
  form.assignee_id = task.value.assignee_id ?? ''
  form.due_date = task.value.due_date ?? ''
  tagsInput.value = (task.value.tags ?? []).join(', ')
}

function close() {
  emit('close')
}

async function save() {
  if (!task.value) return
  saving.value = true
  try {
    const tags = tagsInput.value.split(',').map((t) => t.trim()).filter(Boolean).slice(0, 10)
    const patch = {
      title: form.title.trim(),
      description: form.description.trim() || null,
      status: form.status,
      priority: form.priority,
      assignee_id: form.assignee_id || null,
      due_date: form.due_date || null,
      tags,
    }
    if (form.status === 'done' && task.value.status !== 'done') patch.completed_at = new Date().toISOString()
    if (form.status !== 'done' && task.value.status === 'done') patch.completed_at = null
    await tasks.updateTask(task.value.id, patch)
    toast.success('Task updated')
  } catch (e) {
    toast.error(e.message || 'Could not save the task.')
  } finally {
    saving.value = false
  }
}

async function addSub() {
  const title = newSub.value.trim()
  if (!title || !props.taskId) return
  try {
    await tasks.addSubtask(props.taskId, title)
    newSub.value = ''
  } catch (e) {
    toast.error(e.message || 'Could not add subtask.')
  }
}

async function toggleSub(s) {
  try {
    await tasks.toggleSubtask(props.taskId, s.id, !s.done)
  } catch (e) {
    toast.error(e.message || 'Could not update subtask.')
  }
}

async function removeSub(id) {
  try {
    await tasks.deleteSubtask(props.taskId, id)
  } catch (e) {
    toast.error(e.message || 'Could not delete subtask.')
  }
}

async function addComment() {
  const body = newComment.value.trim()
  if (!body || !props.taskId) return
  commenting.value = true
  try {
    await tasks.addComment(props.taskId, body)
    newComment.value = ''
  } catch (e) {
    toast.error(e.message || 'Could not post comment.')
  } finally {
    commenting.value = false
  }
}

async function doDelete() {
  confirmOpen.value = false
  try {
    await tasks.deleteTask(props.taskId)
    toast.success('Task deleted')
    close()
  } catch (e) {
    toast.error(e.message || 'Could not delete the task.')
  }
}
</script>
