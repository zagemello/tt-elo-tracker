<template>
  <header class="topbar">
    <div class="topbar__inner">
      <RouterLink to="/" class="brand" aria-label="TT Elo home">
        <span class="brand__ball" aria-hidden="true" />
        <span class="brand__name">TT Elo</span>
      </RouterLink>

      <nav class="desktop-links" aria-label="Main">
        <RouterLink v-for="l in links" :key="l.to" :to="l.to">{{ l.label }}</RouterLink>
      </nav>

      <div class="topbar__actions">
        <RouterLink v-if="auth.isAdmin" to="/admin" class="admin-link">Admin</RouterLink>
        <AppButton v-if="!auth.session" to="/login" size="sm">Sign in</AppButton>
        <AppButton v-else variant="ghost" size="sm" @click="auth.signOut">Sign out</AppButton>
      </div>
    </div>
  </header>

  <nav class="tabbar" aria-label="Main">
    <RouterLink v-for="l in tabs" :key="l.to" :to="l.to" class="tab" :class="{ 'tab--primary': l.primary }">
      <span class="tab__icon"><AppIcon :name="l.icon" :size="l.primary ? 24 : 22" /></span>
      <span class="tab__label">{{ l.short ?? l.label }}</span>
    </RouterLink>
  </nav>
</template>

<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppButton from './AppButton.vue'
import AppIcon from './AppIcon.vue'

const auth = useAuthStore()

const links = computed(() => {
  const items = [
    { to: '/', label: 'Leaderboard', short: 'Ranking', icon: 'trophy' },
    { to: '/matches', label: 'Matches', icon: 'list' },
  ]
  if (auth.session) {
    items.push(
      { to: '/log-match', label: 'Log match', short: 'Log', icon: 'plus', primary: true },
      { to: '/h2h', label: 'Head-to-head', short: 'H2H', icon: 'swords' },
    )
    if (auth.profile) items.push({ to: `/profile/${auth.profile.id}`, label: 'My profile', short: 'Me', icon: 'user' })
  } else {
    items.push({ to: '/h2h', label: 'Head-to-head', short: 'H2H', icon: 'swords' })
  }
  return items
})

// Mobile tab bar shows the same entries, ordered so “Log” sits in the middle.
const tabs = computed(() => {
  const items = [...links.value]
  const logIdx = items.findIndex((i) => i.primary)
  if (logIdx > -1) {
    const [log] = items.splice(logIdx, 1)
    items.splice(Math.floor(items.length / 2), 0, log)
  }
  return items
})
</script>

<style scoped>
.topbar {
  position: sticky;
  top: 0;
  z-index: var(--z-header);
  background: color-mix(in srgb, var(--color-bg) 88%, transparent);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--color-line);
}
.topbar__inner {
  display: flex;
  align-items: center;
  gap: var(--space-5);
  height: var(--header-height);
  max-width: var(--page-max);
  margin: 0 auto;
  padding: 0 var(--page-gutter);
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  color: var(--color-text);
  font-family: var(--font-display);
  font-weight: 800;
  font-size: var(--text-lg);
  letter-spacing: -0.02em;
}
.brand:hover {
  text-decoration: none;
}
.brand__ball {
  width: 0.95rem;
  height: 0.95rem;
  border-radius: 50%;
  background: var(--color-accent);
  box-shadow: inset -2px -2px 0 rgb(0 0 0 / 0.18);
}

.desktop-links {
  display: none;
  flex: 1;
  gap: var(--space-1);
}
.desktop-links a {
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  color: var(--color-text-muted);
  font-size: var(--text-sm);
  font-weight: 600;
}
.desktop-links a:hover {
  color: var(--color-text);
  text-decoration: none;
  background: var(--color-surface);
}
.desktop-links a.router-link-exact-active,
.desktop-links a[aria-current='page'] {
  color: var(--color-text);
  background: var(--color-surface-raised);
}

.topbar__actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-left: auto;
}
.admin-link {
  color: var(--color-warn);
  font-size: var(--text-sm);
  font-weight: 600;
}

/* Mobile bottom tab bar */
.tabbar {
  position: fixed;
  inset: auto 0 0 0;
  z-index: var(--z-tabbar);
  display: flex;
  justify-content: space-around;
  align-items: stretch;
  height: calc(var(--tabbar-height) + env(safe-area-inset-bottom));
  padding-bottom: env(safe-area-inset-bottom);
  background: var(--color-surface);
  border-top: 1px solid var(--color-line);
}
.tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  color: var(--color-text-muted);
  font-size: var(--text-xs);
  font-weight: 600;
}
.tab:hover {
  text-decoration: none;
}
.tab.router-link-exact-active,
.tab[aria-current='page'] {
  color: var(--color-accent-text);
}
.tab--primary .tab__icon {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  margin-top: -1.1rem;
  border-radius: 50%;
  background: var(--color-accent);
  color: var(--color-accent-ink);
  box-shadow: var(--shadow-md);
}
.tab--primary.router-link-exact-active {
  color: var(--color-text);
}

@media (min-width: 48rem) {
  .desktop-links {
    display: flex;
  }
  .tabbar {
    display: none;
  }
}
</style>
