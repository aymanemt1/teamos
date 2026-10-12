<template>
  <div class="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
    <div class="absolute inset-0 pointer-events-none">
      <div class="absolute -top-32 -right-32 w-96 h-96 rounded-full bg-accent/10 blur-3xl"></div>
      <div class="absolute -bottom-32 -left-32 w-96 h-96 rounded-full bg-[#9d4edd]/10 blur-3xl"></div>
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
        <h1 class="text-xl font-bold text-white">Create your account</h1>
        <p class="text-sm text-muted mt-1 mb-6">Start managing projects with your team</p>

        <div
          v-if="!isSupabaseConfigured"
          class="mb-5 text-sm text-[#f0b45e] bg-[#f0b45e]/10 border border-[#f0b45e]/30 rounded-lg px-3 py-2.5"
        >
          Supabase is not configured. Set <code>VITE_SUPABASE_URL</code> and
          <code>VITE_SUPABASE_ANON_KEY</code> in a <code>.env</code> file, then restart.
        </div>

        <form v-if="!done" @submit.prevent="submit" class="space-y-4">
          <div>
            <label class="label" for="reg-name">Full name</label>
            <input
              id="reg-name"
              v-model="name"
              type="text"
              class="field"
              placeholder="Alex Morgan"
              required
              autocomplete="name"
            />
          </div>
          <div>
            <label class="label" for="reg-email">Email</label>
            <input
              id="reg-email"
              v-model="email"
              type="email"
              class="field"
              placeholder="you@company.com"
              required
              autocomplete="email"
            />
          </div>
          <div>
            <label class="label" for="reg-password">Password</label>
            <input
              id="reg-password"
              v-model="password"
              type="password"
              class="field"
              placeholder="At least 6 characters"
              required
              minlength="6"
              autocomplete="new-password"
            />
          </div>

          <p v-if="error" class="text-sm text-[#ff7b72] bg-[#f85149]/10 border border-[#f85149]/30 rounded-lg px-3 py-2">
            {{ error }}
          </p>

          <button type="submit" class="btn-primary w-full !py-2.5" :disabled="loading || !isSupabaseConfigured">
            {{ loading ? 'Creating account...' : 'Create account' }}
          </button>
        </form>

        <div v-else class="text-center py-4">
          <div class="w-14 h-14 rounded-full bg-[#3fb950]/15 text-[#3fb950] flex items-center justify-center mx-auto mb-4">
            <svg viewBox="0 0 24 24" class="w-7 h-7" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 6 9 17l-5-5"/>
            </svg>
          </div>
          <h2 class="font-bold text-white text-lg">Account created</h2>
          <p class="text-sm text-muted mt-2">
            Check your inbox to confirm your email, then
            <router-link to="/login" class="text-accent font-semibold hover:underline">sign in</router-link>.
          </p>
        </div>

        <p v-if="!done" class="text-sm text-muted text-center mt-6">
          Already have an account?
          <router-link to="/login" class="text-accent font-semibold hover:underline">Sign in</router-link>
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

const name = ref('')
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)
const done = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    await auth.signUp(email.value.trim(), password.value, name.value.trim())
    await auth.init()
    if (auth.isAuthed) {
      router.push('/')
    } else {
      done.value = true
    }
  } catch (e) {
    error.value = friendly(e)
  } finally {
    loading.value = false
  }
}

function friendly(e) {
  const msg = e.message || 'Sign up failed.'
  if (/already registered|already exists/i.test(msg)) return 'An account with this email already exists. Try signing in.'
  if (/password/i.test(msg) && /short|weak|6/i.test(msg)) return 'Password must be at least 6 characters.'
  return msg
}
</script>
