import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useLeaderboardStore = defineStore('leaderboard', () => {
  const players = ref([])
  const loading = ref(false)
  let subscription = null
  let activeFilter = 'all'

  async function fetchPlayers(filter = 'all') {
    activeFilter = filter
    loading.value = true
    let query = supabase.from('profiles').select('*').order('elo', { ascending: false })

    if (filter === 'active') {
      const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
      const { data: activeIds } = await supabase
        .from('matches')
        .select('winner_id, loser_id')
        .gte('played_at', cutoff)
      if (activeIds) {
        const ids = [...new Set(activeIds.flatMap((m) => [m.winner_id, m.loser_id]))]
        query = query.in('id', ids)
      }
    }

    const { data } = await query
    players.value = data ?? []
    loading.value = false
  }

  function subscribeRealtime() {
    if (subscription) return
    subscription = supabase
      .channel('leaderboard-profiles')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
        fetchPlayers(activeFilter)
      })
      .subscribe()
  }

  function unsubscribeRealtime() {
    if (subscription) {
      supabase.removeChannel(subscription)
      subscription = null
    }
  }

  return { players, loading, fetchPlayers, subscribeRealtime, unsubscribeRealtime }
})
