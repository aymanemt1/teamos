<template>
  <div
    class="bg-card border border-border rounded-2xl p-5 anim-fade-up hover:border-[#3d444d] transition-colors"
    :class="stagger"
  >
    <div class="flex items-start justify-between">
      <div
        class="w-10 h-10 rounded-xl flex items-center justify-center"
        :style="{ backgroundColor: accentBg, color: accent }"
      >
        <Icon :name="icon" cls="w-5 h-5" />
      </div>
    </div>
    <p class="mt-4 text-3xl font-extrabold tracking-tight text-white tabular-nums">
      {{ display }}{{ suffix }}
    </p>
    <p class="mt-1 text-sm text-muted">{{ label }}</p>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, onUnmounted, computed } from 'vue'
import Icon from './Icon.vue'

const props = defineProps({
  icon: { type: String, required: true },
  label: { type: String, required: true },
  value: { type: Number, default: 0 },
  suffix: { type: String, default: '' },
  accent: { type: String, default: '#7c6cf0' },
  stagger: { type: String, default: '' },
})

const accentBg = computed(() => props.accent + '22')
const display = ref(0)
let raf = null

function animate(to) {
  cancelAnimationFrame(raf)
  const start = performance.now()
  const duration = 900
  const tick = (now) => {
    const p = Math.min(1, (now - start) / duration)
    const eased = 1 - Math.pow(1 - p, 3)
    display.value = Math.round(to * eased)
    if (p < 1) raf = requestAnimationFrame(tick)
  }
  raf = requestAnimationFrame(tick)
}

onMounted(() => animate(props.value))
watch(
  () => props.value,
  (v) => animate(v)
)
onUnmounted(() => cancelAnimationFrame(raf))
</script>
