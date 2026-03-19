<script setup lang="ts">
import { computed } from "vue";
import type { Discussion } from "~/types/entities";

const props = defineProps<{
  discussion: Discussion;
}>();

const emit = defineEmits<{
  open: [discussion: Discussion];
}>();

const avatarLabel = computed(() => {
  const name = props.discussion.author?.name || "U";
  return name[0] || "U";
});

const DEFAULT_COVER_ASPECT_RATIO = 643 / 408;
const MIN_COVER_ASPECT_RATIO = 0.75;
const DEFAULT_COVER_IMAGE = "/images/default-cover.webp";

const authorName = computed(() => props.discussion.author?.name || "未知作者");
const excerpt = computed(
  () => props.discussion.bodyText || props.discussion.rawBodyText || "暂无摘要内容",
);
const coverAspectRatio = computed(() => {
  const width = props.discussion.coverWidth;
  const height = props.discussion.coverHeight;

  if (
    typeof width === "number" &&
    typeof height === "number" &&
    Number.isFinite(width) &&
    Number.isFinite(height) &&
    width > 0 &&
    height > 0
  ) {
    return Math.max(width / height, MIN_COVER_ASPECT_RATIO);
  }

  return DEFAULT_COVER_ASPECT_RATIO;
});

const handleOpen = () => {
  emit("open", props.discussion);
};
</script>

<template>
  <article class="ik-card" :class="{ 'ik-card--pinned': discussion.isPinned }">
    <NuxtLink
      :to="`/discussion/${discussion.id}`"
      class="ik-card__link"
      no-prefetch
      @click="handleOpen"
    >
      <div class="ik-card__cover-wrap">
        <div class="ik-card__cover-frame" :style="{ aspectRatio: String(coverAspectRatio) }">
          <img
            v-if="discussion.cover"
            :src="discussion.cover"
            :alt="discussion.title"
            class="ik-card__cover"
            loading="lazy"
            decoding="async"
            fetchpriority="low"
          />
          <img
            v-else
            :src="DEFAULT_COVER_IMAGE"
            alt="default cover"
            class="ik-card__cover ik-card__cover--fallback"
            loading="lazy"
            decoding="async"
            fetchpriority="low"
          />
        </div>
        <div class="ik-card__views">
          <svg
            class="ik-card__views-icon"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              d="M12 5C6.7 5 3 10 2 12c1 2 4.7 7 10 7s9-5 10-7c-1-2-4.7-7-10-7Z"
              stroke="currentColor"
              stroke-width="1.8"
            />
            <circle cx="12" cy="12" r="3.2" stroke="currentColor" stroke-width="1.8" />
          </svg>
          <span>{{ discussion.views || 0 }}</span>
        </div>
      </div>

      <div class="ik-card__body">
        <div class="ik-card__author-row">
          <div class="ik-card__avatar-shell">
            <img
              v-if="discussion.author?.avatar"
              :src="discussion.author.avatar"
              :alt="authorName"
              class="ik-card__avatar-image"
              loading="lazy"
              decoding="async"
            />
            <div v-else class="ik-card__avatar-fallback">{{ avatarLabel }}</div>
          </div>
          <div class="ik-card__author-block">
            <p class="ik-card__author-name">{{ authorName }}</p>
            <div class="ik-card__author-divider" />
          </div>
        </div>

        <h3 class="ik-card__title" :class="{ 'ik-card__title--read': discussion.isRead }">
          {{ discussion.title }}
        </h3>
        <p class="ik-card__excerpt">{{ excerpt }}</p>
      </div>
    </NuxtLink>
  </article>
</template>

<style scoped>
.ik-card {
  border-radius: 24px 24px 0 24px;
  background: #000;
  padding: 4px;
  overflow: hidden;
  transition: background-color 180ms ease;
}

.ik-card--pinned {
  background: #2d4dff;
}

.ik-card:hover {
  background: #d7ff00;
}

.ik-card__link {
  display: block;
  border-radius: 20px 20px 0 20px;
  background: #222;
  overflow: hidden;
}

.ik-card__cover-wrap {
  position: relative;
  overflow: hidden;
}

.ik-card__cover-frame {
  width: 100%;
  background: #151515;
}

.ik-card__cover {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top center;
  transition: transform 1.2s cubic-bezier(0.22, 1, 0.36, 1);
}

.ik-card:hover .ik-card__cover {
  transform: scale(1.06);
}

.ik-card__cover--fallback {
  background: #151515;
}

.ik-card__views {
  position: absolute;
  top: 11px;
  left: 16px;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.75);
}

.ik-card__views-icon {
  width: 22px;
  height: 22px;
}

.ik-card__body {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 8px 12px;
}

.ik-card__author-row {
  position: relative;
  display: flex;
  align-items: flex-start;
}

.ik-card__avatar-shell {
  position: relative;
  margin-top: -28px;
  width: 54px;
  height: 54px;
  padding: 2px;
  border-radius: 999px;
  background: #222;
}

.ik-card__avatar-image,
.ik-card__avatar-fallback {
  width: 100%;
  height: 100%;
  border-radius: 999px;
}

.ik-card__avatar-image {
  object-fit: cover;
  background: #111;
}

.ik-card__avatar-fallback {
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, #2d2d2d 0%, #181818 100%);
  border: 1px solid #3a3a3a;
  color: var(--ik-primary);
  font-weight: 800;
}

.ik-card__author-block {
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-height: 32px;
  padding-left: 8px;
  margin-left: 4px;
  width: calc(100% - 58px);
}

.ik-card__author-name {
  margin: 4px 0 4px;
  font-size: 15px;
  font-weight: 700;
  color: #fff;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.ik-card__author-divider {
  width: 100%;
  height: 1px;
  background: #3a3a3a;
}

.ik-card__title {
  margin: 0;
  font-size: 17px;
  line-height: 1.25;
  color: #6f9cff;
}

.ik-card__title--read {
  color: #8f8f8f;
}

.ik-card__excerpt {
  margin: 0;
  color: #e0e0e0;
  font-size: 15px;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
