<template>
  <div class="empty">
    <p class="empty__title"><slot name="title">{{ title }}</slot></p>
    <p v-if="$slots.default" class="empty__body"><slot /></p>
    <div v-if="$slots.action" class="empty__action"><slot name="action" /></div>
  </div>
</template>

<script setup>
defineProps({ title: { type: String, default: 'Nothing here yet' } })
</script>

<style scoped>
.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-7) var(--space-4);
  text-align: center;
  border: 1px dashed var(--color-line-strong);
  border-radius: var(--radius-lg);
}
.empty__title {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: var(--text-lg);
}
.empty__body {
  color: var(--color-text-muted);
  font-size: var(--text-sm);
  max-width: 40ch;
}
.empty__action {
  margin-top: var(--space-3);
}
</style>
