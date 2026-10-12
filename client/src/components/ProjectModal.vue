<template>
  <teleport to="body">
    <div v-if="open" class="fixed inset-0 z-[80] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/70 backdrop-blur-sm" @click="close"></div>
      <div class="anim-pop relative bg-card border border-border rounded-2xl w-full max-w-md shadow-pop">
        <div class="flex items-center justify-between p-5 border-b border-border">
          <h3 class="font-bold text-lg text-white">{{ editing ? 'Edit project' : 'New project' }}</h3>
          <button class="text-muted hover:text-white transition-colors" @click="close" aria-label="Close">
            <Icon name="x" cls="w-5 h-5" />
          </button>
        </div>

        <form @submit.prevent="submit" class="p-5 space-y-4">
          <div>
            <label class="label">Name</label>
            <input v-model="form.name" class="field" placeholder="Website redesign" required maxlength="120" />
          </div>

          <div>
            <label class="label">Key <span class="normal-case font-normal">(short tag shown on cards)</span></label>
            <input
              v-model="form.key"
              class="field uppercase"
              placeholder="WEB"
              required
              maxlength="8"
              pattern="[A-Za-z0-9]+"
              title="Letters and numbers only"
            />
          </div>

          <div>
            <label class="label">Description</label>
            <textarea v-model="form.description" class="field" rows="3" placeholder="What is this project about?"></textarea>
          </div>

          <div>
            <label class="label">Color</label>
            <div class="flex items-center gap-2 flex-wrap">
              <button
                v-for="c in PROJECT_COLORS"
                :key="c"
                type="button"
                class="w-8 h-8 rounded-full transition-transform hover:scale-110"
                :class="form.color === c ? 'ring-2 ring-white ring-offset-2 ring-offset-card' : ''"
                :style="{ backgroundColor: c }"
                @click="form.color = c"
                :aria-label="`Pick color ${c}`"
              ></button>
              <input v-model="form.color" type="color" class="w-8 h-8 rounded-full bg-transparent cursor-pointer" />
            </div>
          </div>

          <p v-if="error" class="text-sm text-[#ff7b72] bg-[#f85149]/10 border border-[#f85149]/30 rounded-lg px-3 py-2">
            {{ error }}
          </p>

          <div class="flex justify-end gap-2 pt-2">
            <button type="button" class="btn-ghost" @click="close">Cancel</button>
            <button type="submit" class="btn-primary" :disabled="saving">
              {{ saving ? 'Saving...' : editing ? 'Save changes' : 'Create project' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { reactive, ref, computed, watch } from 'vue'
import { useProjectStore } from '../stores/projects.js'
import { useTeamStore } from '../stores/team.js'
import { PROJECT_COLORS } from '../lib/meta.js'
import { toast } from '../lib/toast.js'
import Icon from './Icon.vue'

const props = defineProps({
  open: { type: Boolean, default: false },
  project: { type: Object, default: null },
})

const emit = defineEmits(['close', 'saved'])

const projects = useProjectStore()
const team = useTeamStore()

const editing = computed(() => !!props.project)
const form = reactive({ name: '', key: '', description: '', color: PROJECT_COLORS[0] })
const error = ref('')
const saving = ref(false)

watch(
  () => props.open,
  (v) => {
    if (!v) return
    error.value = ''
    if (props.project) {
      form.name = props.project.name ?? ''
      form.key = props.project.key ?? ''
      form.description = props.project.description ?? ''
      form.color = props.project.color ?? PROJECT_COLORS[0]
    } else {
      form.name = ''
      form.key = ''
      form.description = ''
      form.color = PROJECT_COLORS[0]
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
    const payload = {
      name: form.name.trim(),
      key: form.key.trim().toUpperCase(),
      description: form.description.trim() || null,
      color: form.color,
    }
    if (editing.value) {
      await projects.updateProject(props.project.id, payload)
      toast.success('Project updated')
    } else {
      await projects.createProject(team.currentTeamId, payload)
      toast.success('Project created')
    }
    emit('saved')
    close()
  } catch (e) {
    error.value = e.message || 'Could not save the project.'
  } finally {
    saving.value = false
  }
}
</script>
