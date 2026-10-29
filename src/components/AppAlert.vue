<template>
  <p class="alert" :class="`alert--${tone}`" :role="tone === 'error' ? 'alert' : 'status'">
    <slot />
  </p>
</template>

<script setup>
defineProps({
  tone: { type: String, default: 'error', validator: (v) => ['error', 'success', 'info'].includes(v) },
})
</script>

<style scoped>
.alert {
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  border: 1px solid transparent;
}
.alert--error {
  background: var(--color-loss-soft);
  border-color: var(--color-loss);
  color: var(--color-loss);
}
.alert--success {
  background: var(--color-win-soft);
  border-color: var(--color-win);
  color: var(--color-win);
}
.alert--info {
  background: var(--color-surface-raised);
  border-color: var(--color-line);
  color: var(--color-text-muted);
}
</style>
