<script setup lang="ts">
import type { Comment } from "~/types/entities";

defineProps<{
  comments: Comment[];
  loading: boolean;
  hasNext: boolean;
  error: string;
}>();

const emit = defineEmits<{
  loadMore: [];
  retry: [];
  clearError: [];
  likeComment: [comment: Comment];
  likeReply: [reply: Comment["replies"][number]];
}>();
</script>

<template>
  <section class="ik-discussion-comments">
    <h2 class="ik-discussion-comments__title">
      评论区
    </h2>

    <div class="ik-discussion-comments__viewport">
      <z-scrollbar class="ik-discussion-comments__scrollbar">
        <div class="ik-discussion-comments__scroll-content">
          <!-- 评论列表 - 始终显示（如果有评论） -->
          <div v-if="comments.length" class="ik-discussion-comments__list">
            <CommentItem
              v-for="comment in comments"
              :key="comment.id"
              :comment="comment"
              @like-comment="emit('likeComment', comment)"
              @like-reply="emit('likeReply', $event)"
            />
          </div>

          <!-- 空状态 - 仅在没有评论且没有错误时显示 -->
          <div v-else-if="!loading && !error" class="ik-empty">
            暂时还没有评论
          </div>

          <!-- 加载中提示 - 放在列表底部（仅在已有评论且正在加载时显示） -->
          <div v-if="loading && comments.length" class="ik-discussion-comments__loading--inline">
            正在加载更多...
          </div>
        </div>
      </z-scrollbar>
    </div>

    <!-- 底部控制区 - 固定在 viewport 下方 -->
    <!-- 仅在需要显示按钮或状态文本时显示 -->
    <div v-if="!error && (!loading || !comments.length)" class="ik-discussion-comments__footer">
      <!-- 加载中（首次加载） -->
      <div v-if="loading && !comments.length" class="ik-discussion-comments__loading">
        正在加载评论...
      </div>

      <!-- 加载更多按钮 -->
      <div v-else-if="hasNext && !loading" class="ik-discussion-comments__load-more">
        <z-button type="default" @click="emit('loadMore')">
          加载更多评论
        </z-button>
      </div>

      <!-- 已加载全部 -->
      <div v-else-if="comments.length && !hasNext && !loading" class="ik-discussion-comments__end">
        <span class="ik-meta">评论已全部加载</span>
      </div>
    </div>

    <!-- 错误提示 - 固定在底部（只要有错误就显示） -->
    <div v-else class="ik-discussion-comments__footer-error">
      <p>{{ error }}</p>
      <div class="ik-discussion-comments__error-actions">
        <z-button size="small" type="primary" @click="emit('retry')">
          重试
        </z-button>
        <z-button size="small" type="default" @click="emit('clearError')">
          关闭
        </z-button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.ik-discussion-comments {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.ik-discussion-comments__title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--ik-text);
  flex-shrink: 0;
  padding: 16px 16px 12px;
}

.ik-discussion-comments__viewport {
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

.ik-discussion-comments__scrollbar {
  width: 100%;
  height: 100%;
}

.ik-discussion-comments__scroll-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 100%;
  padding: 0 16px 16px;
  box-sizing: border-box;
}

.ik-discussion-comments__list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* 内联加载中提示（在列表底部） */
.ik-discussion-comments__loading--inline {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 12px;
  flex-shrink: 0;
  color: var(--ik-muted);
  font-size: 13px;
}

/* 底部固定控制区 */
.ik-discussion-comments__footer {
  flex-shrink: 0;
  padding: 12px 16px;
  background: rgba(0, 0, 0, 0.15);
  border-top: 1px solid #2d2d2d;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 52px;
}

.ik-discussion-comments__load-more,
.ik-discussion-comments__end,
.ik-discussion-comments__loading {
  display: flex;
  justify-content: center;
  align-items: center;
}

.ik-discussion-comments__end {
  color: var(--ik-muted);
  font-size: 13px;
}

.ik-discussion-comments__loading {
  color: var(--ik-muted);
  font-size: 13px;
}

/* 底部固定错误提示 */
.ik-discussion-comments__footer-error {
  flex-shrink: 0;
  padding: 12px 16px;
  background: rgba(102, 46, 46, 0.15);
  border-top: 1px solid #662e2e;
  color: #ffb1b1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  min-height: 52px;
}

.ik-discussion-comments__footer-error p {
  margin: 0;
  font-size: 13px;
  flex: 1;
}

.ik-discussion-comments__footer-error .ik-discussion-comments__error-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

@media (max-width: 768px) {
  .ik-discussion-comments__title {
    padding: 12px 12px 10px;
    font-size: 16px;
  }

  .ik-discussion-comments__scroll-content {
    padding: 0 12px 12px;
  }

  .ik-discussion-comments__footer {
    padding: 12px;
  }

  .ik-discussion-comments__footer-error {
    flex-direction: column;
    align-items: stretch;
  }

  .ik-discussion-comments__footer-error .ik-discussion-comments__error-actions {
    justify-content: stretch;
  }

  .ik-discussion-comments__footer-error .ik-discussion-comments__error-actions :deep(.z-button) {
    flex: 1;
  }
}
</style>
