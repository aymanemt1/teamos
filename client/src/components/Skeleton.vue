<template>
  <div class="skeleton rounded-xl" :class="cls"></div>
</template>

<script setup>
defineProps({ cls: { type: String, default: 'h-24 w-full' } })
</script>
