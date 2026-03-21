<script setup lang="ts">
import type { Discussion } from "~/types/entities";

const DEFAULT_AVATAR = "/images/default-avatar.webp";

defineProps<{
  discussion: Discussion;
}>();

const emit = defineEmits<{
  close: [];
}>();
</script>

<template>
  <header class="ik-discussion-header">
    <div class="ik-discussion-header__author">
      <div class="ik-discussion-header__avatar">
        <img
          :src="discussion.author.avatar || DEFAULT_AVATAR"
          :alt="discussion.author.name"
          @error="(e) => { const target = e.target as HTMLImageElement; if (target) target.src = DEFAULT_AVATAR }"
        />
      </div>
      <div class="ik-discussion-header__info">
        <div class="ik-discussion-header__name-row">
          <span class="ik-discussion-header__name">
            {{ discussion.author.name || "匿名用户" }}
          </span>
        </div>
        <div class="ik-discussion-header__meta-row">
          <span class="ik-discussion-header__time">
            {{ discussion.createdAt }}
          </span>
        </div>
      </div>
    </div>
    <div class="ik-discussion-header__actions">
      <div class="ik-discussion-header__stats">
        <span class="ik-discussion-header__stat">
          <svg
            class="ik-icon"
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
          {{ discussion.views || 0 }}
        </span>
        <span class="ik-discussion-header__stat">
          <svg
            class="ik-icon"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"
              stroke="currentColor"
              stroke-width="1.8"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
          {{ discussion.commentsCount || 0 }}
        </span>
      </div>
      <z-button type="default" @click="emit('close')">
        返回
      </z-button>
    </div>
  </header>
</template>

<style scoped>
.ik-discussion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 16px;
  background: linear-gradient(135deg, #161616 0%, #080808 100%);
  border-bottom: 1px solid #2d2d2d;
  border-radius: 12px 12px 0 0;
}

.ik-discussion-header__author {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
  flex: 1;
}

.ik-discussion-header__avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  overflow: hidden;
  border: 2px solid #2d2d2d;
  flex-shrink: 0;
}

.ik-discussion-header__avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ik-discussion-header__info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.ik-discussion-header__name-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ik-discussion-header__name {
  font-size: 15px;
  font-weight: 700;
  color: var(--ik-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.ik-discussion-header__meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ik-discussion-header__time {
  font-size: 12px;
  color: var(--ik-muted);
}

.ik-discussion-header__actions {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-shrink: 0;
}

.ik-discussion-header__stats {
  display: flex;
  align-items: center;
  gap: 12px;
}

.ik-discussion-header__stat {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  color: var(--ik-muted);
}

.ik-icon {
  width: 14px;
  height: 14px;
}

@media (max-width: 768px) {
  .ik-discussion-header {
    padding: 10px 12px;
  }

  .ik-discussion-header__avatar {
    width: 32px;
    height: 32px;
  }

  .ik-discussion-header__name {
    font-size: 14px;
  }

  .ik-discussion-header__time {
    font-size: 11px;
  }

  .ik-discussion-header__stats {
    display: none;
  }
}
</style>
