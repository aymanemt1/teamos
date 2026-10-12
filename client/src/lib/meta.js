// Shared domain metadata. Status/priority ids match the Supabase contract verbatim.

export const STATUSES = [
  { id: 'backlog', label: 'Backlog', color: '#8b949e' },
  { id: 'in_progress', label: 'In Progress', color: '#7c6cf0' },
  { id: 'review', label: 'Review', color: '#f0b45e' },
  { id: 'done', label: 'Done', color: '#3fb950' },
]

export const PRIORITIES = [
  { id: 'low', label: 'Low', color: '#8b949e' },
  { id: 'medium', label: 'Medium', color: '#e3b341' },
  { id: 'high', label: 'High', color: '#f0883e' },
  { id: 'urgent', label: 'Urgent', color: '#f85149' },
]

export const statusOf = (id) => STATUSES.find((s) => s.id === id) ?? STATUSES[0]
export const priorityOf = (id) => PRIORITIES.find((p) => p.id === id) ?? PRIORITIES[0]

export const ACTION_LABELS = {
  'project.created': 'created project',
  'task.created': 'created task',
  'task.moved': 'moved task',
  'task.completed': 'completed task',
  'task.commented': 'commented on',
  'task.updated': 'updated task',
  'team.member_added': 'added',
}

export function activityText(a) {
  const verb = ACTION_LABELS[a.action] ?? a.action
  const subject =
    a.meta?.task_title ?? a.meta?.name ?? a.meta?.email ?? a.meta?.title ?? ''
  return `${verb}${subject ? ` ${subject}` : ''}`
}

export const PROJECT_COLORS = [
  '#7c6cf0', '#2f81f7', '#3fb950', '#e3b341',
  '#f0883e', '#f85149', '#d2a8ff', '#39c5cf',
]
