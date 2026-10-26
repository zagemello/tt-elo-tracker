<template>
  <div class="page">
    <h2>Admin Panel</h2>

    <div class="section">
      <h3>Recent Matches</h3>
      <p class="admin-note">Deleting a match removes the record but does not recalculate ELO history.</p>

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
    .select('*, winner:winner_id(display_name), loser:loser_id(display_name)')
    .order('played_at', { ascending: false })
    .limit(50)
  matches.value = data ?? []
  loading.value = false
}

async function deleteMatch(match) {
  if (!confirm(`Delete match: ${match.winner.display_name} vs ${match.loser.display_name}?`)) return
  deleting.value = match.id
  const { error } = await supabase.from('matches').delete().eq('id', match.id)
  if (error) { alert(error.message); deleting.value = null; return }
  matches.value = matches.value.filter((m) => m.id !== match.id)
  deleting.value = null
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
}

onMounted(fetchMatches)
</script>
