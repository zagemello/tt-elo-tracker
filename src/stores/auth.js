import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

const DOMAIN = 'tt-elo-tracker.app'

function toEmail(username) {
  return `${username.toLowerCase().trim()}@${DOMAIN}`
}

export const useAuthStore = defineStore('auth', () => {
  const session = ref(null)
  const profile = ref(null)
  const loading = ref(true)

  const isAdmin = computed(() => profile.value?.is_admin === true)

  async function init() {
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    if (data.session) await fetchProfile(data.session.user.id)
    loading.value = false

    supabase.auth.onAuthStateChange(async (event, newSession) => {
      session.value = newSession
      if (newSession) {
        await fetchProfile(newSession.user.id)
      } else {
        profile.value = null
      }
    })
  }

  async function fetchProfile(userId) {
    const { data } = await supabase.from('profiles').select('*').eq('id', userId).single()
    profile.value = data
  }

  async function signUp(username, password) {
    const trimmed = username.trim()
    if (!/^[a-zA-Z0-9_\- ]+$/.test(trimmed)) {
      throw new Error('Username can only contain letters, numbers, spaces, hyphens and underscores.')
    }
    const { data, error } = await supabase.auth.signUp({ email: toEmail(trimmed), password })
    if (error) throw error
    if (data.user) {
      const { error: profileErr } = await supabase
        .from('profiles')
        .insert({ id: data.user.id, display_name: trimmed })
      if (profileErr) throw new Error(profileErr.message === 'duplicate key value violates unique constraint "profiles_display_name_key"'
        ? 'That username is already taken.'
        : profileErr.message)
    }
  }

  async function signIn(username, password) {
    const { error } = await supabase.auth.signInWithPassword({
      email: toEmail(username.trim()),
      password,
    })
    if (error) throw new Error('Invalid username or password.')
  }

  async function updateProfile(updates) {
    const userId = session.value.user.id
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single()
    if (error) throw error
    profile.value = data
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  return {
    session,
    profile,
    loading,
    isAdmin,
    init,
    fetchProfile,
    signUp,
    signIn,
    updateProfile,
    signOut,
  }
})
