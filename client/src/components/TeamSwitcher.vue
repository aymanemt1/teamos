<template>
  <div>
    <!-- Single team: just show the name. No create-team action exists on purpose:
         the teams INSERT RLS policy blocks direct client inserts for new teams,
         so teams are created by an admin in the Supabase dashboard. -->
    <div v-if="team.teams.length <= 1" class="flex items-center gap-2 px-1 py-1">
      <span class="w-2 h-2 rounded-full bg-accent shrink-0"></span>
      <span class="text-sm font-semibold text-gray-200 truncate">
        {{ team.currentTeam?.name ?? 'No team' }}
      </span>
    </div>
    <div v-else class="relative">
      <select
        :value="team.currentTeamId"
        @change="onChange($event.target.value)"
        class="field appearance-none pr-9 !py-2 text-sm font-semibold cursor-pointer"
        aria-label="Switch team"
      >
        <option v-for="t in team.teams" :key="t.id" :value="t.id">{{ t.name }}</option>
      </select>
      <Icon
        name="chevronDown"
        cls="w-4 h-4 text-muted absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none"
      />
    </div>
  </div>
</template>

<script setup>
import { useTeamStore } from '../stores/team.js'
import Icon from './Icon.vue'

const team = useTeamStore()
const emit = defineEmits(['change'])

function onChange(id) {
  team.setCurrentTeam(id)
  emit('change', id)
}
</script>
