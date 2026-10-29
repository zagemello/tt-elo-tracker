import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

/** Recent matches list with admin delete, shared by the Matches and Admin views. */
export function useMatches({ limit = 50 } = {}) {
  const matches = ref([])
  const loading = ref(true)
  const deletingId = ref(null)
  const error = ref('')

  async function fetchMatches() {
    const { data, error: fetchError } = await supabase
      .from('matches')
      .select('*, winner:winner_id(display_name, avatar_url), loser:loser_id(display_name, avatar_url)')
      .order('played_at', { ascending: false })
      .limit(limit)
    if (fetchError) error.value = `Couldn't load matches: ${fetchError.message}`
    matches.value = data ?? []
    loading.value = false
  }

  async function deleteMatch(match) {
    const label = `${match.winner.display_name} vs ${match.loser.display_name}`
    if (!confirm(`Delete match: ${label}?\nThis will reverse the ELO changes.`)) return
    error.value = ''
    deletingId.value = match.id
    const { error: rpcError } = await supabase.rpc('delete_match', { p_match_id: match.id })
    if (rpcError) error.value = rpcError.message
    else matches.value = matches.value.filter((m) => m.id !== match.id)
    deletingId.value = null
  }

  onMounted(fetchMatches)

  return { matches, loading, deletingId, error, deleteMatch }
}
