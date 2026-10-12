<template>
  <!-- Auth pages: minimal layout -->
  <div v-if="minimal">
    <router-view />
    <Toasts />
  </div>

  <!-- App shell -->
  <div v-else class="min-h-screen flex">
    <!-- Sidebar (desktop, >=900px) -->
    <aside class="hidden min-[900px]:flex w-64 shrink-0 flex-col bg-card border-r border-border sticky top-0 h-screen">
      <div class="flex items-center gap-3 px-5 pt-6 pb-5">
        <div class="w-9 h-9 rounded-xl bg-accent flex items-center justify-center shrink-0">
          <Icon name="board" cls="w-5 h-5 text-white" />
        </div>
        <span class="text-lg font-extrabold tracking-tight text-white">TeamOS</span>
      </div>

      <div class="px-4 pb-4 border-b border-border/60">
        <TeamSwitcher />
        <p class="text-[11px] text-muted mt-2 px-1 leading-snug">
          Teams are created by an admin in the Supabase dashboard.
        </p>
      </div>

      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <router-link
          v-for="link in nav"
          :key="link.to"
          :to="link.to"
          class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors"
          :class="
            route.path === link.to
              ? 'bg-accent/15 text-white'
              : 'text-muted hover:text-white hover:bg-cardhover'
          "
        >
          <Icon :name="link.icon" cls="w-5 h-5" :class="route.path === link.to ? 'text-accent' : ''" />
          {{ link.label }}
        </router-link>
      </nav>

      <div class="p-4 border-t border-border/60">
        <div class="flex items-center gap-3">
          <Avatar
            :name="auth.profile?.name"
            :email="auth.user?.email"
            :color="auth.profile?.avatar_color || '#7c6cf0'"
            size="sm"
          />
          <div class="min-w-0 flex-1">
            <p class="text-sm font-semibold text-white truncate">
              {{ auth.profile?.name || auth.user?.email }}
            </p>
            <p class="text-xs text-muted truncate">{{ auth.user?.email }}</p>
          </div>
          <button
            class="p-2 text-muted hover:text-[#ff7b72] rounded-lg hover:bg-base transition-colors"
            @click="signOut"
            title="Sign out"
            aria-label="Sign out"
          >
            <Icon name="logout" cls="w-5 h-5" />
          </button>
        </div>
      </div>
    </aside>

    <!-- Main column -->
    <div class="flex-1 min-w-0 flex flex-col min-h-screen">
      <!-- Topbar (mobile, <900px) -->
      <header class="min-[900px]:hidden sticky top-0 z-40 bg-card/95 backdrop-blur border-b border-border">
        <div class="flex items-center gap-2 px-4 py-3">
          <div class="w-8 h-8 rounded-lg bg-accent flex items-center justify-center shrink-0">
            <Icon name="board" cls="w-4 h-4 text-white" />
          </div>
          <span class="font-extrabold text-white">TeamOS</span>
          <button
            class="ml-auto p-2 text-muted hover:text-[#ff7b72] rounded-lg"
            @click="signOut"
            aria-label="Sign out"
          >
            <Icon name="logout" cls="w-5 h-5" />
          </button>
        </div>
        <nav class="flex gap-1 px-3 pb-2 overflow-x-auto">
          <router-link
            v-for="link in nav"
            :key="link.to"
            :to="link.to"
            class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors"
            :class="
              route.path === link.to
                ? 'bg-accent/15 text-white'
                : 'text-muted hover:text-white hover:bg-cardhover'
            "
          >
            <Icon :name="link.icon" cls="w-4 h-4" />
            {{ link.label }}
          </router-link>
        </nav>
      </header>

      <main class="flex-1 min-w-0">
        <router-view />
      </main>
    </div>

    <Toasts />
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth.js'
import { useTaskStore } from './stores/tasks.js'
import Icon from './components/Icon.vue'
import Avatar from './components/Avatar.vue'
import Toasts from './components/Toasts.vue'
import TeamSwitcher from './components/TeamSwitcher.vue'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const taskStore = useTaskStore()

const minimal = computed(() => !!route.meta.guest)

const nav = [
  { to: '/', label: 'Dashboard', icon: 'dashboard' },
  { to: '/board', label: 'Board', icon: 'board' },
  { to: '/projects', label: 'Projects', icon: 'folder' },
  { to: '/team', label: 'Team', icon: 'users' },
]

async function signOut() {
  taskStore.unsubscribe()
  await auth.signOut()
  router.push('/login')
}
</script>
