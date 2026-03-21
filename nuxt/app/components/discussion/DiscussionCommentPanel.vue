<script setup lang="ts">
import type { Comment } from "~/types/entities";

defineProps<{
  comments: Comment[];
  loading: boolean;
  hasNext: boolean;
}>();

const emit = defineEmits<{
  loadMore: [];
  likeComment: [comment: Comment];
  likeReply: [reply: Comment["replies"][number]];
}>();
</script>

<template>
  <section class="ik-discussion-comments">
    <h2 class="ik-discussion-comments__title">
      评论区
    </h2>

    <div v-if="!comments.length && !loading" class="ik-empty">
      暂时还没有评论
    </div>

    <div v-else class="ik-discussion-comments__list">
      <CommentItem
        v-for="comment in comments"
        :key="comment.id"
        :comment="comment"
        @like-comment="emit('likeComment', comment)"
        @like-reply="emit('likeReply', $event)"
      />
    </div>

    <div v-if="loading" class="ik-discussion-comments__loading">
      正在加载更多...
    </div>

    <div v-else-if="hasNext" class="ik-discussion-comments__load-more">
      <z-button type="default" @click="emit('loadMore')">
        加载更多评论
      </z-button>
    </div>

    <div v-else-if="comments.length" class="ik-discussion-comments__end">
      <span class="ik-meta">评论已全部加载</span>
    </div>
  </section>
</template>

<style scoped>
.ik-discussion-comments {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 16px;
  height: 100%;
  overflow: hidden;
}

.ik-discussion-comments__title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--ik-text);
  flex-shrink: 0;
}

.ik-discussion-comments__list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  overflow-y: auto;
  padding-right: 4px;
  min-height: 0;
}

/* 自定义滚动条 */
.ik-discussion-comments__list::-webkit-scrollbar {
  width: 6px;
}

.ik-discussion-comments__list::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 3px;
}

.ik-discussion-comments__list::-webkit-scrollbar-thumb {
  background: #3d3d3d;
  border-radius: 3px;
}

.ik-discussion-comments__list::-webkit-scrollbar-thumb:hover {
  background: #4d4d4d;
}

.ik-discussion-comments__loading,
.ik-discussion-comments__load-more,
.ik-discussion-comments__end {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 12px;
  flex-shrink: 0;
}

.ik-discussion-comments__loading {
  color: var(--ik-muted);
  font-size: 13px;
}

.ik-discussion-comments__end {
  color: var(--ik-muted);
  font-size: 13px;
}

@media (max-width: 768px) {
  .ik-discussion-comments {
    padding: 12px;
    gap: 12px;
  }

  .ik-discussion-comments__title {
    font-size: 16px;
  }
}
</style>
