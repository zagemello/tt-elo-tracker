<template>
  <section class="section">
    <h2 class="section__title">{{ title }}</h2>
    <slot />
  </section>
</template>

<script setup>
defineProps({ title: { type: String, required: true } })
</script>

<style scoped>
.section {
  margin-top: var(--space-6);
}
.section__title {
  margin-bottom: var(--space-3);
  font-size: var(--text-lg);
}
</style>
