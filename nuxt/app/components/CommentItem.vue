<script setup lang="ts">
import type { Comment, CommentReply } from "~/types/entities";

const DEFAULT_AVATAR = "/images/default-avatar.webp";

const props = defineProps<{
  comment: Comment;
}>();

const emit = defineEmits<{
  likeComment: [comment: Comment];
  likeReply: [reply: CommentReply];
}>();
</script>

<template>
  <z-card class="ik-comment-item">
    <div class="ik-comment-item__header">
      <div class="ik-comment-item__avatar">
        <img
          :src="comment.author?.avatar || DEFAULT_AVATAR"
          :alt="comment.author?.name"
          @error="(e) => { const target = e.target as HTMLImageElement; if (target) target.src = DEFAULT_AVATAR }"
        />
      </div>
      <div class="ik-comment-item__info">
        <div class="ik-comment-item__author-row">
          <strong class="ik-comment-item__author">
            {{ comment.author?.name || "匿名用户" }}
          </strong>
          <span class="ik-meta">{{ comment.createdAt || "刚刚" }}</span>
        </div>
        <p class="ik-comment-item__content">
          {{ comment.content }}
        </p>
      </div>
    </div>

    <div class="ik-comment-item__actions">
      <z-button
        size="small"
        :type="comment.liked ? 'primary' : 'default'"
        :class="{ 'ik-comment-item__btn--liked': comment.liked }"
        @click="emit('likeComment', comment)"
      >
        <!-- 已点赞 - 实心大拇指 -->
        <svg
          v-if="comment.liked"
          class="ik-icon--small ik-icon--liked"
          viewBox="0 0 24 24"
          fill="currentColor"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" />
        </svg>
        <!-- 未点赞 - 轮廓大拇指 -->
        <svg
          v-else
          class="ik-icon--small"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
        {{ comment.likesCount || 0 }}
      </z-button>
    </div>

    <!-- 回复列表 -->
    <div v-if="comment.replies?.length" class="ik-comment-item__replies">
      <div
        v-for="reply in comment.replies"
        :key="reply.id"
        class="ik-comment-item__reply"
      >
        <div class="ik-comment-item__reply-header">
          <div class="ik-comment-item__reply-avatar">
            <img
              :src="reply.author?.avatar || DEFAULT_AVATAR"
              :alt="reply.author?.name"
              @error="(e) => { const target = e.target as HTMLImageElement; if (target) target.src = DEFAULT_AVATAR }"
            />
          </div>
          <div class="ik-comment-item__reply-info">
            <div class="ik-comment-item__reply-author-row">
              <strong class="ik-comment-item__reply-author">
                {{ reply.author?.name || "匿名用户" }}
              </strong>
              <span class="ik-meta">{{ reply.createdAt || "刚刚" }}</span>
            </div>
            <p class="ik-comment-item__reply-content">
              {{ reply.content }}
            </p>
          </div>
        </div>
        <div class="ik-comment-item__reply-actions">
          <z-button
            size="small"
            :type="reply.liked ? 'primary' : 'default'"
            :class="{ 'ik-comment-item__btn--liked': reply.liked }"
            @click="emit('likeReply', reply)"
          >
            <!-- 已点赞 - 实心大拇指 -->
            <svg
              v-if="reply.liked"
              class="ik-icon--small ik-icon--liked"
              viewBox="0 0 24 24"
              fill="currentColor"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" />
            </svg>
            <!-- 未点赞 - 轮廓大拇指 -->
            <svg
              v-else
              class="ik-icon--small"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"
                stroke="currentColor"
                stroke-width="1.8"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
            {{ reply.likesCount || 0 }}
          </z-button>
        </div>
      </div>
    </div>
  </z-card>
</template>

<style scoped>
.ik-comment-item {
  border-radius: 12px;
  padding: 14px;
  background: rgba(0, 0, 0, 0.15);
  border: 1px solid #2f2f2f;
}

.ik-comment-item__header {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
}

.ik-comment-item__avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  overflow: hidden;
  border: 2px solid #2d2d2d;
  flex-shrink: 0;
}

.ik-comment-item__avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ik-comment-item__info {
  flex: 1;
  min-width: 0;
}

.ik-comment-item__author-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.ik-comment-item__author {
  font-size: 14px;
  font-weight: 600;
  color: var(--ik-text);
}

.ik-comment-item__content {
  margin: 0;
  line-height: 1.55;
  color: #f0f0f0;
  white-space: pre-wrap;
  font-size: 14px;
}

.ik-comment-item__actions {
  display: flex;
  justify-content: flex-end;
  padding-top: 8px;
  border-top: 1px dashed #323232;
}

.ik-icon--small {
  width: 14px;
  height: 14px;
}

.ik-icon--liked {
  color: var(--ik-primary);
}

/* 回复列表 */
.ik-comment-item__replies {
  margin-top: 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding-top: 12px;
  border-top: 1px dashed #323232;
}

.ik-comment-item__reply {
  border-radius: 10px;
  border: 1px solid #2f2f2f;
  padding: 10px;
  background: rgba(0, 0, 0, 0.1);
}

.ik-comment-item__reply-header {
  display: flex;
  gap: 10px;
  margin-bottom: 8px;
}

.ik-comment-item__reply-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  overflow: hidden;
  border: 2px solid #2d2d2d;
  flex-shrink: 0;
}

.ik-comment-item__reply-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ik-comment-item__reply-info {
  flex: 1;
  min-width: 0;
}

.ik-comment-item__reply-author-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.ik-comment-item__reply-author {
  font-size: 13px;
  font-weight: 600;
  color: var(--ik-text);
}

.ik-comment-item__reply-content {
  margin: 0;
  line-height: 1.5;
  color: #f0f0f0;
  white-space: pre-wrap;
  font-size: 13px;
}

.ik-comment-item__reply-actions {
  display: flex;
  justify-content: flex-end;
  padding-top: 6px;
  border-top: 1px dashed #3a3a3a;
}

@media (max-width: 768px) {
  .ik-comment-item {
    padding: 12px;
  }

  .ik-comment-item__avatar {
    width: 32px;
    height: 32px;
  }

  .ik-comment-item__content {
    font-size: 13px;
  }

  .ik-comment-item__reply-avatar {
    width: 24px;
    height: 24px;
  }

  .ik-comment-item__reply-content {
    font-size: 12px;
  }
}
</style>
