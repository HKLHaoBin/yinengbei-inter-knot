<script setup lang="ts">
const auth = useAuthStore();
const router = useRouter();

if (import.meta.client) {
  auth.hydrateFromStorage();

  const url = new URL(window.location.href);
  const fallbackPath = url.searchParams.get("p");
  if (fallbackPath) {
    url.searchParams.delete("p");
    window.history.replaceState({}, "", url.toString());
    router.replace(decodeURIComponent(fallbackPath)).catch(() => undefined);
  }
}
</script>

<template>
  <div>
    <AppHeader />
    <main class="ik-page">
      <NuxtPage />
    </main>
    <MobileBottomNav />
  </div>
</template>
