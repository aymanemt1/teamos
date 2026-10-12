import { supabase } from './supabase.js'

/**
 * Fire-and-forget activity log insert. Never blocks the UI; failures are
 * swallowed (a console warning only) so a logging problem can't break a mutation.
 */
export function logActivity({ team_id, user_id, action, subject_type = null, subject_id = null, meta = {} }) {
  if (!supabase || !team_id) return
  supabase
    .from('activities')
    .insert({
      team_id,
      user_id: user_id ?? null,
      action,
      subject_type,
      subject_id,
      meta,
    })
    .then(({ error }) => {
      if (error) console.warn('[teamos] activity log failed:', error.message)
    })
}
