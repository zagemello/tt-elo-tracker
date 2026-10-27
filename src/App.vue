<template>
  <LoadingState v-if="auth.loading" class="app-loading" />
  <template v-else>
    <AppNav />
    <main class="page-shell">
      <RouterView />
    </main>
  </template>
</template>

<script setup>
import { RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppNav from '@/components/AppNav.vue'
import LoadingState from '@/components/LoadingState.vue'

const auth = useAuthStore()
auth.init()
</script>

<style>
.app-loading {
  min-height: 100dvh;
}

.page-shell {
  max-width: var(--page-max);
  margin: 0 auto;
  padding: var(--space-5) var(--page-gutter) calc(var(--tabbar-height) + var(--space-6) + env(safe-area-inset-bottom));
}

@media (min-width: 48rem) {
  .page-shell {
    padding-top: var(--space-6);
    padding-bottom: var(--space-8);
  }
}
</style>
