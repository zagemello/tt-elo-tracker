<template>
  <div class="field">
    <label class="field__label" :for="id">{{ label }}</label>
    <slot :id="id" />
    <small v-if="hint" class="field__hint">{{ hint }}</small>
  </div>
</template>

<script setup>
import { useId } from 'vue'

defineProps({
  label: { type: String, required: true },
  hint: { type: String, default: '' },
})

const id = useId()
</script>

<style scoped>
.field {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  min-width: 0;
}
.field__label {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--color-text-muted);
}
.field__hint {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}
</style>

<style>
/* Shared control styling: use class="control" on inputs/selects */
.control {
  width: 100%;
  min-height: var(--tap-target);
  padding: 0 var(--space-3);
  background: var(--color-bg);
  color: var(--color-text);
  border: 1px solid var(--color-line);
  border-radius: var(--radius-md);
  font-size: 1rem; /* 16px+ prevents iOS zoom on focus */
  transition: border-color var(--duration-fast) var(--ease);
}
.control:hover {
  border-color: var(--color-line-strong);
}
.control:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 0;
  border-color: var(--color-accent);
}
.control::placeholder {
  color: var(--color-text-muted);
  opacity: 0.7;
}

/* ---- Select ---- */
select.control {
  appearance: none;
  padding-right: var(--space-6);
  cursor: pointer;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%238fab9d' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right var(--space-3) center;
}
/* Themed options where the browser lets us (Firefox/Safari desktop partially) */
select.control option {
  background: var(--color-surface);
  color: var(--color-text);
}

/* Fully customizable dropdown (Chromium). Other browsers keep the native picker,
   which is the better experience on phones anyway. */
@supports (appearance: base-select) {
  select.control,
  select.control::picker(select) {
    appearance: base-select;
  }
  select.control {
    display: flex;
    align-items: center;
    justify-content: space-between;
    background-image: none;
    padding-right: var(--space-3);
  }
  select.control::picker-icon {
    color: var(--color-text-muted);
    transition: rotate var(--duration) var(--ease);
  }
  select.control:open::picker-icon {
    rotate: 180deg;
  }
  select.control::picker(select) {
    margin-top: var(--space-1);
    padding: var(--space-1);
    max-height: min(20rem, 50dvh);
    background: var(--color-surface);
    color: var(--color-text);
    border: 1px solid var(--color-line-strong);
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-md);
  }
  select.control option {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    min-height: 2.5rem;
    padding: 0 var(--space-3);
    border-radius: var(--radius-sm);
    cursor: pointer;
  }
  select.control option:hover,
  select.control option:focus-visible {
    background: var(--color-surface-raised);
    outline: none;
  }
  select.control option:checked {
    color: var(--color-accent-text);
    font-weight: 600;
  }
  select.control option:disabled {
    color: var(--color-text-muted);
    cursor: default;
  }
  select.control option::checkmark {
    order: 1;
    margin-left: auto;
    color: var(--color-accent-text);
  }
}
</style>
