<template>
  <article class="match" :class="{ 'is-win': outcome === 'win', 'is-loss': outcome === 'loss' }">
    <div class="match__score">
      <div class="match__row match__row--winner">
        <span class="match__name">{{ match.winner?.display_name ?? '?' }}</span>
        <span class="match__sets num">{{ match.winner_score }}</span>
      </div>
      <div class="match__row">
        <span class="match__name">{{ match.loser?.display_name ?? '?' }}</span>
        <span class="match__sets num">{{ match.loser_score }}</span>
      </div>
    </div>

    <div class="match__meta">
      <span v-if="delta !== null" class="match__delta num" :class="delta >= 0 ? 'text-win' : 'text-loss'">
        {{ delta > 0 ? '+' : '' }}{{ delta }}
      </span>
      <time class="match__date" :datetime="match.played_at">{{ formatDate(match.played_at) }}</time>
    </div>

    <div v-if="$slots.actions" class="match__actions"><slot name="actions" /></div>
  </article>
</template>

<script setup>
import { computed } from 'vue'
import { formatDate } from '@/lib/format'

const props = defineProps({
  match: { type: Object, required: true },
  /** When set, the card is shown from this player's perspective (win/loss tint + Elo change). */
  viewerId: { type: String, default: null },
})

const outcome = computed(() => {
  if (!props.viewerId) return null
  return props.match.winner_id === props.viewerId ? 'win' : 'loss'
})

const delta = computed(() => {
  const m = props.match
  if (outcome.value === 'win') return m.winner_elo_after - m.winner_elo_before
  if (outcome.value === 'loss') return m.loser_elo_after - m.loser_elo_before
  return null
})
</script>

<style scoped>
.match {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--color-surface);
  border: 1px solid var(--color-line);
  border-left-width: 4px;
  border-radius: var(--radius-md);
}
.match.is-win {
  border-left-color: var(--color-win);
}
.match.is-loss {
  border-left-color: var(--color-loss);
}

.match__score {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.match__row {
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);
  color: var(--color-text-muted);
}
.match__row--winner {
  color: var(--color-text);
  font-weight: 600;
}
.match__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.match__sets {
  font-family: var(--font-display);
  font-weight: 700;
}

.match__meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  font-size: var(--text-sm);
}
.match__delta {
  font-weight: 700;
}
.match__date {
  color: var(--color-text-muted);
  font-size: var(--text-xs);
  white-space: nowrap;
}

.match__actions {
  flex-shrink: 0;
}
</style>
