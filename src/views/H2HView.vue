<template>
  <div>
    <PageHeader title="Head-to-head" subtitle="Compare two players' record and rating history." />

    <form class="pickers" @submit.prevent="loadH2H">
      <FormField v-slot="{ id }" label="Player A">
        <select :id="id" v-model="playerAId" class="control">
          <option value="" disabled>Select player</option>
          <option v-for="p in players" :key="p.id" :value="p.id">{{ p.display_name }}</option>
        </select>
      </FormField>
      <span class="pickers__vs" aria-hidden="true">vs</span>
      <FormField v-slot="{ id }" label="Player B">
        <select :id="id" v-model="playerBId" class="control">
          <option value="" disabled>Select player</option>
          <option v-for="p in players" :key="p.id" :value="p.id">{{ p.display_name }}</option>
        </select>
      </FormField>
      <AppButton type="submit" :disabled="!canCompare" class="pickers__submit">Compare</AppButton>
    </form>

    <AppAlert v-if="error" class="h2h-error">{{ error }}</AppAlert>

    <div v-if="loaded">
      <AppCard class="versus">
        <div class="versus__side">
          <span class="versus__name">{{ playerA?.display_name }}</span>
          <span class="versus__wins num">{{ aWins }}</span>
        </div>
        <span class="versus__sep" aria-hidden="true">–</span>
        <div class="versus__side versus__side--right">
          <span class="versus__name">{{ playerB?.display_name }}</span>
          <span class="versus__wins num">{{ bWins }}</span>
        </div>
        <p class="versus__sets text-muted num">Sets: {{ totalSetsA }} – {{ totalSetsB }}</p>
      </AppCard>

      <SectionBlock title="Elo history">
        <AppCard>
          <EloChart :history="eloHistoryA" :history2="eloHistoryB" :label1="playerA?.display_name" :label2="playerB?.display_name" />
        </AppCard>
      </SectionBlock>

      <SectionBlock title="Match history">
        <EmptyState v-if="!h2hMatches.length" title="No matches between these players yet" />
        <ul v-else class="stack match-list">
          <li v-for="m in h2hMatches" :key="m.id"><MatchCard :match="m" :viewerId="playerAId" /></li>
        </ul>
      </SectionBlock>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import EloChart from '@/components/EloChart.vue'
import MatchCard from '@/components/MatchCard.vue'
import PageHeader from '@/components/PageHeader.vue'
import AppCard from '@/components/AppCard.vue'
import AppButton from '@/components/AppButton.vue'
import AppAlert from '@/components/AppAlert.vue'
import FormField from '@/components/FormField.vue'
import SectionBlock from '@/components/SectionBlock.vue'
import EmptyState from '@/components/EmptyState.vue'

const players = ref([])
const playerAId = ref('')
const playerBId = ref('')
const playerA = ref(null)
const playerB = ref(null)
const h2hMatches = ref([])
const eloHistoryA = ref([])
const eloHistoryB = ref([])
const loaded = ref(false)
const error = ref('')

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
  error.value = ''
  const aId = playerAId.value
  const bId = playerBId.value

  const results = await Promise.all([
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

  const failed = results.find((r) => r.error)
  if (failed) {
    error.value = `Couldn't load the comparison: ${failed.error.message}`
    return
  }
  const [{ data: pa }, { data: pb }, { data: matches }, { data: histA }, { data: histB }] = results

  playerA.value = pa
  playerB.value = pb
  h2hMatches.value = matches ?? []
  eloHistoryA.value = histA ?? []
  eloHistoryB.value = histB ?? []
  loaded.value = true
}

;(async () => {
  const { data, error: playersError } = await supabase.from('profiles').select('id, display_name').order('display_name')
  if (playersError) error.value = `Couldn't load players: ${playersError.message}`
  players.value = data ?? []
})()
</script>

<style scoped>
.h2h-error {
  margin-top: var(--space-4);
}
.pickers {
  display: grid;
  gap: var(--space-3);
}
.pickers__vs {
  justify-self: center;
  font-family: var(--font-display);
  font-weight: 700;
  color: var(--color-text-muted);
}

.versus {
  margin-top: var(--space-6);
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  gap: var(--space-3);
}
.versus__side {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  min-width: 0;
}
.versus__side--right {
  align-items: flex-end;
  text-align: right;
}
.versus__name {
  font-weight: 600;
  overflow-wrap: anywhere;
}
.versus__wins {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: var(--text-2xl);
  line-height: 1;
}
.versus__side:first-child .versus__wins {
  color: var(--color-accent-text);
}
.versus__sep {
  font-size: var(--text-xl);
  color: var(--color-text-muted);
}
.versus__sets {
  grid-column: 1 / -1;
  text-align: center;
  font-size: var(--text-sm);
}
.match-list {
  list-style: none;
  gap: var(--space-2);
}

@media (min-width: 40rem) {
  .pickers {
    grid-template-columns: 1fr auto 1fr auto;
    align-items: end;
  }
  .pickers__vs {
    padding-bottom: var(--space-3);
  }
}
</style>
