<template>
  <div>
    <LoadingState v-if="loading" />
    <template v-else-if="player">
      <AppCard class="hero">
        <div class="hero__who">
          <PlayerAvatar
            :url="player.avatar_url"
            :name="player.display_name"
            :size="72"
            :editable="isOwnProfile"
            @upload="handleAvatarUpload"
          />
          <h1 class="hero__name">{{ player.display_name }}</h1>
        </div>

        <div class="hero__elo">
          <span class="hero__elo-value num">
            {{ player.elo }}<span v-if="player.rd > 100" class="hero__unsure" title="Rating still settling">?</span>
          </span>
          <span class="hero__elo-label">Elo</span>
        </div>

        <div class="hero__stats">
          <StatTile label="Peak" :value="player.peak_elo" />
          <StatTile label="Games" :value="player.matches_played" />
          <StatTile label="Win rate" :value="winRate" />
          <StatTile label="Streak" :value="streakLabel" :tone="streakClass" />
        </div>
      </AppCard>

      <AppAlert v-if="uploadError" class="upload-error">{{ uploadError }}</AppAlert>

      <SectionBlock title="Elo progression">
        <AppCard>
          <EmptyState v-if="!eloHistory.length" title="No rating history yet" />
          <EloChart v-else :history="eloHistory" :label1="player.display_name" />
        </AppCard>
      </SectionBlock>

      <SectionBlock title="Recent matches">
        <EmptyState v-if="!recentMatches.length" title="No matches yet" />
        <ul v-else class="stack match-list">
          <li v-for="m in recentMatches" :key="m.id"><MatchCard :match="m" :viewerId="player.id" /></li>
        </ul>
      </SectionBlock>
    </template>
    <EmptyState v-else title="Player not found" />
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
import AppCard from '@/components/AppCard.vue'
import AppAlert from '@/components/AppAlert.vue'
import StatTile from '@/components/StatTile.vue'
import SectionBlock from '@/components/SectionBlock.vue'
import LoadingState from '@/components/LoadingState.vue'
import EmptyState from '@/components/EmptyState.vue'
import { winRate as formatWinRate, streakLabel as formatStreak, streakTone } from '@/lib/format'

const route = useRoute()
const auth = useAuthStore()
const player = ref(null)
const eloHistory = ref([])
const recentMatches = ref([])
const loading = ref(true)

const isOwnProfile = computed(() => auth.profile?.id === route.params.id)

const winRate = computed(() => formatWinRate(player.value))
const streakLabel = computed(() => formatStreak(player.value))
const streakClass = computed(() => streakTone(player.value))
const uploadError = ref('')

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
  uploadError.value = ''
  const compressed = await compressImage(file, 500 * 1024)
  const path = `${auth.session.user.id}/avatar.jpg`
  const { error: uploadErr } = await supabase.storage
    .from('avatars')
    .upload(path, compressed, { upsert: true, contentType: 'image/jpeg' })
  if (uploadErr) { uploadError.value = uploadErr.message; return }

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

<style scoped>
.hero {
  display: grid;
  gap: var(--space-4);
  grid-template-columns: 1fr auto;
  align-items: center;
}
.hero__who {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  min-width: 0;
}
.hero__name {
  font-size: var(--text-xl);
  overflow-wrap: anywhere;
}
.hero__elo {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}
.hero__elo-value {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: var(--text-2xl);
  line-height: 1;
  color: var(--color-accent-text);
}
.hero__unsure {
  font-size: var(--text-lg);
  color: var(--color-text-muted);
}
.hero__elo-label {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}
.hero__stats {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--space-3);
  padding-top: var(--space-4);
  border-top: 1px solid var(--color-line);
}
.upload-error {
  margin-top: var(--space-3);
}
.match-list {
  list-style: none;
  gap: var(--space-2);
}
</style>
