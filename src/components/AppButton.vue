<template>
  <component
    :is="to ? RouterLink : 'button'"
    class="btn"
    :class="[`btn--${variant}`, `btn--${size}`, { 'btn--block': block }]"
    :to="to"
    :type="to ? undefined : type"
    :disabled="to ? undefined : disabled || loading"
    :aria-busy="loading || undefined"
  >
    <slot />
  </component>
</template>

<script setup>
import { RouterLink } from 'vue-router'

defineProps({
  variant: { type: String, default: 'primary', validator: (v) => ['primary', 'secondary', 'ghost', 'danger'].includes(v) },
  size: { type: String, default: 'md', validator: (v) => ['sm', 'md'].includes(v) },
  type: { type: String, default: 'button' },
  to: { type: [String, Object], default: null },
  disabled: Boolean,
  loading: Boolean,
  block: Boolean,
})
</script>

<style scoped>
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  min-height: var(--tap-target);
  padding: 0 var(--space-5);
  border: 1px solid transparent;
  border-radius: var(--radius-md);
  font-weight: 600;
  font-size: var(--text-sm);
  text-decoration: none;
  white-space: nowrap;
  transition:
    background var(--duration-fast) var(--ease),
    border-color var(--duration-fast) var(--ease),
    transform var(--duration-fast) var(--ease);
}
.btn:hover {
  text-decoration: none;
}
.btn:active:not(:disabled) {
  transform: translateY(1px);
}
.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn--sm {
  min-height: 2.25rem;
  padding: 0 var(--space-3);
}
.btn--block {
  width: 100%;
}

.btn--primary {
  background: var(--color-accent);
  color: var(--color-accent-ink);
}
.btn--primary:hover:not(:disabled) {
  background: var(--color-accent-strong);
}

.btn--secondary {
  background: var(--color-surface-raised);
  border-color: var(--color-line);
  color: var(--color-text);
}
.btn--secondary:hover:not(:disabled) {
  border-color: var(--color-line-strong);
}

.btn--ghost {
  background: transparent;
  color: var(--color-text-muted);
}
.btn--ghost:hover:not(:disabled) {
  color: var(--color-text);
  background: var(--color-surface-raised);
}

.btn--danger {
  background: transparent;
  border-color: var(--color-loss);
  color: var(--color-loss);
}
.btn--danger:hover:not(:disabled) {
  background: var(--color-loss);
  color: var(--color-bg);
}
</style>
