<template>
  <div class="space-y-1">
    <div
      v-for="a in activities"
      :key="a.id"
      class="flex items-start gap-3 py-2.5 border-b border-border/60 last:border-0"
    >
      <Avatar
        :name="a.user?.name"
        :email="a.user ? '' : '?'"
        :color="a.user?.avatar_color || '#30363d'"
        size="sm"
      />
      <div class="min-w-0 flex-1">
        <p class="text-sm text-gray-300 leading-snug">
          <span class="font-semibold text-white">{{ a.user?.name || 'Someone' }}</span>
          {{ activityText(a) }}
        </p>
        <p class="text-xs text-muted mt-0.5">{{ timeAgo(a.created_at) }}</p>
      </div>
    </div>
    <p v-if="!activities.length" class="text-sm text-muted py-4">No activity yet</p>
  </div>
</template>

<script setup>
import { activityText } from '../lib/meta.js'
import { timeAgo } from '../lib/time.js'
import Avatar from './Avatar.vue'

defineProps({
  activities: { type: Array, default: () => [] },
})
</script>
