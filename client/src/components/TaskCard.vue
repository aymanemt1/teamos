<template>
  <div
    class="bg-cardhover/60 border border-border rounded-xl p-3.5 cursor-grab active:cursor-grabbing hover:border-[#484f58] transition-all hover:-translate-y-0.5 hover:shadow-pop"
    @click="$emit('open', task)"
  >
    <div class="flex items-center gap-2">
      <span
        class="w-2 h-2 rounded-full shrink-0"
        :style="{ backgroundColor: priorityOf(task.priority).color }"
        :title="priorityOf(task.priority).label + ' priority'"
      ></span>
      <span
        v-if="projectKey"
        class="text-[10px] font-bold tracking-wider text-accent bg-accent/10 rounded px-1.5 py-0.5"
      >
        {{ projectKey }}
      </span>
      <span class="ml-auto flex items-center gap-1 text-[11px] font-medium" :class="dueClass">
        <Icon name="calendar" cls="w-3.5 h-3.5" />
        {{ dueLabel }}
      </span>
    </div>

    <h4 class="mt-2 text-sm font-semibold text-gray-100 leading-snug">{{ task.title }}</h4>

    <div v-if="task.tags?.length" class="mt-2 flex flex-wrap gap-1.5">
      <span
        v-for="tag in task.tags"
        :key="tag"
        class="text-[11px] text-muted bg-base border border-border rounded-md px-1.5 py-0.5"
      >
        {{ tag }}
      </span>
    </div>

    <div v-if="subTotal" class="mt-3">
      <div class="flex items-center justify-between text-[11px] text-muted mb-1">
        <span class="flex items-center gap-1"><Icon name="list" cls="w-3.5 h-3.5" /> Subtasks</span>
        <span class="tabular-nums font-semibold">{{ subDone }}/{{ subTotal }}</span>
      </div>
      <div class="h-1.5 rounded-full bg-base overflow-hidden">
        <div
          class="h-full rounded-full bg-accent transition-all duration-500"
          :style="{ width: `${Math.round((subDone / subTotal) * 100)}%` }"
        ></div>
      </div>
    </div>

    <div class="mt-3 flex items-center justify-between">
      <Avatar
        v-if="assignee"
        :name="assignee.name"
        :email="assignee.email"
        :color="assignee.avatar_color"
        size="xs"
        :title="assignee.name || assignee.email"
      />
      <span v-else class="w-6 h-6 rounded-full border border-dashed border-border flex items-center justify-center text-muted">
        <Icon name="users" cls="w-3 h-3" />
      </span>
      <Icon name="grip" cls="w-4 h-4 text-muted/60" />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useTaskStore } from '../stores/tasks.js'
import { priorityOf } from '../lib/meta.js'
import { daysUntil, formatDate } from '../lib/time.js'
import Icon from './Icon.vue'
import Avatar from './Avatar.vue'

const props = defineProps({
  task: { type: Object, required: true },
  projectKey: { type: String, default: '' },
})

defineEmits(['open'])

const tasks = useTaskStore()

const subs = computed(() => tasks.subtasksOf(props.task.id))
const subTotal = computed(() => subs.value.length)
const subDone = computed(() => subs.value.filter((s) => s.done).length)
const assignee = computed(() => tasks.profileOf(props.task.assignee_id))

const dueInfo = computed(() => {
  if (!props.task.due_date) return null
  const d = daysUntil(props.task.due_date)
  if (d === null) return null
  if (props.task.status === 'done') return { label: formatDate(props.task.due_date), cls: 'text-muted' }
  if (d < 0) return { label: `${Math.abs(d)}d overdue`, cls: 'text-[#ff7b72]' }
  if (d === 0) return { label: 'Due today', cls: 'text-[#f0b45e]' }
  if (d < 3) return { label: `Due in ${d}d`, cls: 'text-[#f0b45e]' }
  return { label: formatDate(props.task.due_date), cls: 'text-muted' }
})
const dueLabel = computed(() => dueInfo.value?.label ?? '')
const dueClass = computed(() => dueInfo.value?.cls ?? 'text-muted')
</script>
