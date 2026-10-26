<template>
  <div class="auth-page">
    <div class="auth-card">
      <div class="auth-header">
        <span class="ping-icon">🏓</span>
        <h1>TT Elo Tracker</h1>
        <p>Sign in to log matches and track your ranking</p>
      </div>

      <div class="tab-row">
        <button :class="{ active: mode === 'signin' }" @click="mode = 'signin'">Sign In</button>
        <button :class="{ active: mode === 'signup' }" @click="mode = 'signup'">Sign Up</button>
      </div>

      <form @submit.prevent="handleSubmit" class="auth-form">
        <div class="field">
          <label>Email</label>
          <input v-model="email" type="email" required autocomplete="email" />
        </div>

        <div class="field">
          <label>Password</label>
          <input v-model="password" type="password" required autocomplete="current-password" minlength="6" />
        </div>

        <p v-if="error" class="error-msg">{{ error }}</p>
        <p v-if="successMsg" class="success-msg">{{ successMsg }}</p>

        <button type="submit" class="btn-primary" :disabled="loading">
          {{ loading ? 'Loading…' : mode === 'signin' ? 'Sign In' : 'Create Account' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const mode = ref('signin')
const email = ref('')
const password = ref('')
const error = ref('')
const successMsg = ref('')
const loading = ref(false)

async function handleSubmit() {
  error.value = ''
  successMsg.value = ''
  loading.value = true
  try {
    if (mode.value === 'signin') {
      await auth.signInWithEmail(email.value, password.value)
    } else {
      await auth.signUpWithEmail(email.value, password.value)
      successMsg.value = 'Account created! You are now signed in.'
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>
