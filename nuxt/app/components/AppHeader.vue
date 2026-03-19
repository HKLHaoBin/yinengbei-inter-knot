<script setup lang="ts">
const route = useRoute();
const auth = useAuthStore();
const isLoginRoute = computed(() => route.path.startsWith("/login"));
</script>

<template>
  <header class="ik-header">
    <div class="container ik-header__inner">
      <NuxtLink to="/" class="ik-brand">
        <span class="ik-brand__dot" />
        <strong>Inter Knot</strong>
      </NuxtLink>

      <div class="ik-row">
        <NuxtLink v-if="auth.isLogin" :to="`/profile/${auth.user?.documentId || auth.user?.authorId || ''}`">
          <z-button>我的主页</z-button>
        </NuxtLink>
        <NuxtLink v-if="!isLoginRoute" to="/login">
          <z-button :type="auth.isLogin ? 'default' : 'primary'">
            {{ auth.isLogin ? "切换账号" : "登录 / 注册" }}
          </z-button>
        </NuxtLink>
      </div>
    </div>
  </header>
</template>

<style scoped>
.ik-header {
  position: sticky;
  top: 0;
  z-index: 50;
  border-bottom: 1px solid #2b2b2b;
  background: rgba(12, 12, 12, 0.92);
  backdrop-filter: blur(8px);
}

.ik-header__inner {
  height: 62px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.ik-brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.ik-brand__dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--ik-primary);
  box-shadow: 0 0 16px var(--ik-primary);
}
</style>
