<template>
  <div class="fixed bottom-5 right-5 z-[100] flex flex-col gap-2 items-end">
    <div
      v-for="t in toasts"
      :key="t.id"
      class="anim-toast flex items-center gap-3 bg-card border border-border rounded-xl px-4 py-3 shadow-pop max-w-sm"
    >
      <span
        class="w-2.5 h-2.5 rounded-full shrink-0"
        :style="{ backgroundColor: dotColor(t.type) }"
      ></span>
      <p class="text-sm text-gray-200">{{ t.message }}</p>
      <button
        class="text-muted hover:text-white transition-colors"
        @click="dismissToast(t.id)"
        aria-label="Dismiss"
      >
        <Icon name="x" cls="w-4 h-4" />
      </button>
    </div>
  </div>
</template>

<script setup>
import { toasts, dismissToast } from '../lib/toast.js'
import Icon from './Icon.vue'

const dotColor = (type) =>
  ({ success: '#3fb950', error: '#f85149', info: '#7c6cf0' })[type] ?? '#7c6cf0'
</script>
