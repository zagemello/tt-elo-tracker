<template>
  <div class="avatar-wrapper" :style="{ width: size + 'px', height: size + 'px' }">
    <img v-if="url" :src="url" :alt="name" class="avatar-img" />
    <div v-else class="avatar-placeholder">{{ initials }}</div>
    <label v-if="editable" class="avatar-upload-btn" title="Upload avatar">
      <input type="file" accept="image/*" @change="onFileChange" hidden />
      📷
    </label>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  url: { type: String, default: null },
  name: { type: String, default: '' },
  size: { type: Number, default: 40 },
  editable: { type: Boolean, default: false },
})

const emit = defineEmits(['upload'])

const initials = computed(() =>
  props.name
    .split(' ')
    .map((w) => w[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
)

function onFileChange(e) {
  const file = e.target.files[0]
  if (file) emit('upload', file)
}
</script>
