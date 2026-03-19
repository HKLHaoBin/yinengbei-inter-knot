<script setup lang="ts">
import { useDebounceFn } from "@vueuse/core";
import { useMessage } from "zenless-ui";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const message = useMessage();

type HeaderTabName = "home" | "notification" | "mine";

const activeTab = ref<HeaderTabName>("home");
const searchKeyword = ref("");
const applyingSearch = ref(false);

const profilePath = computed(() => {
  const id = auth.user?.documentId || auth.user?.authorId;
  return id ? `/profile/${id}` : "/login";
});

const pickFirstQuery = (query: string | string[] | undefined) => {
  if (Array.isArray(query)) {
    return query[0] || "";
  }
  return query || "";
};

const resolveActiveTab = (path: string): HeaderTabName => {
  if (path.startsWith("/profile")) {
    return "mine";
  }
  if (path.startsWith("/notification")) {
    return "notification";
  }
  return "home";
};

const applySearch = async () => {
  if (applyingSearch.value) return;

  const keyword = searchKeyword.value.trim();
  const currentKeyword = pickFirstQuery(route.query.q as string | string[] | undefined).trim();
  const query = keyword ? { q: keyword } : {};

  if (route.path === "/" && keyword === currentKeyword) {
    return;
  }

  applyingSearch.value = true;
  if (route.path === "/") {
    try {
      await router.replace({ path: "/", query });
      return;
    } finally {
      applyingSearch.value = false;
    }
  }

  try {
    await router.push({ path: "/", query });
  } finally {
    applyingSearch.value = false;
  }
};

const debouncedSearch = useDebounceFn(() => {
  if (route.path === "/") {
    applySearch().catch(() => undefined);
  }
}, 700);

const handleSearchEnter = () => {
  applySearch().catch(() => undefined);
};

const handleTabChange = async (next: string | number) => {
  const tab = String(next) as HeaderTabName;

  if (tab === "home") {
    await router.push("/");
    return;
  }

  if (tab === "notification") {
    message.warning("通知中心即将开放");
    activeTab.value = resolveActiveTab(route.path);
    return;
  }

  await router.push(profilePath.value);
};

watch(
  () => route.fullPath,
  () => {
    activeTab.value = resolveActiveTab(route.path);
    searchKeyword.value = pickFirstQuery(route.query.q as string | string[] | undefined);
  },
  { immediate: true },
);

watch(
  () => searchKeyword.value,
  () => {
    debouncedSearch();
  },
);
</script>

<template>
  <header class="ik-header">
    <div class="ik-header__inner">
      <div class="ik-header__left">
        <NuxtLink to="/" class="ik-brand" aria-label="Inter Knot 首页">
          <img src="/images/zzzicon.png" alt="Inter Knot" class="ik-brand__icon" />
          <strong class="ik-brand__title">INTER-KNOT</strong>
        </NuxtLink>
      </div>

      <div class="ik-header__middle">
        <div class="ik-search-shell">
          <z-input
            v-model="searchKeyword"
            class="ik-search-input"
            placeholder="全站搜索"
            @keydown.enter.prevent="handleSearchEnter"
          />
        </div>
      </div>

      <div class="ik-header__right">
        <z-tabs v-model="activeTab" placement="top-left" class="ik-header-tabs" @change="handleTabChange">
          <z-tab-panel name="home" label="推荐" />
          <z-tab-panel name="notification">
            <template #label>
              <span class="ik-tab-label">消息</span>
              <span class="ik-tab-dot" />
            </template>
          </z-tab-panel>
          <z-tab-panel name="mine" label="我的" />
        </z-tabs>
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
  background: rgba(5, 5, 5, 0.94);
  backdrop-filter: blur(8px);
}

.ik-header__inner {
  min-height: 78px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
}

.ik-header__left {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
}

.ik-brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  flex: 0 0 auto;
}

.ik-brand__icon {
  width: 46px;
  height: 46px;
  object-fit: contain;
}

.ik-brand__title {
  color: #fff;
  font-size: 24px;
  line-height: 1;
  letter-spacing: -0.9px;
  font-weight: 900;
}

.ik-header__middle {
  min-width: 0;
  flex: 1 1 0;
  display: flex;
  justify-content: center;
  align-items: center;
}

.ik-search-shell {
  width: min(700px, 100%);
  min-width: 200px;
  max-width: 700px;
  display: flex;
  align-items: center;
}

.ik-header__right {
  flex: 0 0 auto;
  display: inline-flex;
  justify-content: flex-end;
  align-items: center;
}

.ik-search-input {
  width: 100%;
}

.ik-search-input :deep(.z-input__inner) {
  height: 44px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: #1e1e1e;
  padding: 0 16px;
  color: #e0e0e0;
}

.ik-search-input :deep(.z-input__inner::placeholder) {
  color: #808080;
}

.ik-search-input :deep(.z-input__inner:focus) {
  border-color: rgba(215, 255, 0, 0.55);
  box-shadow: 0 0 0 2px rgba(215, 255, 0, 0.12);
}

.ik-header-tabs :deep(.z-tabs__content) {
  display: none;
}

.ik-header-tabs :deep(.z-tabs__item) {
  min-width: 92px;
  height: 38px;
  padding: 0 24px;
  font-size: 16px;
  font-weight: 800;
  font-style: italic;
}

.ik-tab-label {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.ik-tab-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #ff4d4f;
}

@media (max-width: 1180px) {
  .ik-brand__title {
    font-size: 20px;
  }

  .ik-search-shell {
    max-width: 500px;
  }
}

@media (max-width: 900px) {
  .ik-header__middle {
    justify-content: flex-end;
  }

  .ik-search-shell {
    max-width: 100%;
  }

  .ik-header-tabs {
    display: none;
  }
}

@media (max-width: 768px) {
  .ik-header__inner {
    min-height: 66px;
    padding: 6px 10px;
    gap: 8px;
  }

  .ik-brand__icon {
    width: 38px;
    height: 38px;
  }

  .ik-brand__title {
    display: none;
  }

  .ik-search-shell {
    max-width: 100%;
    min-width: 0;
  }
}
</style>
