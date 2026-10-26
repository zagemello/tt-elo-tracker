<template>
  <div v-if="auth.loading" class="app-loading">Loading…</div>
  <template v-else>
    <nav v-if="auth.session" class="navbar">
      <RouterLink to="/" class="nav-brand">🏓 TT Elo</RouterLink>
      <div class="nav-links">
        <RouterLink to="/">Leaderboard</RouterLink>
        <RouterLink to="/log-match">Log Match</RouterLink>
        <RouterLink to="/h2h">H2H</RouterLink>
        <RouterLink v-if="auth.profile" :to="`/profile/${auth.session.user.id}`">
          My Profile
        </RouterLink>
      </div>
      <button class="btn-ghost" @click="auth.signOut">Sign out</button>
    </nav>

    <div v-if="auth.session && !auth.profile" class="create-profile-banner">
      <form @submit.prevent="handleCreateProfile" class="inline-form">
        <span>Choose a display name to get started:</span>
        <input v-model="displayName" type="text" maxlength="40" required placeholder="Your name" />
        <button type="submit" class="btn-primary">Set Name</button>
        <span v-if="profileError" class="error-msg">{{ profileError }}</span>
      </form>
    </div>

    <main class="main-content">
      <RouterView />
    </main>
  </template>
</template>

<script setup>
import { ref } from 'vue'
import { RouterView, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const displayName = ref('')
const profileError = ref('')

auth.init()

async function handleCreateProfile() {
  profileError.value = ''
  try {
    await auth.createProfile(displayName.value.trim())
  } catch (e) {
    profileError.value = e.message
  }
}
</script>
