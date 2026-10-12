<template>
  <teleport to="body">
    <div v-if="open" class="fixed inset-0 z-[90] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/70 backdrop-blur-sm" @click="cancel"></div>
      <div class="anim-pop relative bg-card border border-border rounded-2xl p-6 w-full max-w-sm shadow-pop">
        <div class="flex items-start gap-3">
          <div class="w-10 h-10 rounded-xl bg-[#f85149]/15 text-[#ff7b72] flex items-center justify-center shrink-0">
            <Icon name="alert" cls="w-5 h-5" />
          </div>
          <div>
            <h3 class="font-bold text-white">{{ title }}</h3>
            <p class="text-sm text-muted mt-1">{{ message }}</p>
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button class="btn-ghost" @click="cancel">{{ cancelLabel }}</button>
          <button class="btn-danger" @click="confirm">{{ confirmLabel }}</button>
        </div>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import Icon from './Icon.vue'

defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, default: 'Are you sure?' },
  message: { type: String, default: 'This action cannot be undone.' },
  confirmLabel: { type: String, default: 'Delete' },
  cancelLabel: { type: String, default: 'Cancel' },
})

const emit = defineEmits(['confirm', 'cancel'])
const confirm = () => emit('confirm')
const cancel = () => emit('cancel')
</script>
