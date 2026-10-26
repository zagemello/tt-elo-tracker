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
          <td class="elo">{{ player.elo }}</td>
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
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useLeaderboardStore } from '@/stores/leaderboard'
import PlayerAvatar from '@/components/PlayerAvatar.vue'

const leaderboard = useLeaderboardStore()
const activeFilter = ref('all')
const filters = [
  { label: 'All Time', value: 'all' },
  { label: 'Active (30d)', value: 'active' },
]

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

onMounted(() => {
  leaderboard.fetchPlayers()
  leaderboard.subscribeRealtime()
})

onUnmounted(() => {
  leaderboard.unsubscribeRealtime()
})
</script>
