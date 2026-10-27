<template>
  <div class="page">
    <h2>Admin Panel</h2>

    <div class="section">
      <h3>Recent Matches</h3>
      <p class="admin-note">Deleting a match reverses its ELO impact. If other matches happened after it, those ELOs may be slightly off.</p>

      <div v-if="loading" class="loading">Loading…</div>

      <div v-else>
        <div
          v-for="m in matches"
          :key="m.id"
          class="match-card admin-match-row"
        >
          <div class="match-players">
              <span class="win-name">{{ m.winner.display_name }}</span>
              <span class="match-score">{{ m.winner_score }}–{{ m.loser_score }}</span>
              <span>{{ m.loser.display_name }}</span>
            </div>
            <div v-if="formatSets(m)" class="set-scores">{{ formatSets(m) }}</div>
            <div class="elo-changes">
              <span class="elo-delta elo-delta--gain">{{ m.winner.display_name }} +{{ m.winner_elo_after - m.winner_elo_before }}</span>
              <span class="elo-delta elo-delta--loss">{{ m.loser.display_name }} −{{ m.loser_elo_before - m.loser_elo_after }}</span>
            </div>
          <span class="match-date">{{ formatDate(m.played_at) }}</span>
          <button class="btn-danger" :disabled="deleting === m.id" @click="deleteMatch(m)">
            {{ deleting === m.id ? 'Deleting…' : 'Delete' }}
          </button>
        </div>

        <p v-if="!matches.length" class="empty">No matches yet.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

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
.set-scores {
  font-size: 0.8rem;
  color: #888;
  margin-top: 0.15rem;
}
.elo-changes {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.2rem;
}
.elo-delta {
  font-size: 0.75rem;
  font-weight: 600;
  padding: 1px 5px;
  border-radius: 4px;
}
.elo-delta--gain { color: #4ade80; background: rgba(74,222,128,0.12); }
.elo-delta--loss { color: #f87171; background: rgba(248,113,113,0.12); }
</style>
