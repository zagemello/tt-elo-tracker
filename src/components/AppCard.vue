<template>
  <component :is="as" class="card" :class="{ 'card--flush': flush }">
    <slot />
  </component>
</template>

<script setup>
defineProps({
  as: { type: String, default: 'div' },
  flush: Boolean,
})
</script>

<style scoped>
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-line);
  border-radius: var(--radius-lg);
  padding: var(--space-4);
}
.card--flush {
  padding: 0;
  overflow: hidden;
}
@media (min-width: 48rem) {
  .card:not(.card--flush) {
    padding: var(--space-5);
  }
}
</style>
