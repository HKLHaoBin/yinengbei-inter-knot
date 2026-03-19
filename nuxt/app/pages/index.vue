<script setup lang="ts">
import { MasonryWall } from "@yeger/vue-masonry-wall";
import { useDebounceFn, useIntersectionObserver } from "@vueuse/core";
import type { Discussion } from "~/types/entities";
import { resolveErrorMessage } from "~/utils/api-error";

const api = useApi();

const query = ref("");
const loading = ref(false);
const loadingMore = ref(false);
const error = ref("");

const list = ref<Discussion[]>([]);
const endCursor = ref("0");
const hasNextPage = ref(true);
const sentinelRef = ref<HTMLElement | null>(null);
const requestVersion = ref(0);

const fetchList = async (reset = false) => {
  if (loading.value || loadingMore.value) return;
  if (!hasNextPage.value && !reset) return;

  error.value = "";
  if (reset) {
    loading.value = true;
  } else {
    loadingMore.value = true;
  }

  const currentVersion = ++requestVersion.value;
  try {
    const page = await api.searchArticles(query.value.trim(), reset ? "0" : endCursor.value);
    if (currentVersion !== requestVersion.value) {
      return;
    }

    if (reset) {
      list.value = page.nodes;
    } else {
      list.value = [...list.value, ...page.nodes];
    }

    endCursor.value = page.endCursor;
    hasNextPage.value = page.hasNextPage;
  } catch (err) {
    error.value = resolveErrorMessage(err, "获取帖子失败");
  } finally {
    loading.value = false;
    loadingMore.value = false;
  }
};

const goDiscussion = async (discussion: Discussion) => {
  try {
    await api.markAsReadBatch([discussion.id]);
  } catch {
    // ignore read status update errors
  }
};

const debouncedSearch = useDebounceFn(() => fetchList(true), 300);

watch(
  () => query.value,
  () => {
    debouncedSearch();
  },
);

onMounted(() => {
  fetchList(true);
});

useIntersectionObserver(
  sentinelRef,
  (entries) => {
    const [entry] = entries;
    if (entry?.isIntersecting) {
      fetchList(false);
    }
  },
  {
    rootMargin: "900px 0px",
    threshold: 0,
  },
);
</script>

<template>
  <section class="container ik-home-container ik-stack">
    <h1 class="ik-title">绳网推荐</h1>

    <z-card class="ik-panel">
      <div class="ik-row">
        <z-input
          v-model="query"
          placeholder="搜索帖子标题或关键词"
          style="flex: 1"
        />
        <z-button @click="fetchList(true)" :loading="loading">搜索</z-button>
      </div>
      <p class="ik-meta">数据源：/api/articles/list 和 /api/articles/search</p>
    </z-card>

    <div v-if="error" class="ik-panel" style="border-color: #5d2424; color: #ff9d9d">
      {{ error }}
    </div>

    <div v-if="loading" class="ik-empty">正在加载帖子...</div>
    <div v-else-if="!list.length" class="ik-empty">暂无相关帖子... [ o_x ]/</div>

    <ClientOnly v-else>
      <MasonryWall
        :items="list"
        :column-width="228"
        :gap="12"
        :min-columns="1"
        :max-columns="6"
        :ssr-columns="1"
        class="ik-masonry"
        :key-mapper="(item: Discussion) => item.id"
      >
        <template #default="{ item }">
          <DiscussionCard :discussion="item" @open="goDiscussion" />
        </template>
      </MasonryWall>
    </ClientOnly>

    <div class="ik-row" style="justify-content: center; margin-top: 6px">
      <z-button v-if="hasNextPage" @click="fetchList(false)" :loading="loadingMore">
        加载更多
      </z-button>
      <span v-else class="ik-meta">已经到底啦 [ O_X ] /</span>
    </div>

    <div ref="sentinelRef" class="ik-sentinel" />
  </section>
</template>

<style scoped>
.ik-home-container {
  width: min(1450px, calc(100% - 20px));
}

.ik-masonry {
  width: 100%;
}

.ik-sentinel {
  width: 100%;
  height: 1px;
}

@media (max-width: 768px) {
  .ik-home-container {
    width: calc(100% - 20px);
  }
}
</style>
