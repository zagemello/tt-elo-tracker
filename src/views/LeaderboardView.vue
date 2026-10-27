<template>
  <div>
    <PageHeader title="Leaderboard" subtitle="Ranked by Elo. Tap a player to see their history.">
      <SegmentedControl v-model="activeFilter" :options="filters" label="Time range" @update:modelValue="leaderboard.fetchPlayers" />
    </PageHeader>

    <LoadingState v-if="leaderboard.loading" />

    <EmptyState v-else-if="!leaderboard.players.length" title="No players yet">
      Create an account to join the leaderboard.
      <template #action><AppButton to="/login">Sign up</AppButton></template>
    </EmptyState>

    <AppCard v-else flush as="ol" class="board">
      <li class="board__head" aria-hidden="true">
        <span>#</span>
        <span>Player</span>
        <span class="board__col">Games</span>
        <span class="board__col">Win %</span>
        <span class="board__col">Streak</span>
        <span class="board__elo">Elo</span>
      </li>
      <li v-for="(player, idx) in leaderboard.players" :key="player.id">
        <RouterLink :to="`/profile/${player.id}`" class="row" :class="{ 'row--leader': idx === 0 }">
          <span class="row__rank num">{{ idx + 1 }}</span>
          <span class="row__player">
            <PlayerAvatar :url="player.avatar_url" :name="player.display_name" :size="40" />
            <span class="row__text">
              <span class="row__name">{{ player.display_name }}</span>
              <span class="row__sub num">{{ player.matches_played }} games · {{ winRate(player) }}</span>
            </span>
          </span>
          <span class="row__col num">{{ player.matches_played }}</span>
          <span class="row__col num">{{ winRate(player) }}</span>
          <span class="row__col num" :class="streakTone(player) && `text-${streakTone(player)}`">{{ streakLabel(player) }}</span>
          <span class="row__elo num">
            {{ player.elo }}<span v-if="player.rd > 100" class="row__unsure" title="Rating still settling">?</span>
          </span>
        </RouterLink>
      </li>
    </AppCard>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useLeaderboardStore } from '@/stores/leaderboard'
import { winRate, streakLabel, streakTone } from '@/lib/format'
import PageHeader from '@/components/PageHeader.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import LoadingState from '@/components/LoadingState.vue'
import EmptyState from '@/components/EmptyState.vue'
import AppButton from '@/components/AppButton.vue'
import AppCard from '@/components/AppCard.vue'
import PlayerAvatar from '@/components/PlayerAvatar.vue'

const leaderboard = useLeaderboardStore()
const activeFilter = ref('all')
const filters = [
  { label: 'All time', value: 'all' },
  { label: 'Last 30 days', value: 'active' },
]

onMounted(() => {
  leaderboard.fetchPlayers()
  leaderboard.subscribeRealtime()
})

onUnmounted(() => {
  leaderboard.unsubscribeRealtime()
})
</script>

<style scoped>
.board {
  list-style: none;
}

/* Shared column template so header and rows align */
.board__head,
.row {
  display: grid;
  grid-template-columns: 1.75rem 1fr auto;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
}
.board__head {
  display: none;
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--color-text-muted);
  border-bottom: 1px solid var(--color-line);
}
.board li + li .row {
  border-top: 1px solid var(--color-line);
}

.row {
  color: var(--color-text);
  min-height: 4rem;
  transition: background var(--duration-fast) var(--ease);
}
.row:hover {
  text-decoration: none;
  background: var(--color-surface-raised);
}
.row--leader {
  box-shadow: inset 4px 0 0 var(--color-accent);
}

.row__rank {
  font-family: var(--font-display);
  font-weight: 700;
  color: var(--color-text-muted);
}
.row--leader .row__rank {
  color: var(--color-accent-text);
}
.row__player {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  min-width: 0;
}
.row__text {
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.row__name {
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.row__sub {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}
.row__col {
  display: none;
}
.row__elo,
.board__elo {
  text-align: right;
}
.row__elo {
  font-family: var(--font-display);
  font-size: var(--text-lg);
  font-weight: 800;
}
.row__unsure {
  margin-left: 2px;
  font-size: var(--text-sm);
  color: var(--color-text-muted);
}

@media (min-width: 40rem) {
  .board__head,
  .row {
    grid-template-columns: 2rem 1fr 4.5rem 4.5rem 4.5rem 4.5rem;
  }
  .board__head {
    display: grid;
  }
  .row__col,
  .board__col {
    display: block;
    text-align: right;
  }
  .row__sub {
    display: none;
  }
}
</style>
