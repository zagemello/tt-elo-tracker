<template>
  <div class="page">
    <h2>Log a Match</h2>

    <form @submit.prevent="handleSubmit" class="match-form">
      <div class="players-row">
        <div class="field">
          <label>Winner</label>
          <select v-model="winnerId" required>
            <option value="" disabled>Select winner</option>
            <option v-for="p in availablePlayers" :key="p.id" :value="p.id">
              {{ p.display_name }} ({{ p.elo }})
            </option>
          </select>
        </div>
        <div class="vs">vs</div>
        <div class="field">
          <label>Loser</label>
          <select v-model="loserId" required>
            <option value="" disabled>Select loser</option>
            <option v-for="p in availablePlayers" :key="p.id" :value="p.id">
              {{ p.display_name }} ({{ p.elo }})
            </option>
          </select>
        </div>
      </div>

      <p v-if="samePlayerError" class="error-msg">Winner and loser must be different players.</p>

      <div class="sets-section">
        <h3>Sets</h3>
        <SetScoreInput
          v-for="(set, i) in sets"
          :key="i"
          :index="i"
          :modelValue="set"
          :winnerId="winnerId"
          @update:modelValue="sets[i] = $event"
          @remove="removeSet(i)"
        />
        <button type="button" class="btn-secondary" @click="addSet">+ Add Set</button>
      </div>

      <div v-if="setErrors.length" class="error-msg">
        <p v-for="e in setErrors" :key="e">{{ e }}</p>
      </div>

      <p v-if="submitError" class="error-msg">{{ submitError }}</p>
      <p v-if="successMsg" class="success-msg">{{ successMsg }}</p>

      <button type="submit" class="btn-primary" :disabled="submitting || samePlayerError">
        {{ submitting ? 'Saving…' : 'Record Match' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import SetScoreInput from '@/components/SetScoreInput.vue'

const players = ref([])
const winnerId = ref('')
const loserId = ref('')
const sets = ref([{ winnerPoints: '', loserPoints: '' }])
const submitting = ref(false)
const submitError = ref('')
const successMsg = ref('')

const availablePlayers = computed(() => players.value)
const samePlayerError = computed(() => winnerId.value && winnerId.value === loserId.value)

const setErrors = computed(() => {
  const errors = []
  sets.value.forEach((s, i) => {
    const w = parseInt(s.winnerPoints)
    const l = parseInt(s.loserPoints)
    if (isNaN(w) || isNaN(l)) return
    const hi = Math.max(w, l)
    const lo = Math.min(w, l)
    if (hi < 11) errors.push(`Set ${i + 1}: points must reach at least 11.`)
    else if (hi - lo < 2) errors.push(`Set ${i + 1}: winner must lead by at least 2 points.`)
    if (w <= l) errors.push(`Set ${i + 1}: winner's points must be higher than loser's.`)
  })
  return errors
})

function addSet() {
  sets.value.push({ winnerPoints: '', loserPoints: '' })
}

function removeSet(i) {
  if (sets.value.length > 1) sets.value.splice(i, 1)
}

async function handleSubmit() {
  submitError.value = ''
  successMsg.value = ''

  if (samePlayerError.value) return
  if (setErrors.value.length) return

  submitting.value = true
  try {
    const totalWinnerPts = sets.value.reduce((s, set) => s + parseInt(set.winnerPoints), 0)
    const totalLoserPts = sets.value.reduce((s, set) => s + parseInt(set.loserPoints), 0)

    const { data: eloResult, error: rpcErr } = await supabase.rpc('calculate_elo_update', {
      p_winner_id: winnerId.value,
      p_loser_id: loserId.value,
      p_total_winner_points: totalWinnerPts,
      p_total_loser_points: totalLoserPts,
    })
    if (rpcErr) throw rpcErr

    const { new_winner_elo, new_loser_elo, new_winner_rd, new_loser_rd, eff_winner_elo, eff_loser_elo } = eloResult[0]

    const winnerProfile = players.value.find((p) => p.id === winnerId.value)
    const loserProfile = players.value.find((p) => p.id === loserId.value)
    const now = new Date().toISOString()

    const { data: match, error: matchErr } = await supabase
      .from('matches')
      .insert({
        winner_id: winnerId.value,
        loser_id: loserId.value,
        winner_score: sets.value.filter((s) => parseInt(s.winnerPoints) > parseInt(s.loserPoints)).length,
        loser_score: sets.value.filter((s) => parseInt(s.loserPoints) > parseInt(s.winnerPoints)).length,
        winner_elo_before: eff_winner_elo,
        loser_elo_before: eff_loser_elo,
        winner_elo_after: new_winner_elo,
        loser_elo_after: new_loser_elo,
      })
      .select()
      .single()
    if (matchErr) throw matchErr

    await supabase.from('match_sets').insert(
      sets.value.map((s, i) => ({
        match_id: match.id,
        set_number: i + 1,
        winner_points: parseInt(s.winnerPoints),
        loser_points: parseInt(s.loserPoints),
      }))
    )

    await supabase.from('elo_history').insert([
      { player_id: winnerId.value, match_id: match.id, new_elo: new_winner_elo },
      { player_id: loserId.value, match_id: match.id, new_elo: new_loser_elo },
    ])

    const newWinnerStreak = winnerProfile.current_streak >= 0 ? winnerProfile.current_streak + 1 : 1
    const newLoserStreak = loserProfile.current_streak <= 0 ? loserProfile.current_streak - 1 : -1

    await Promise.all([
      supabase
        .from('profiles')
        .update({
          elo: new_winner_elo,
          rd: new_winner_rd,
          last_played_at: now,
          peak_elo: Math.max(winnerProfile.peak_elo, new_winner_elo),
          matches_played: winnerProfile.matches_played + 1,
          wins: winnerProfile.wins + 1,
          current_streak: newWinnerStreak,
        })
        .eq('id', winnerId.value),
      supabase
        .from('profiles')
        .update({
          elo: new_loser_elo,
          rd: new_loser_rd,
          last_played_at: now,
          matches_played: loserProfile.matches_played + 1,
          losses: loserProfile.losses + 1,
          current_streak: newLoserStreak,
        })
        .eq('id', loserId.value),
    ])

    successMsg.value = `Match recorded! ${winnerProfile.display_name} +${new_winner_elo - eff_winner_elo} Elo`
    winnerId.value = ''
    loserId.value = ''
    sets.value = [{ winnerPoints: '', loserPoints: '' }]
  } catch (e) {
    submitError.value = e.message
  } finally {
    submitting.value = false
  }
}

onMounted(async () => {
  const { data } = await supabase.from('profiles').select('*').order('display_name')
  players.value = data ?? []
})
</script>
