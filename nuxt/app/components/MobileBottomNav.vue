<script setup lang="ts">
const route = useRoute();
const links = [
  { to: "/", label: "推送" },
  { to: "/login", label: "账号" },
];
</script>

<template>
  <nav class="ik-mobile-nav">
    <NuxtLink
      v-for="link in links"
      :key="link.to"
      :to="link.to"
      class="ik-mobile-nav__item"
      :class="{ active: route.path === link.to }"
    >
      {{ link.label }}
    </NuxtLink>
  </nav>
</template>

<style scoped>
.ik-mobile-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 58px;
  display: none;
  border-top: 1px solid #2d2d2d;
  background: rgba(17, 17, 17, 0.96);
  backdrop-filter: blur(8px);
  z-index: 30;
}

.ik-mobile-nav__item {
  flex: 1;
  display: grid;
  place-items: center;
  color: var(--ik-muted);
  font-size: 13px;
}

.ik-mobile-nav__item.active {
  color: var(--ik-primary);
  font-weight: 700;
}

@media (max-width: 768px) {
  .ik-mobile-nav {
    display: flex;
  }
}
</style>
