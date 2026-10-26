<template>
  <div class="set-row">
    <span class="set-label">Set {{ index + 1 }}</span>
    <div class="score-inputs">
      <input
        type="number"
        min="0"
        max="99"
        :value="modelValue.winnerPoints"
        @input="update('winnerPoints', $event.target.value)"
        placeholder="W pts"
      />
      <span>–</span>
      <input
        type="number"
        min="0"
        max="99"
        :value="modelValue.loserPoints"
        @input="update('loserPoints', $event.target.value)"
        placeholder="L pts"
      />
    </div>
    <button v-if="index > 0" type="button" class="btn-remove" @click="$emit('remove')">✕</button>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Object, required: true },
  index: { type: Number, required: true },
})

const emit = defineEmits(['update:modelValue', 'remove'])

function update(field, value) {
  emit('update:modelValue', { ...props.modelValue, [field]: value })
}
</script>
