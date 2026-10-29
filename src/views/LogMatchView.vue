<template>
  <div>
    <PageHeader title="Log a match" subtitle="Enter the points for each set. Elo updates right away." />

    <AppCard class="form-card">
      <form class="stack form" @submit.prevent="handleSubmit">
        <div class="players">
          <FormField v-slot="{ id }" label="Winner">
            <select :id="id" v-model="winnerId" class="control" required>
              <option value="" disabled>Select winner</option>
              <option v-for="p in availablePlayers" :key="p.id" :value="p.id">{{ p.display_name }} ({{ p.elo }})</option>
            </select>
          </FormField>
          <span class="players__vs" aria-hidden="true">vs</span>
          <FormField v-slot="{ id }" label="Loser">
            <select :id="id" v-model="loserId" class="control" required>
              <option value="" disabled>Select loser</option>
              <option v-for="p in availablePlayers" :key="p.id" :value="p.id">{{ p.display_name }} ({{ p.elo }})</option>
            </select>
          </FormField>
        </div>

        <AppAlert v-if="samePlayerError">Winner and loser must be different players.</AppAlert>

        <fieldset class="sets">
          <legend class="sets__legend">Sets <span class="text-muted">(winner – loser points)</span></legend>
          <SetScoreInput
            v-for="(set, i) in sets"
            :key="i"
            :index="i"
            :modelValue="set"
            :removable="i > 0"
            @update:modelValue="sets[i] = $event"
            @remove="removeSet(i)"
          />
          <AppButton variant="secondary" size="sm" class="sets__add" @click="addSet">Add set</AppButton>
        </fieldset>

        <AppAlert v-if="setErrors.length">
          <span v-for="e in setErrors" :key="e" class="block">{{ e }}</span>
        </AppAlert>
        <AppAlert v-if="submitError">{{ submitError }}</AppAlert>
        <AppAlert v-if="successMsg" tone="success">{{ successMsg }}</AppAlert>

        <AppButton type="submit" block :loading="submitting" :disabled="samePlayerError">
          {{ submitting ? 'Saving…' : 'Record match' }}
        </AppButton>
      </form>
    </AppCard>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import PageHeader from '@/components/PageHeader.vue'
import AppCard from '@/components/AppCard.vue'
import AppButton from '@/components/AppButton.vue'
import AppAlert from '@/components/AppAlert.vue'
import FormField from '@/components/FormField.vue'
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

    const winnerSets = sets.value.filter((s) => parseInt(s.winnerPoints) > parseInt(s.loserPoints)).length
    const loserSets  = sets.value.filter((s) => parseInt(s.loserPoints) > parseInt(s.winnerPoints)).length

    const { data, error } = await supabase.rpc('record_match', {
      p_winner_id:        winnerId.value,
      p_loser_id:         loserId.value,
      p_winner_score:     winnerSets,
      p_loser_score:      loserSets,
      p_total_winner_pts: totalWinnerPts,
      p_total_loser_pts:  totalLoserPts,
      p_sets: sets.value.map((s) => ({
        winner_points: parseInt(s.winnerPoints),
        loser_points:  parseInt(s.loserPoints),
      })),
    })
    if (error) throw error

    const winnerProfile = players.value.find((p) => p.id === winnerId.value)
    successMsg.value = `Match recorded! +ELO for ${winnerProfile.display_name}`
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

<style scoped>
.form-card {
  max-width: 34rem;
}
.form {
  gap: var(--space-5);
}
.players {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-3);
}
.players__vs {
  justify-self: center;
  font-family: var(--font-display);
  font-weight: 700;
  color: var(--color-text-muted);
}
.sets {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  border: 0;
  min-width: 0;
}
.sets__legend {
  margin-bottom: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
}
.sets__add {
  align-self: flex-start;
  margin-top: var(--space-2);
}
.block {
  display: block;
}

@media (min-width: 40rem) {
  .players {
    grid-template-columns: 1fr auto 1fr;
    align-items: end;
  }
  .players__vs {
    padding-bottom: var(--space-3);
  }
}
</style>
