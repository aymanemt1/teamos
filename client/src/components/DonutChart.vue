<template>
  <div class="flex items-center gap-6">
    <div class="relative shrink-0">
      <svg width="132" height="132" viewBox="0 0 132 132">
        <circle cx="66" cy="66" r="54" fill="none" stroke="#21262d" stroke-width="14" />
        <circle
          v-for="(seg, i) in segments"
          :key="seg.id"
          cx="66"
          cy="66"
          r="54"
          fill="none"
          :stroke="seg.color"
          stroke-width="14"
          :stroke-dasharray="`${seg.len} ${CIRC - seg.len}`"
          :stroke-dashoffset="-seg.offset"
          stroke-linecap="butt"
          transform="rotate(-90 66 66)"
          class="transition-all duration-700"
        />
      </svg>
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <span class="text-2xl font-extrabold text-white tabular-nums">{{ total }}</span>
        <span class="text-xs text-muted">tasks</span>
      </div>
    </div>
    <div class="flex-1 space-y-2.5 min-w-0">
      <div v-for="s in items" :key="s.id" class="flex items-center gap-2 text-sm">
        <span class="w-2.5 h-2.5 rounded-full shrink-0" :style="{ backgroundColor: s.color }"></span>
        <span class="text-gray-300 flex-1 truncate">{{ s.label }}</span>
        <span class="text-muted font-semibold tabular-nums">{{ s.count }}</span>
      </div>
      <p v-if="!total" class="text-sm text-muted">No tasks yet</p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  items: { type: Array, default: () => [] }, // [{id,label,count,color}]
})

const CIRC = 2 * Math.PI * 54
const total = computed(() => props.items.reduce((n, s) => n + s.count, 0))

const segments = computed(() => {
  const t = total.value
  let acc = 0
  return props.items.map((s) => {
    const len = t ? (s.count / t) * CIRC : 0
    const seg = { ...s, len, offset: acc }
    acc += len
    return seg
  })
})
</script>
