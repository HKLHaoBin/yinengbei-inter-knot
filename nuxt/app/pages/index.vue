<script setup lang="ts">
import { Waterfall } from "vue-waterfall-plugin-next";
import "vue-waterfall-plugin-next/dist/style.css";
import BScroll from "@better-scroll/core";
import PullUp from "@better-scroll/pull-up";
import MouseWheel from "@better-scroll/mouse-wheel";
import ObserveDOM from "@better-scroll/observe-dom";
import { useDebounceFn } from "@vueuse/core";
import type { Discussion } from "~/types/entities";
import { resolveErrorMessage } from "~/utils/api-error";

type BScrollWithFlag = typeof BScroll & {
  __ikPluginsRegistered?: boolean;
};

const BScrollRuntime = BScroll as BScrollWithFlag;
if (!BScrollRuntime.__ikPluginsRegistered) {
  BScrollRuntime.use(PullUp);
  BScrollRuntime.use(MouseWheel);
  BScrollRuntime.use(ObserveDOM);
  BScrollRuntime.__ikPluginsRegistered = true;
}

const api = useApi();
const route = useRoute();

const SCROLL_PULL_THRESHOLD = 40;
const SCROLL_MIN_HEIGHT = 360;
const MOBILE_BOTTOM_NAV_HEIGHT = 64;

const WATERFALL_BREAKPOINTS = {
  99999: { rowPerView: 6 },
  1400: { rowPerView: 5 },
  1200: { rowPerView: 4 },
  900: { rowPerView: 3 },
  680: { rowPerView: 2 },
  460: { rowPerView: 1 },
};

const pickFirstQuery = (queryValue: string | string[] | undefined) => {
  if (Array.isArray(queryValue)) {
    return queryValue[0] || "";
  }
  return queryValue || "";
};

const query = ref(pickFirstQuery(route.query.q as string | string[] | undefined));
const loading = ref(false);
const loadingMore = ref(false);
const error = ref("");

const list = ref<Discussion[]>([]);
const endCursor = ref("0");
const hasNextPage = ref(true);
const requestVersion = ref(0);
const seenIds = ref<Set<string>>(new Set());

const selectedDiscussionId = ref("");
const detailOpen = ref(false);

const lockBodyScroll = () => {
  if (import.meta.client) {
    document.body.style.overflow = "hidden";
  }
};

const unlockBodyScroll = () => {
  if (import.meta.client) {
    document.body.style.overflow = "";
  }
};

watch(detailOpen, (isOpen) => {
  if (isOpen) {
    lockBodyScroll();
  } else {
    unlockBodyScroll();
  }
});

onBeforeUnmount(() => {
  unlockBodyScroll();
});

const scrollWrapperRef = ref<HTMLElement | null>(null);
const scrollHeight = ref(540);
const bScrollRef = shallowRef<InstanceType<typeof BScroll> | null>(null);

const finishPullUp = () => {
  (bScrollRef.value as (InstanceType<typeof BScroll> & { finishPullUp?: () => void }) | null)
    ?.finishPullUp?.();
};

const refreshScroll = useDebounceFn(() => {
  bScrollRef.value?.refresh();
}, 60);

const updateScrollHeight = () => {
  if (!import.meta.client) return;
  const wrapper = scrollWrapperRef.value;
  if (!wrapper) return;

  const rect = wrapper.getBoundingClientRect();
  const viewportHeight = window.innerHeight;
  const reserveBottom = window.innerWidth <= 768 ? MOBILE_BOTTOM_NAV_HEIGHT : 0;
  const nextHeight = Math.floor(viewportHeight - rect.top - reserveBottom);
  scrollHeight.value = Math.max(SCROLL_MIN_HEIGHT, nextHeight);
};

const toUniqueNodes = (nodes: Discussion[], reset: boolean): Discussion[] => {
  if (reset) {
    seenIds.value = new Set();
  }

  const unique: Discussion[] = [];
  for (const node of nodes) {
    if (!node.id || seenIds.value.has(node.id)) continue;
    seenIds.value.add(node.id);
    unique.push(node);
  }
  return unique;
};

const syncScrollAfterData = async (reset: boolean) => {
  await nextTick();
  if (reset) {
    bScrollRef.value?.scrollTo(0, 0, 0);
  }
  finishPullUp();
  refreshScroll();
};

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

    const uniqueNodes = toUniqueNodes(page.nodes, reset);

    if (reset) {
      list.value = uniqueNodes;
    } else {
      list.value = [...list.value, ...uniqueNodes];
    }

    endCursor.value = page.endCursor;
    hasNextPage.value = page.hasNextPage;

    await syncScrollAfterData(reset);
  } catch (err) {
    error.value = resolveErrorMessage(err, "获取帖子失败");
    await syncScrollAfterData(false);
  } finally {
    loading.value = false;
    loadingMore.value = false;
  }
};

const goDiscussion = async (discussion: Discussion) => {
  try {
    await api.markAsReadBatch([discussion.id]);
  } catch {
  }
  selectedDiscussionId.value = discussion.id;
  detailOpen.value = true;
};

const handlePullingUp = async () => {
  if (loading.value || loadingMore.value || !hasNextPage.value) {
    finishPullUp();
    refreshScroll();
    return;
  }

  await fetchList(false);
};

const initBetterScroll = () => {
  if (!import.meta.client || !scrollWrapperRef.value || bScrollRef.value) return;

  const instance = new BScroll(scrollWrapperRef.value, {
    scrollY: true,
    scrollX: false,
    click: true,
    probeType: 3,
    bounceTime: 500,
    observeDOM: true,
    mouseWheel: {
      speed: 20,
      invert: false,
      easeTime: 280,
    },
    pullUpLoad: {
      threshold: SCROLL_PULL_THRESHOLD,
    },
  });

  instance.on("pullingUp", handlePullingUp);
  bScrollRef.value = instance;
};

const destroyBetterScroll = () => {
  if (!bScrollRef.value) return;
  bScrollRef.value.off("pullingUp", handlePullingUp);
  bScrollRef.value.destroy();
  bScrollRef.value = null;
};

const handleResize = useDebounceFn(() => {
  updateScrollHeight();
  refreshScroll();
}, 80);

const debouncedSearch = useDebounceFn(() => fetchList(true), 300);

const handleWaterfallAfterRender = () => {
  refreshScroll();
};

watch(
  () => query.value,
  () => {
    debouncedSearch();
  },
);

watch(
  () => route.query.q,
  (nextQuery) => {
    const normalized = pickFirstQuery(nextQuery as string | string[] | undefined);
    if (normalized === query.value) return;
    query.value = normalized;
  },
);

watch(
  () => list.value.length,
  async () => {
    await nextTick();
    refreshScroll();
  },
);

watch(
  () => scrollWrapperRef.value,
  async (wrapper) => {
    if (!wrapper) {
      destroyBetterScroll();
      return;
    }
    await nextTick();
    updateScrollHeight();
    initBetterScroll();
    refreshScroll();
  },
  { flush: "post" },
);

onMounted(async () => {
  if (import.meta.client) {
    window.addEventListener("resize", handleResize, { passive: true });
  }

  await fetchList(true);

  await nextTick();
  updateScrollHeight();
  initBetterScroll();
  refreshScroll();
});

onBeforeUnmount(() => {
  if (import.meta.client) {
    window.removeEventListener("resize", handleResize);
  }
  destroyBetterScroll();
});
</script>

<template>
  <section class="container ik-home-container ik-stack">
    <div v-if="error" class="ik-panel" style="border-color: #5d2424; color: #ff9d9d">
      {{ error }}
    </div>

    <div v-if="!list.length && loading" class="ik-empty">正在加载帖子...</div>
    <div v-else-if="!list.length && !loading" class="ik-empty">暂无相关帖子... [ o_x ]/</div>

    <ClientOnly v-else>
      <div
        ref="scrollWrapperRef"
        class="ik-scroll-wrapper"
        :style="{ height: `${scrollHeight}px` }"
      >
        <div class="ik-scroll-content">
          <Waterfall
            class="ik-masonry"
            :list="list"
            row-key="id"
            img-selector="cover"
            :width="228"
            :gutter="12"
            :space="12"
            :has-around-gutter="false"
            :breakpoints="WATERFALL_BREAKPOINTS"
            background-color="transparent"
            :delay="80"
            :animation-cancel="true"
            @after-render="handleWaterfallAfterRender"
          >
            <template #default="{ item }">
              <DiscussionCard :discussion="item" @open="goDiscussion" />
            </template>
          </Waterfall>

          <div v-if="loadingMore || !hasNextPage" class="ik-scroll-footer">
            <img v-if="loadingMore" class="ik-scroll-gif" src="/images/Bangboo.gif" alt="加载中" />
            <span v-else class="ik-meta">已经到底啦 [ O_X ] /</span>
          </div>
        </div>
      </div>
    </ClientOnly>

    <DiscussionDetailModal
      v-if="detailOpen && selectedDiscussionId"
      :discussion-id="selectedDiscussionId"
      :width-percent="82"
      :height-percent="88"
      @close="detailOpen = false"
    />
  </section>
</template>

<style scoped>
.ik-home-container {
  width: min(1450px, calc(100% - 20px));
}

.ik-scroll-wrapper {
  width: 100%;
  overflow: hidden;
  border-radius: 12px;
  position: relative;
}

.ik-scroll-content {
  min-height: 100%;
  width: 100%;
  padding-bottom: 0;
}

.ik-masonry {
  width: 100%;
}

.ik-scroll-footer {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 2;
  pointer-events: none;
  min-height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 8px 0;
}

.ik-scroll-gif {
  width: 80px;
  height: 80px;
  object-fit: contain;
}

@media (max-width: 768px) {
  .ik-home-container {
    width: calc(100% - 20px);
  }

  .ik-scroll-footer {
    flex-wrap: wrap;
  }
}
</style>
