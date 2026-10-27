<template>
  <div class="segmented" role="radiogroup" :aria-label="label" :style="thumbStyle">
    <span class="segmented__thumb" aria-hidden="true" />
    <button
      v-for="opt in options"
      :key="opt.value"
      type="button"
      role="radio"
      class="segmented__item"
      :class="{ 'is-active': opt.value === modelValue }"
      :aria-checked="opt.value === modelValue"
      @click="$emit('update:modelValue', opt.value)"
    >
      {{ opt.label }}
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: [String, Number], required: true },
  options: { type: Array, required: true }, // [{ label, value }]
  label: { type: String, default: '' },
})
defineEmits(['update:modelValue'])

// The thumb slides to the active option; items are equal width so index math is enough.
const thumbStyle = computed(() => ({
  '--count': props.options.length,
  '--index': Math.max(0, props.options.findIndex((o) => o.value === props.modelValue)),
}))
</script>

<style scoped>
.segmented {
  --duration-slide: calc(var(--duration) * 1.25); /* thumb and label colour share one clock */
  position: relative;
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: 1fr; /* equal-width options, so the thumb maths is exact */
  padding: 3px;
  background: var(--color-surface);
  border: 1px solid var(--color-line);
  border-radius: var(--radius-md);
}
.segmented__thumb {
  position: absolute;
  top: 3px;
  bottom: 3px;
  left: 3px;
  width: calc((100% - 6px) / var(--count));
  background: var(--color-accent);
  border-radius: calc(var(--radius-md) - 3px);
  transform: translateX(calc(var(--index) * 100%));
  transition: transform var(--duration-slide) var(--ease);
}
.segmented__item {
  position: relative;
  min-height: 2.25rem;
  padding: 0 var(--space-4);
  background: transparent;
  border: 0;
  border-radius: calc(var(--radius-md) - 3px);
  color: var(--color-text-muted);
  font-size: var(--text-sm);
  font-weight: 600;
  white-space: nowrap;
  transition: color var(--duration-slide) var(--ease);
}
.segmented__item:hover {
  color: var(--color-text);
}
.segmented__item.is-active,
.segmented__item.is-active:hover {
  color: var(--color-accent-ink);
}
</style>
