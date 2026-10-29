<template>
  <div class="auth">
    <AppCard class="auth__card">
      <div class="auth__header">
        <img :src="logo" alt="TT Elo" class="auth__logo" />
        <h1>{{ mode === 'signin' ? 'Welcome back' : 'Join the league' }}</h1>
        <p>Sign in to log matches and track your ranking.</p>
      </div>

      <SegmentedControl v-model="mode" :options="modes" label="Account action" />

      <form class="stack auth__form" @submit.prevent="handleSubmit">
        <FormField v-slot="{ id }" label="Username">
          <input :id="id" v-model="username" class="control" type="text" required autocomplete="username" placeholder="e.g. john" />
        </FormField>

        <FormField v-slot="{ id }" label="Password" hint="At least 6 characters.">
          <input
            :id="id"
            v-model="password"
            class="control"
            type="password"
            required
            minlength="6"
            :autocomplete="mode === 'signin' ? 'current-password' : 'new-password'"
          />
        </FormField>

        <AppAlert v-if="error">{{ error }}</AppAlert>

        <AppButton type="submit" block :loading="loading">
          {{ loading ? 'Please wait…' : mode === 'signin' ? 'Sign in' : 'Create account' }}
        </AppButton>
      </form>
    </AppCard>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import logo from '@/assets/logo.svg'
import AppCard from '@/components/AppCard.vue'
import AppButton from '@/components/AppButton.vue'
import AppAlert from '@/components/AppAlert.vue'
import FormField from '@/components/FormField.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'

const auth = useAuthStore()
const router = useRouter()
const mode = ref('signin')
const modes = [
  { label: 'Sign in', value: 'signin' },
  { label: 'Sign up', value: 'signup' },
]
const username = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function handleSubmit() {
  error.value = ''
  loading.value = true
  try {
    if (mode.value === 'signin') await auth.signIn(username.value, password.value)
    else await auth.signUp(username.value, password.value)
    router.push('/')
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth {
  display: flex;
  justify-content: center;
  padding-top: var(--space-5);
}
.auth__card {
  width: 100%;
  max-width: 26rem;
}
.auth__header {
  text-align: center;
  margin-bottom: var(--space-5);
}
.auth__header h1 {
  font-size: var(--text-xl);
}
.auth__header p {
  margin-top: var(--space-1);
  color: var(--color-text-muted);
  font-size: var(--text-sm);
}
.auth__logo {
  display: block;
  height: 6rem;
  width: auto;
  margin: 0 auto var(--space-3);
}
.auth__form {
  margin-top: var(--space-5);
}
</style>
