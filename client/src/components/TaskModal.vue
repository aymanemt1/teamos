<template>
  <teleport to="body">
    <div v-if="open" class="fixed inset-0 z-[80] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/70 backdrop-blur-sm" @click="close"></div>
      <div class="anim-pop relative bg-card border border-border rounded-2xl w-full max-w-lg shadow-pop max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between p-5 border-b border-border sticky top-0 bg-card z-10">
          <h3 class="font-bold text-lg text-white">New task</h3>
          <button class="text-muted hover:text-white transition-colors" @click="close" aria-label="Close">
            <Icon name="x" cls="w-5 h-5" />
          </button>
        </div>

        <form @submit.prevent="submit" class="p-5 space-y-4">
          <div>
            <label class="label">Title</label>
            <input v-model="form.title" class="field" placeholder="What needs to be done?" required maxlength="200" />
          </div>

          <div>
            <label class="label">Description</label>
            <textarea v-model="form.description" class="field" rows="3" placeholder="Add more detail..."></textarea>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">Project</label>
              <select v-model="form.project_id" class="field" required>
                <option v-for="p in projects.active" :key="p.id" :value="p.id">{{ p.name }}</option>
              </select>
            </div>
            <div>
              <label class="label">Column</label>
              <select v-model="form.status" class="field">
                <option v-for="s in STATUSES" :key="s.id" :value="s.id">{{ s.label }}</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">Priority</label>
              <select v-model="form.priority" class="field">
                <option v-for="p in PRIORITIES" :key="p.id" :value="p.id">{{ p.label }}</option>
              </select>
            </div>
            <div>
              <label class="label">Due date</label>
              <input v-model="form.due_date" type="date" class="field" />
            </div>
          </div>

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
            <label class="label">Tags <span class="normal-case font-normal">(comma separated)</span></label>
            <input v-model="tagsInput" class="field" placeholder="design, urgent, backend" />
          </div>

          <p v-if="error" class="text-sm text-[#ff7b72] bg-[#f85149]/10 border border-[#f85149]/30 rounded-lg px-3 py-2">
            {{ error }}
          </p>

          <div class="flex justify-end gap-2 pt-2">
            <button type="button" class="btn-ghost" @click="close">Cancel</button>
            <button type="submit" class="btn-primary" :disabled="saving">
              {{ saving ? 'Creating...' : 'Create task' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { reactive, ref, watch } from 'vue'
import { useTaskStore } from '../stores/tasks.js'
import { useProjectStore } from '../stores/projects.js'
import { useTeamStore } from '../stores/team.js'
import { STATUSES, PRIORITIES } from '../lib/meta.js'
import { toast } from '../lib/toast.js'
import Icon from './Icon.vue'

const props = defineProps({
  open: { type: Boolean, default: false },
  projectId: { type: String, default: '' },
  status: { type: String, default: 'backlog' },
})

const emit = defineEmits(['close', 'created'])

const tasks = useTaskStore()
const projects = useProjectStore()
const team = useTeamStore()

const form = reactive({
  title: '',
  description: '',
  project_id: '',
  status: 'backlog',
  priority: 'medium',
  assignee_id: '',
  due_date: '',
})
const tagsInput = ref('')
const error = ref('')
const saving = ref(false)

watch(
  () => props.open,
  (v) => {
    if (v) {
      form.title = ''
      form.description = ''
      form.project_id = props.projectId || projects.active[0]?.id || ''
      form.status = props.status
      form.priority = 'medium'
      form.assignee_id = ''
      form.due_date = ''
      tagsInput.value = ''
      error.value = ''
    }
  }
)

function close() {
  emit('close')
}

async function submit() {
  error.value = ''
  saving.value = true
  try {
    const tags = tagsInput.value
      .split(',')
      .map((t) => t.trim())
      .filter(Boolean)
      .slice(0, 10)
    const task = await tasks.createTask({
      project_id: form.project_id,
      title: form.title.trim(),
      description: form.description.trim(),
      status: form.status,
      priority: form.priority,
      assignee_id: form.assignee_id || null,
      due_date: form.due_date || null,
      tags,
    })
    toast.success('Task created')
    emit('created', task)
    close()
  } catch (e) {
    error.value = e.message || 'Could not create the task.'
  } finally {
    saving.value = false
  }
}
</script>
