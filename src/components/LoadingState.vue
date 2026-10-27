<template>
  <div class="loading" role="status">
    <span class="loading__spinner" aria-hidden="true" />
    <span>{{ label }}</span>
  </div>
</template>

<script setup>
defineProps({ label: { type: String, default: 'Loading…' } })
</script>

<style scoped>
.loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-3);
  padding: var(--space-7) 0;
  color: var(--color-text-muted);
  font-size: var(--text-sm);
}
.loading__spinner {
  width: 1.1rem;
  height: 1.1rem;
  border: 2px solid var(--color-line-strong);
  border-top-color: var(--color-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
@media (prefers-reduced-motion: reduce) {
  .loading__spinner {
    animation-duration: 2.4s;
  }
}
</style>
