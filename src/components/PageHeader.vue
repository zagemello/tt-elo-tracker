<template>
  <header class="page-header">
    <div class="page-header__text">
      <h1 class="page-header__title">{{ title }}</h1>
      <p v-if="subtitle" class="page-header__subtitle">{{ subtitle }}</p>
    </div>
    <div v-if="$slots.default" class="page-header__actions">
      <slot />
    </div>
  </header>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
})
</script>

<style scoped>
.page-header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-3) var(--space-5);
  margin-bottom: var(--space-5);
}
.page-header__title {
  font-size: var(--text-xl);
}
.page-header__subtitle {
  margin-top: var(--space-1);
  color: var(--color-text-muted);
  font-size: var(--text-sm);
  max-width: 60ch;
}
.page-header__actions {
  max-width: 100%;
}
@media (max-width: 30rem) {
  .page-header__actions {
    width: 100%;
  }
}
</style>
