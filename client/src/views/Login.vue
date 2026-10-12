<template>
  <div class="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
    <div class="absolute inset-0 pointer-events-none">
      <div class="absolute -top-32 -left-32 w-96 h-96 rounded-full bg-accent/10 blur-3xl"></div>
      <div class="absolute -bottom-32 -right-32 w-96 h-96 rounded-full bg-[#9d4edd]/10 blur-3xl"></div>
    </div>

    <div class="anim-pop relative w-full max-w-md">
      <div class="flex items-center justify-center gap-3 mb-8">
        <div class="w-11 h-11 rounded-2xl bg-accent flex items-center justify-center shadow-pop">
          <svg viewBox="0 0 24 24" class="w-6 h-6 text-white" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="4" width="5" height="16" rx="1.5"/><rect x="10" y="4" width="5" height="10" rx="1.5"/><rect x="17" y="4" width="4" height="13" rx="1.5"/>
          </svg>
        </div>
        <span class="text-2xl font-extrabold tracking-tight text-white">TeamOS</span>
      </div>

      <div class="bg-card border border-border rounded-2xl p-8 shadow-pop">
        <h1 class="text-xl font-bold text-white">Welcome back</h1>
        <p class="text-sm text-muted mt-1 mb-6">Sign in to your workspace</p>

        <div
          v-if="!isSupabaseConfigured"
          class="mb-5 text-sm text-[#f0b45e] bg-[#f0b45e]/10 border border-[#f0b45e]/30 rounded-lg px-3 py-2.5"
        >
          Supabase is not configured. Set <code>VITE_SUPABASE_URL</code> and
          <code>VITE_SUPABASE_ANON_KEY</code> in a <code>.env</code> file, then restart.
        </div>

        <form @submit.prevent="submit" class="space-y-4">
          <div>
            <label class="label" for="login-email">Email</label>
            <input
              id="login-email"
              v-model="email"
              type="email"
              class="field"
              placeholder="you@company.com"
              required
              autocomplete="email"
            />
          </div>
          <div>
            <label class="label" for="login-password">Password</label>
            <input
              id="login-password"
              v-model="password"
              type="password"
              class="field"
              placeholder="Your password"
              required
              autocomplete="current-password"
            />
          </div>

          <p v-if="error" class="text-sm text-[#ff7b72] bg-[#f85149]/10 border border-[#f85149]/30 rounded-lg px-3 py-2">
            {{ error }}
          </p>

          <button type="submit" class="btn-primary w-full !py-2.5" :disabled="loading || !isSupabaseConfigured">
            {{ loading ? 'Signing in...' : 'Sign in' }}
          </button>
        </form>

        <p class="text-sm text-muted text-center mt-6">
          New to TeamOS?
          <router-link to="/register" class="text-accent font-semibold hover:underline">Create an account</router-link>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'
import { isSupabaseConfigured } from '../lib/supabase.js'

const router = useRouter()
const auth = useAuthStore()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    await auth.signIn(email.value.trim(), password.value)
    router.push('/')
  } catch (e) {
    error.value = friendly(e)
  } finally {
    loading.value = false
  }
}

function friendly(e) {
  const msg = e.message || 'Sign in failed.'
  if (/invalid login credentials/i.test(msg)) return 'Incorrect email or password.'
  if (/email not confirmed/i.test(msg)) return 'Please confirm your email first, then sign in.'
  return msg
}
</script>
