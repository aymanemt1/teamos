import { reactive } from 'vue'

export const toasts = reactive([])

let nextId = 0

function push(message, type = 'info') {
  const t = { id: ++nextId, message, type }
  toasts.push(t)
  setTimeout(() => {
    const i = toasts.findIndex((x) => x.id === t.id)
    if (i >= 0) toasts.splice(i, 1)
  }, 4200)
}

export const toast = {
  success: (message) => push(message, 'success'),
  error: (message) => push(message, 'error'),
  info: (message) => push(message, 'info'),
}

export function dismissToast(id) {
  const i = toasts.findIndex((x) => x.id === id)
  if (i >= 0) toasts.splice(i, 1)
}
