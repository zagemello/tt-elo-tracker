<template>
  <div class="page">
    <div v-if="loading" class="loading">Loading…</div>
    <template v-else-if="player">
      <div class="profile-header">
        <PlayerAvatar
          :url="player.avatar_url"
          :name="player.display_name"
          :size="80"
          :editable="isOwnProfile"
          @upload="handleAvatarUpload"
        />
        <div class="profile-info">
          <h2>{{ player.display_name }}</h2>
          <div class="stats-row">
            <div class="stat">
              <span class="stat-value">{{ player.elo }}<span v-if="player.rd > 100" class="elo-uncertain" title="Rating still settling">?</span></span>
              <span class="stat-label">Elo</span>
            </div>
            <div class="stat">
              <span class="stat-value">{{ player.peak_elo }}</span>
              <span class="stat-label">Peak Elo</span>
            </div>
            <div class="stat">
              <span class="stat-value">{{ player.matches_played }}</span>
              <span class="stat-label">Games</span>
            </div>
            <div class="stat">
              <span class="stat-value">{{ winRate }}</span>
              <span class="stat-label">Win Rate</span>
            </div>
            <div class="stat">
              <span class="stat-value" :class="streakClass">{{ streakLabel }}</span>
              <span class="stat-label">Streak</span>
            </div>
          </div>
        </div>
      </div>

      <div class="section">
        <h3>Elo Progression</h3>
        <EloChart :history="eloHistory" />
      </div>

      <div class="section">
        <h3>Recent Matches</h3>
        <MatchCard
          v-for="m in recentMatches"
          :key="m.id"
          :match="m"
          :viewerId="player.id"
        />
        <p v-if="!recentMatches.length" class="empty">No matches yet.</p>
      </div>
    </template>
    <p v-else class="empty">Player not found.</p>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import PlayerAvatar from '@/components/PlayerAvatar.vue'
import EloChart from '@/components/EloChart.vue'
import MatchCard from '@/components/MatchCard.vue'

const route = useRoute()
const auth = useAuthStore()
const player = ref(null)
const eloHistory = ref([])
const recentMatches = ref([])
const loading = ref(true)

const isOwnProfile = computed(() => auth.session?.user.id === route.params.id)

const winRate = computed(() => {
  if (!player.value?.matches_played) return '—'
  return ((player.value.wins / player.value.matches_played) * 100).toFixed(0) + '%'
})

const streakLabel = computed(() => {
  const s = player.value?.current_streak
  if (!s) return '—'
  return s > 0 ? `${s}W` : `${Math.abs(s)}L`
})

const streakClass = computed(() => {
  const s = player.value?.current_streak
  if (!s) return ''
  return s > 0 ? 'streak-win' : 'streak-loss'
})

async function load() {
  const id = route.params.id
  const [{ data: p }, { data: hist }, { data: matches }] = await Promise.all([
    supabase.from('profiles').select('*').eq('id', id).single(),
    supabase
      .from('elo_history')
      .select('new_elo, recorded_at')
      .eq('player_id', id)
      .order('recorded_at', { ascending: true }),
    supabase
      .from('matches')
      .select(
        '*, winner:winner_id(display_name, avatar_url), loser:loser_id(display_name, avatar_url)'
      )
      .or(`winner_id.eq.${id},loser_id.eq.${id}`)
      .order('played_at', { ascending: false })
      .limit(15),
  ])
  player.value = p
  eloHistory.value = hist ?? []
  recentMatches.value = matches ?? []
  loading.value = false
}

async function handleAvatarUpload(file) {
  const compressed = await compressImage(file, 500 * 1024)
  const path = `${auth.session.user.id}/avatar.jpg`
  const { error: uploadErr } = await supabase.storage
    .from('avatars')
    .upload(path, compressed, { upsert: true, contentType: 'image/jpeg' })
  if (uploadErr) { alert(uploadErr.message); return }

  const { data } = supabase.storage.from('avatars').getPublicUrl(path)
  await auth.updateProfile({ avatar_url: data.publicUrl })
  player.value = { ...player.value, avatar_url: data.publicUrl }
}

function compressImage(file, maxBytes) {
  return new Promise((resolve) => {
    const img = new Image()
    const url = URL.createObjectURL(file)
    img.onload = () => {
      let { width, height } = img
      const canvas = document.createElement('canvas')
      const MAX_DIM = 400
      if (width > MAX_DIM || height > MAX_DIM) {
        const ratio = Math.min(MAX_DIM / width, MAX_DIM / height)
        width = Math.round(width * ratio)
        height = Math.round(height * ratio)
      }
      canvas.width = width
      canvas.height = height
      canvas.getContext('2d').drawImage(img, 0, 0, width, height)
      canvas.toBlob((blob) => resolve(blob), 'image/jpeg', 0.82)
      URL.revokeObjectURL(url)
    }
    img.src = url
  })
}

onMounted(load)
</script>
