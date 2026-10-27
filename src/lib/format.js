export function formatDate(iso, { year = true } = {}) {
  return new Date(iso).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    ...(year && { year: '2-digit' }),
  })
}

export function winRate(player) {
  if (!player?.matches_played) return '—'
  return Math.round((player.wins / player.matches_played) * 100) + '%'
}

export function streakLabel(player) {
  const s = player?.current_streak
  if (!s) return '—'
  return s > 0 ? `${s}W` : `${Math.abs(s)}L`
}

export function streakTone(player) {
  const s = player?.current_streak
  if (!s) return ''
  return s > 0 ? 'win' : 'loss'
}
