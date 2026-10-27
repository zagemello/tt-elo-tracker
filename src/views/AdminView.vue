<template>
  <div>
    <PageHeader
      title="Admin"
      subtitle="Deleting a match reverses its Elo impact. If other matches were played after it, those ratings may be slightly off."
    />

    <AppAlert v-if="error">{{ error }}</AppAlert>
    <LoadingState v-if="loading" />
    <EmptyState v-else-if="!matches.length" title="No matches yet" />

    <ul v-else class="stack match-list">
      <li v-for="m in matches" :key="m.id">
        <MatchCard :match="m">
          <template #actions>
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
import { useMatches } from '@/composables/useMatches'
import PageHeader from '@/components/PageHeader.vue'
import LoadingState from '@/components/LoadingState.vue'
import EmptyState from '@/components/EmptyState.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppButton from '@/components/AppButton.vue'
import MatchCard from '@/components/MatchCard.vue'

const { matches, loading, deletingId, error, deleteMatch } = useMatches()
</script>

<style scoped>
.match-list {
  list-style: none;
  gap: var(--space-2);
}
</style>
