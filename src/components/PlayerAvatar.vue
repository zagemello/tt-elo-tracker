<template>
  <div class="avatar" :style="{ '--size': size + 'px' }">
    <img v-if="url" :src="url" :alt="name" class="avatar__img" />
    <span v-else class="avatar__initials" aria-hidden="true">{{ initials }}</span>
    <label v-if="editable" class="avatar__upload">
      <input type="file" accept="image/*" class="visually-hidden" @change="onFileChange" />
      <AppIcon name="camera" :size="size > 60 ? 18 : 14" />
      <span class="visually-hidden">Upload avatar</span>
    </label>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import AppIcon from './AppIcon.vue'

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
    .slice(0, 2),
)

function onFileChange(e) {
  const file = e.target.files[0]
  if (file) emit('upload', file)
}
</script>

<style scoped>
.avatar {
  position: relative;
  flex-shrink: 0;
  display: grid;
  place-items: center;
  width: var(--size);
  height: var(--size);
  border-radius: 50%;
  background: var(--color-surface-raised);
  border: 1px solid var(--color-line);
  overflow: hidden;
}
.avatar__img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.avatar__initials {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: calc(var(--size) * 0.38);
  color: var(--color-accent-text);
}
.avatar__upload {
  position: absolute;
  inset: auto 0 0 0;
  display: grid;
  place-items: center;
  padding: 4px 0;
  background: rgb(0 0 0 / 0.6);
  color: #fff;
  cursor: pointer;
}
.avatar__upload:focus-within {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}
/* Hover-only affordances don't exist on touch, so the button stays visible there */
@media (hover: hover) {
  .avatar__upload {
    opacity: 0;
    transition: opacity var(--duration-fast) var(--ease);
  }
  .avatar:hover .avatar__upload,
  .avatar__upload:focus-within {
    opacity: 1;
  }
}
</style>
