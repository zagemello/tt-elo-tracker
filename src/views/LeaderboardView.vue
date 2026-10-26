<template>
  <div class="page">
    <div class="page-header">
      <h2>Leaderboard</h2>
      <div class="filter-tabs">
        <button
          v-for="f in filters"
          :key="f.value"
          :class="{ active: activeFilter === f.value }"
          @click="setFilter(f.value)"
        >
          {{ f.label }}
        </button>
      </div>
    </div>

    <div v-if="leaderboard.loading" class="loading">Loading…</div>

    <table v-else class="leaderboard-table">
      <thead>
        <tr>
          <th>#</th>
          <th>Player</th>
          <th>Elo</th>
          <th>Games</th>
          <th>Win %</th>
          <th>Streak</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(player, idx) in leaderboard.players"
          :key="player.id"
          class="player-row"
          @click="$router.push(`/profile/${player.id}`)"
        >
          <td class="rank">{{ idx + 1 }}</td>
          <td class="player-cell">
            <PlayerAvatar :url="player.avatar_url" :name="player.display_name" :size="36" />
            <span>{{ player.display_name }}</span>
          </td>
          <td class="elo">{{ player.elo }}<span v-if="player.rd > 100" class="elo-uncertain" title="Rating still settling">?</span></td>
          <td>{{ player.matches_played }}</td>
          <td>{{ winRate(player) }}</td>
          <td>
            <span :class="streakClass(player)">{{ streakLabel(player) }}</span>
          </td>
        </tr>
        <tr v-if="leaderboard.players.length === 0">
          <td colspan="6" class="empty">No players yet.</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="page" style="margin-top: 0; padding-top: 0;">
    <h3>Recent Matches</h3>
    <div v-if="!matches.length" class="empty">No matches yet.</div>
    <div v-for="m in matches" :key="m.id" class="match-card admin-match-row">
      <div class="match-players">
        <span class="win-name">{{ m.winner.display_name }}</span>
        <span class="match-score">{{ m.winner_score }}–{{ m.loser_score }}</span>
        <span>{{ m.loser.display_name }}</span>
      </div>
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
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useLeaderboardStore } from '@/stores/leaderboard'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import PlayerAvatar from '@/components/PlayerAvatar.vue'

const leaderboard = useLeaderboardStore()
const auth = useAuthStore()
const activeFilter = ref('all')
const filters = [
  { label: 'All Time', value: 'all' },
  { label: 'Active (30d)', value: 'active' },
]

const matches = ref([])
const deleting = ref(null)

function setFilter(f) {
  activeFilter.value = f
  leaderboard.fetchPlayers(f)
}

function winRate(p) {
  if (!p.matches_played) return '—'
  return ((p.wins / p.matches_played) * 100).toFixed(0) + '%'
}

function streakLabel(p) {
  if (!p.current_streak) return '—'
  return p.current_streak > 0 ? `${p.current_streak}W` : `${Math.abs(p.current_streak)}L`
}

function streakClass(p) {
  if (!p.current_streak) return ''
  return p.current_streak > 0 ? 'streak-win' : 'streak-loss'
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })
}

async function fetchMatches() {
  const { data } = await supabase
    .from('matches')
    .select('*, winner:winner_id(display_name), loser:loser_id(display_name)')
    .order('played_at', { ascending: false })
    .limit(20)
  matches.value = data ?? []
}

async function deleteMatch(match) {
  if (!confirm(`Delete match: ${match.winner.display_name} vs ${match.loser.display_name}?\nThis will reverse the ELO changes.`)) return
  deleting.value = match.id
  const { error } = await supabase.rpc('delete_match', { p_match_id: match.id })
  if (error) { alert(error.message); deleting.value = null; return }
  matches.value = matches.value.filter((m) => m.id !== match.id)
  leaderboard.fetchPlayers(activeFilter.value)
  deleting.value = null
}

onMounted(() => {
  leaderboard.fetchPlayers()
  leaderboard.subscribeRealtime()
  fetchMatches()
})

onUnmounted(() => {
  leaderboard.unsubscribeRealtime()
})
</script>
