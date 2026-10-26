import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const session = ref(null)
  const profile = ref(null)
  const loading = ref(true)

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

  async function createProfile(displayName) {
    const userId = session.value.user.id
    const { data, error } = await supabase
      .from('profiles')
      .insert({ id: userId, display_name: displayName })
      .select()
      .single()
    if (error) throw error
    profile.value = data
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

  async function signInWithEmail(email, password) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signUpWithEmail(email, password) {
    const { error } = await supabase.auth.signUp({ email, password })
    if (error) throw error
  }

  async function signInWithMagicLink(email) {
    const { error } = await supabase.auth.signInWithOtp({ email })
    if (error) throw error
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  const isAdmin = computed(() => profile.value?.is_admin === true)

  return {
    session,
    profile,
    loading,
    isAdmin,
    init,
    fetchProfile,
    createProfile,
    updateProfile,
    signInWithEmail,
    signUpWithEmail,
    signInWithMagicLink,
    signOut,
  }
})
