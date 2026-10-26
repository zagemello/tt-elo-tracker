<template>
  <div class="page">
    <h2>Head-to-Head</h2>

    <div class="h2h-pickers">
      <div class="field">
        <label>Player A</label>
        <select v-model="playerAId">
          <option value="" disabled>Select player</option>
          <option v-for="p in players" :key="p.id" :value="p.id">{{ p.display_name }}</option>
        </select>
      </div>
      <div class="vs">vs</div>
      <div class="field">
        <label>Player B</label>
        <select v-model="playerBId">
          <option value="" disabled>Select player</option>
          <option v-for="p in players" :key="p.id" :value="p.id">{{ p.display_name }}</option>
        </select>
      </div>
    </div>

    <button class="btn-primary" :disabled="!canCompare" @click="loadH2H">Compare</button>

    <div v-if="loaded" class="h2h-results">
      <div class="h2h-summary">
        <div class="h2h-side">
          <span class="h2h-name">{{ playerA?.display_name }}</span>
          <span class="h2h-wins">{{ aWins }} W</span>
        </div>
        <div class="h2h-divider">—</div>
        <div class="h2h-side">
          <span class="h2h-wins">{{ bWins }} W</span>
          <span class="h2h-name">{{ playerB?.display_name }}</span>
        </div>
      </div>

      <div class="section">
        <h3>Set Differential</h3>
        <p>
          {{ playerA?.display_name }} {{ totalSetsA }} – {{ totalSetsB }}
          {{ playerB?.display_name }}
        </p>
      </div>

      <div class="section">
        <h3>Elo History</h3>
        <EloChart :history="eloHistoryA" :history2="eloHistoryB" :label2="playerB?.display_name" :label1="playerA?.display_name" />
      </div>

      <div class="section">
        <h3>Match History</h3>
        <MatchCard v-for="m in h2hMatches" :key="m.id" :match="m" :viewerId="playerAId" />
        <p v-if="!h2hMatches.length" class="empty">No matches between these players yet.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import EloChart from '@/components/EloChart.vue'
import MatchCard from '@/components/MatchCard.vue'

const players = ref([])
const playerAId = ref('')
const playerBId = ref('')
const playerA = ref(null)
const playerB = ref(null)
const h2hMatches = ref([])
const eloHistoryA = ref([])
const eloHistoryB = ref([])
const loaded = ref(false)

const canCompare = computed(() => playerAId.value && playerBId.value && playerAId.value !== playerBId.value)

const aWins = computed(() => h2hMatches.value.filter((m) => m.winner_id === playerAId.value).length)
const bWins = computed(() => h2hMatches.value.filter((m) => m.winner_id === playerBId.value).length)

const totalSetsA = computed(() =>
  h2hMatches.value.reduce((acc, m) => acc + (m.winner_id === playerAId.value ? m.winner_score : m.loser_score), 0)
)
const totalSetsB = computed(() =>
  h2hMatches.value.reduce((acc, m) => acc + (m.winner_id === playerBId.value ? m.winner_score : m.loser_score), 0)
)

async function loadH2H() {
  loaded.value = false
  const aId = playerAId.value
  const bId = playerBId.value

  const [{ data: pa }, { data: pb }, { data: matches }, { data: histA }, { data: histB }] =
    await Promise.all([
      supabase.from('profiles').select('*').eq('id', aId).single(),
      supabase.from('profiles').select('*').eq('id', bId).single(),
      supabase
        .from('matches')
        .select('*, winner:winner_id(display_name, avatar_url), loser:loser_id(display_name, avatar_url)')
        .or(
          `and(winner_id.eq.${aId},loser_id.eq.${bId}),and(winner_id.eq.${bId},loser_id.eq.${aId})`
        )
        .order('played_at', { ascending: false }),
      supabase
        .from('elo_history')
        .select('new_elo, recorded_at')
        .eq('player_id', aId)
        .order('recorded_at', { ascending: true }),
      supabase
        .from('elo_history')
        .select('new_elo, recorded_at')
        .eq('player_id', bId)
        .order('recorded_at', { ascending: true }),
    ])

  playerA.value = pa
  playerB.value = pb
  h2hMatches.value = matches ?? []
  eloHistoryA.value = histA ?? []
  eloHistoryB.value = histB ?? []
  loaded.value = true
}

;(async () => {
  const { data } = await supabase.from('profiles').select('id, display_name').order('display_name')
  players.value = data ?? []
})()
</script>
