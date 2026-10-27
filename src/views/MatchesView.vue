<template>
  <div>
    <PageHeader title="Matches" subtitle="The latest results across the league." />

    <AppAlert v-if="error">{{ error }}</AppAlert>
    <LoadingState v-if="loading" />
    <EmptyState v-else-if="!matches.length" title="No matches yet">Results show up here as soon as one is logged.</EmptyState>

    <ul v-else class="stack match-list">
      <li v-for="m in matches" :key="m.id">
        <MatchCard :match="m">
          <template v-if="auth.isAdmin" #actions>
            <AppButton variant="danger" size="sm" :loading="deletingId === m.id" @click="deleteMatch(m)">
              {{ deletingId === m.id ? 'Deleting…' : 'Delete' }}
            </AppButton>
          </template>
        </MatchCard>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
import { useMatches } from '@/composables/useMatches'
import PageHeader from '@/components/PageHeader.vue'
import LoadingState from '@/components/LoadingState.vue'
import EmptyState from '@/components/EmptyState.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppButton from '@/components/AppButton.vue'
import MatchCard from '@/components/MatchCard.vue'

const auth = useAuthStore()
const { matches, loading, deletingId, error, deleteMatch } = useMatches()
</script>

<style scoped>
.match-list {
  list-style: none;
  gap: var(--space-2);
}
</style>
