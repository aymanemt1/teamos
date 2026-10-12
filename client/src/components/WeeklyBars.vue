<template>
  <div>
    <div class="flex items-end justify-between gap-2 h-36">
      <div v-for="d in days" :key="d.key" class="flex-1 flex flex-col items-center gap-2 h-full justify-end">
        <span class="text-[11px] font-semibold text-muted tabular-nums">{{ d.count }}</span>
        <div
          class="w-full max-w-[36px] rounded-t-md transition-all duration-700"
          :style="{
            height: barHeight(d.count),
            background: d.count
              ? 'linear-gradient(180deg, #9d8ffb 0%, #7c6cf0 100%)'
              : '#21262d',
          }"
          :title="`${d.count} completed on ${d.full}`"
        ></div>
        <span class="text-[11px] text-muted font-medium">{{ d.label }}</span>
      </div>
    </div>
    <p v-if="!max" class="text-sm text-muted mt-3">No completions in the last 7 days</p>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  days: { type: Array, default: () => [] }, // [{key,label,full,count}]
})

const max = computed(() => Math.max(1, ...props.days.map((d) => d.count)))
const barHeight = (count) => `${Math.max(count ? 8 : 4, (count / max.value) * 100)}%`
</script>
