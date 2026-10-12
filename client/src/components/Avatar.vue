<template>
  <div
    class="rounded-full flex items-center justify-center font-bold text-white shrink-0 select-none"
    :class="sizeCls"
    :style="{ backgroundColor: color }"
    :title="title"
  >
    {{ label }}
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { initials } from '../lib/time.js'

const props = defineProps({
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  color: { type: String, default: '#7c6cf0' },
  size: { type: String, default: 'md' }, // xs | sm | md | lg
  title: { type: String, default: '' },
})

const label = computed(() => initials(props.name, props.email))
const sizeCls = computed(
  () =>
    ({
      xs: 'w-6 h-6 text-[10px]',
      sm: 'w-8 h-8 text-xs',
      md: 'w-10 h-10 text-sm',
      lg: 'w-12 h-12 text-base',
    })[props.size] ?? 'w-10 h-10 text-sm'
)
</script>
