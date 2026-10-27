<template>
  <div class="set">
    <span class="set__label">Set {{ index + 1 }}</span>
    <input
      class="control set__input num"
      type="number"
      inputmode="numeric"
      min="0"
      max="99"
      :value="modelValue.winnerPoints"
      :aria-label="`Set ${index + 1} winner points`"
      placeholder="11"
      @input="update('winnerPoints', $event.target.value)"
    />
    <span class="set__sep" aria-hidden="true">–</span>
    <input
      class="control set__input num"
      type="number"
      inputmode="numeric"
      min="0"
      max="99"
      :value="modelValue.loserPoints"
      :aria-label="`Set ${index + 1} loser points`"
      placeholder="7"
      @input="update('loserPoints', $event.target.value)"
    />
    <button v-if="removable" type="button" class="set__remove" aria-label="Remove set" @click="$emit('remove')">
      <AppIcon name="close" :size="18" />
    </button>
    <span v-else class="set__remove" aria-hidden="true" />
  </div>
</template>

<script setup>
import AppIcon from './AppIcon.vue'

const props = defineProps({
  modelValue: { type: Object, required: true },
  index: { type: Number, required: true },
  removable: { type: Boolean, default: false },
})

const emit = defineEmits(['update:modelValue', 'remove'])

function update(field, value) {
  emit('update:modelValue', { ...props.modelValue, [field]: value })
}
</script>

<style scoped>
.set {
  display: grid;
  grid-template-columns: 3.5rem 1fr auto 1fr var(--tap-target);
  align-items: center;
  gap: var(--space-2);
}
.set__label {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
  font-weight: 600;
}
.set__input {
  text-align: center;
  font-family: var(--font-display);
  font-weight: 700;
  font-size: 1.125rem;
}
.set__sep {
  color: var(--color-text-muted);
}
.set__remove {
  display: grid;
  place-items: center;
  width: var(--tap-target);
  height: var(--tap-target);
  background: none;
  border: 0;
  border-radius: var(--radius-md);
  color: var(--color-text-muted);
}
button.set__remove:hover {
  color: var(--color-loss);
  background: var(--color-loss-soft);
}
</style>
