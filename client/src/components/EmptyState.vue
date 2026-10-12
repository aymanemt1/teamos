<template>
  <div class="flex flex-col items-center justify-center text-center py-12 px-6">
    <div class="w-14 h-14 rounded-2xl bg-card border border-border flex items-center justify-center text-muted">
      <Icon :name="icon" cls="w-7 h-7" />
    </div>
    <p class="mt-4 font-semibold text-gray-200">{{ title }}</p>
    <p class="mt-1 text-sm text-muted max-w-xs">{{ subtitle }}</p>
    <div class="mt-5"><slot /></div>
  </div>
</template>

<script setup>
import Icon from './Icon.vue'

defineProps({
  icon: { type: String, default: 'inbox' },
  title: { type: String, default: 'Nothing here yet' },
  subtitle: { type: String, default: '' },
})
</script>
