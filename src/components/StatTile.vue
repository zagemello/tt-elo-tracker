<template>
  <div class="stat">
    <span class="stat__value num" :class="tone && `text-${tone}`">
      <slot>{{ value }}</slot>
    </span>
    <span class="stat__label">{{ label }}</span>
  </div>
</template>

<script setup>
defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], default: '' },
  tone: { type: String, default: '', validator: (v) => ['', 'win', 'loss'].includes(v) },
})
</script>

<style scoped>
.stat {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}
.stat__value {
  font-family: var(--font-display);
  font-size: var(--text-lg);
  font-weight: 700;
  line-height: 1.1;
}
.stat__label {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}
</style>
