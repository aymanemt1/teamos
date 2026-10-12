import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'

const routes = [
  { path: '/login', component: () => import('../views/Login.vue'), meta: { guest: true } },
  { path: '/register', component: () => import('../views/Register.vue'), meta: { guest: true } },
  { path: '/', component: () => import('../views/Dashboard.vue'), meta: { requiresAuth: true } },
  { path: '/board', component: () => import('../views/Board.vue'), meta: { requiresAuth: true } },
  { path: '/projects', component: () => import('../views/Projects.vue'), meta: { requiresAuth: true } },
  { path: '/team', component: () => import('../views/Team.vue'), meta: { requiresAuth: true } },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.init()
  if (to.meta.requiresAuth && !auth.isAuthed) return '/login'
  if (to.meta.guest && auth.isAuthed) return '/'
})

export default router
