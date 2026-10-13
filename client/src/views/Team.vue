<template>
  <div class="p-4 sm:p-6 lg:p-8 max-w-4xl mx-auto">
    <div class="mb-6 anim-fade-up">
      <h1 class="text-2xl font-extrabold tracking-tight text-white">Team</h1>
      <p class="text-sm text-muted mt-1">
        {{
          team.currentTeam
            ? `${team.members.length} member(s) in ${team.currentTeam.name}`
            : 'Members of your team will show up here.'
        }}
      </p>
    </div>

    <!-- add member -->
    <div v-if="team.canManage && !loadError" class="bg-card border border-border rounded-2xl p-5 mb-6 anim-fade-up stagger-1">
      <h2 class="font-bold text-white flex items-center gap-2">
        <Icon name="userPlus" cls="w-5 h-5 text-accent" /> Add member
      </h2>
      <p class="text-sm text-muted mt-1 mb-4">
        New people must sign up for TeamOS first — then add them here by email and they will
        join this team immediately.
      </p>
      <form @submit.prevent="addMember" class="flex flex-col sm:flex-row gap-2">
        <label class="sr-only" for="add-member-email">Email</label>
        <input
          id="add-member-email"
          v-model="email"
          type="email"
          class="field flex-1"
          placeholder="colleague@company.com"
          required
          autocomplete="email"
        />
        <button type="submit" class="btn-primary shrink-0" :disabled="adding">
          {{ adding ? 'Adding...' : 'Add to team' }}
        </button>
      </form>
      <p v-if="addError" class="text-sm text-[#ff7b72] mt-2">{{ addError }}</p>
    </div>

    <!-- member list -->
    <div v-if="loading" class="space-y-3">
      <Skeleton v-for="i in 4" :key="i" cls="h-16" />
    </div>
    <div v-else-if="loadError" role="alert">
      <EmptyState icon="alert" title="Couldn't load the team" :subtitle="loadError">
        <button type="button" class="btn-primary" @click="load">Try again</button>
      </EmptyState>
    </div>
    <EmptyState
      v-else-if="!team.currentTeamId"
      icon="users"
      title="No team yet"
      subtitle="You're not on a team yet. An admin creates teams and adds members in the Supabase dashboard."
    />
    <div v-else class="bg-card border border-border rounded-2xl overflow-hidden anim-fade-up stagger-2">
      <div
        v-for="m in team.members"
        :key="m.id"
        class="flex items-center gap-4 px-5 py-4 border-b border-border/60 last:border-0 hover:bg-cardhover/50 transition-colors"
      >
        <Avatar
          :name="m.profile?.name"
          :email="m.profile?.email"
          :color="m.profile?.avatar_color || '#30363d'"
          size="md"
        />
        <div class="min-w-0 flex-1">
          <p class="font-semibold text-white truncate">
            {{ m.profile?.name || 'Unknown user' }}
            <span v-if="m.user_id === auth.user?.id" class="text-xs text-muted font-normal">(you)</span>
          </p>
          <p class="text-sm text-muted truncate">{{ m.profile?.email || '' }}</p>
        </div>
        <span
          class="text-[11px] font-bold uppercase tracking-wider rounded-full px-2.5 py-1"
          :class="roleBadge(m.role)"
        >
          {{ m.role }}
        </span>
        <template v-if="team.canManage && m.user_id !== auth.user?.id">
          <select
            :value="m.role"
            @change="changeRole(m, $event.target.value)"
            class="field !w-auto !py-1.5 text-sm cursor-pointer"
            aria-label="Change role"
          >
            <option value="member">member</option>
            <option value="admin">admin</option>
            <option value="owner">owner</option>
          </select>
          <button
            class="p-2 text-muted hover:text-[#ff7b72] rounded-lg hover:bg-base transition-colors"
            @click="askRemove(m)"
            aria-label="Remove member"
            title="Remove from team"
          >
            <Icon name="x" cls="w-4 h-4" />
          </button>
        </template>
      </div>
      <p v-if="!team.members.length" class="text-sm text-muted text-center py-8">No members found</p>
    </div>

    <ConfirmModal
      :open="confirmOpen"
      title="Remove member?"
      :message="`${toRemove?.profile?.name || toRemove?.profile?.email || 'This member'} will lose access to this team.`"
      confirm-label="Remove"
      @confirm="doRemove"
      @cancel="confirmOpen = false"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import { useTeamStore } from '../stores/team.js'
import { toast } from '../lib/toast.js'
import Avatar from '../components/Avatar.vue'
import Icon from '../components/Icon.vue'
import Skeleton from '../components/Skeleton.vue'
import ConfirmModal from '../components/ConfirmModal.vue'
import EmptyState from '../components/EmptyState.vue'

const auth = useAuthStore()
const team = useTeamStore()

const loading = ref(true)
const loadError = ref('')
const email = ref('')
const adding = ref(false)
const addError = ref('')
const confirmOpen = ref(false)
const toRemove = ref(null)

function roleBadge(role) {
  return {
    owner: 'bg-[#9d4edd]/15 text-[#d2a8ff]',
    admin: 'bg-accent/15 text-accent',
    member: 'bg-muted/15 text-muted',
  }[role] ?? 'bg-muted/15 text-muted'
}

async function load() {
  loading.value = true
  loadError.value = ''
  try {
    await team.fetchTeams()
    if (team.currentTeamId) await team.fetchMembers()
  } catch (e) {
    loadError.value = e?.message || 'Could not load the team.'
  } finally {
    loading.value = false
  }
}

async function addMember() {
  addError.value = ''
  adding.value = true
  try {
    await team.addMemberByEmail(email.value)
    email.value = ''
    toast.success('Member added to the team')
  } catch (e) {
    addError.value = e.message || 'Could not add the member.'
  } finally {
    adding.value = false
  }
}

async function changeRole(m, role) {
  try {
    await team.updateRole(m.id, role)
    toast.success(`Role updated to ${role}`)
  } catch (e) {
    toast.error(e.message || 'Could not update the role.')
    await team.fetchMembers()
  }
}

function askRemove(m) {
  toRemove.value = m
  confirmOpen.value = true
}

async function doRemove() {
  confirmOpen.value = false
  try {
    await team.removeMember(toRemove.value.id)
    toast.success('Member removed')
  } catch (e) {
    toast.error(e.message || 'Could not remove the member.')
  } finally {
    toRemove.value = null
  }
}

onMounted(load)
watch(
  () => team.currentTeamId,
  (id, prev) => {
    if (id && id !== prev) load()
  }
)
</script>
