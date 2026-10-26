<template>
  <div class="match-card" :class="{ won: isWin, lost: !isWin }">
    <div class="match-result-badge">{{ isWin ? 'W' : 'L' }}</div>
    <div class="match-players">
      <span class="match-name">{{ match.winner?.display_name ?? '?' }}</span>
      <span class="match-score">{{ match.winner_score }} – {{ match.loser_score }}</span>
      <span class="match-name">{{ match.loser?.display_name ?? '?' }}</span>
    </div>
    <div class="match-elo-delta">
      <span v-if="isWin" class="elo-gain">+{{ match.winner_elo_after - match.winner_elo_before }}</span>
      <span v-else class="elo-loss">{{ match.loser_elo_after - match.loser_elo_before }}</span>
    </div>
    <div class="match-date">{{ formatDate(match.played_at) }}</div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  match: { type: Object, required: true },
  viewerId: { type: String, default: null },
})

const isWin = computed(() => props.match.winner_id === props.viewerId)

function formatDate(iso) {
  return new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: '2-digit' })
}
</script>
