<template>
  <div v-if="auth.loading" class="app-loading">Loading…</div>
  <template v-else>
    <nav class="navbar">
      <RouterLink to="/" class="nav-brand">🏓 TT Elo</RouterLink>
      <div class="nav-links">
        <RouterLink to="/">Leaderboard</RouterLink>
        <template v-if="auth.session">
          <RouterLink to="/log-match">Log Match</RouterLink>
          <RouterLink to="/h2h">H2H</RouterLink>
          <RouterLink v-if="auth.profile" :to="`/profile/${auth.profile.id}`">
            My Profile
          </RouterLink>
          <RouterLink v-if="auth.isAdmin" to="/admin" class="admin-link">Admin</RouterLink>
        </template>
      </div>
      <RouterLink v-if="!auth.session" to="/login" class="btn-primary">Login / Sign up</RouterLink>
      <button v-else class="btn-ghost" @click="auth.signOut">Sign out</button>
    </nav>

    <main class="main-content">
      <RouterView />
    </main>
  </template>
</template>

<script setup>
import { RouterView, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
auth.init()
</script>
