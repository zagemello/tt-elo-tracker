<template>
  <div class="page">
    <h2>Recent Matches</h2>

    <div v-if="loading" class="loading">Loading…</div>
    <div v-else>
      <div v-if="!matches.length" class="empty">No matches yet.</div>
      <div v-for="m in matches" :key="m.id" class="match-card match-card--detail">
        <div class="match-main">
          <div class="match-players">
            <div class="match-player">
              <span class="win-name">{{ m.winner.display_name }}</span>
              <span class="elo-delta elo-delta--gain">+{{ winnerDelta(m) }}</span>
            </div>
            <span class="match-score">{{ m.winner_score }}–{{ m.loser_score }}</span>
            <div class="match-player match-player--right">
              <span>{{ m.loser.display_name }}</span>
              <span class="elo-delta elo-delta--loss">−{{ loserDelta(m) }}</span>
            </div>
          </div>
          <div class="set-scores">{{ formatSets(m) }}</div>
        </div>
        <div class="match-meta">
          <span class="match-date">{{ formatDate(m.played_at) }}</span>
          <button
            v-if="auth.isAdmin"
            class="btn-danger"
            :disabled="deleting === m.id"
            @click="deleteMatch(m)"
          >
            {{ deleting === m.id ? '…' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const matches = ref([])
const loading = ref(true)
const deleting = ref(null)

async function fetchMatches() {
  const { data } = await supabase
    .from('matches')
    .select('*, winner:winner_id(display_name), loser:loser_id(display_name), match_sets(*)')
    .order('played_at', { ascending: false })
    .limit(50)
  matches.value = data ?? []
  loading.value = false
}

async function deleteMatch(match) {
  if (!confirm(`Delete match: ${match.winner.display_name} vs ${match.loser.display_name}?\nThis will reverse the ELO changes.`)) return
  deleting.value = match.id
  const { error } = await supabase.rpc('delete_match', { p_match_id: match.id })
  if (error) { alert(error.message); deleting.value = null; return }
  matches.value = matches.value.filter((m) => m.id !== match.id)
  deleting.value = null
}

function winnerDelta(m) {
  return m.winner_elo_after - m.winner_elo_before
}

function loserDelta(m) {
  return m.loser_elo_before - m.loser_elo_after
}

function formatSets(m) {
  if (!m.match_sets?.length) return ''
  return [...m.match_sets]
    .sort((a, b) => a.set_number - b.set_number)
    .map(s => `${s.winner_points}–${s.loser_points}`)
    .join(', ')
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
}

onMounted(fetchMatches)
</script>

<style scoped>
.match-card--detail {
  flex-direction: column;
  gap: 0.25rem;
}
.match-main {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
}
.match-players {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.match-player {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  flex: 1;
}
.match-player--right {
  justify-content: flex-end;
}
.elo-delta {
  font-size: 0.75rem;
  font-weight: 600;
  padding: 1px 5px;
  border-radius: 4px;
}
.elo-delta--gain {
  color: #4ade80;
  background: rgba(74, 222, 128, 0.12);
}
.elo-delta--loss {
  color: #f87171;
  background: rgba(248, 113, 113, 0.12);
}
.set-scores {
  font-size: 0.8rem;
  color: var(--color-text-muted, #888);
  letter-spacing: 0.01em;
}
.match-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 0.25rem;
}
</style>
