import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/',
      name: 'leaderboard',
      component: () => import('@/views/LeaderboardView.vue'),
    },
    {
      path: '/profile/:id',
      name: 'profile',
      component: () => import('@/views/ProfileView.vue'),
    },
    {
      path: '/matches',
      name: 'matches',
      component: () => import('@/views/MatchesView.vue'),
    },
    {
      name: 'log-match',
      component: () => import('@/views/LogMatchView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('@/views/AdminView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/h2h',
      name: 'h2h',
      component: () => import('@/views/H2HView.vue'),
    },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  if (auth.loading) await new Promise((r) => setTimeout(r, 50))

  if (to.meta.requiresAdmin && !auth.isAdmin) return { name: 'leaderboard' }
  if (to.meta.requiresAuth && !auth.session) return { name: 'login' }
  if (to.meta.guestOnly && auth.session) return { name: 'leaderboard' }
})

export default router
