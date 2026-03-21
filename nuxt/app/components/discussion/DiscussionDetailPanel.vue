<script setup lang="ts">
import type { Discussion } from "~/types/entities";

defineProps<{
  discussion: Discussion;
}>();
</script>

<template>
  <article class="ik-discussion-main">
    <!-- 封面图 -->
    <div v-if="discussion.cover" class="ik-discussion-cover">
      <img :src="discussion.cover" alt="封面图" />
    </div>

    <!-- 标题和元信息 -->
    <div class="ik-discussion-detail-header">
      <h1 class="ik-discussion-detail-title">
        {{ discussion.title }}
      </h1>
      <div class="ik-discussion-detail-meta">
        <span class="ik-discussion-detail-meta__item">
          作者：<strong>{{ discussion.author.name || "未知作者" }}</strong>
        </span>
        <span class="ik-discussion-detail-meta__item">
          {{ discussion.views || 0 }} 阅读
        </span>
        <span class="ik-discussion-detail-meta__item">
          {{ discussion.commentsCount || 0 }} 评论
        </span>
        <span class="ik-discussion-detail-meta__item">
          {{ discussion.likesCount || 0 }} 点赞
        </span>
      </div>
    </div>

    <!-- 正文内容 -->
    <div class="ik-discussion-detail-body">
      <p class="ik-discussion-detail-content">
        {{ discussion.bodyText || discussion.rawBodyText || discussion.body || "暂无正文内容" }}
      </p>
    </div>
  </article>
</template>

<style scoped>
.ik-discussion-main {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 16px;
}

/* 封面图 */
.ik-discussion-cover {
  width: 100%;
  border-radius: 12px;
  overflow: hidden;
  border: 4px solid #313132;
  background: #070707;
}

.ik-discussion-cover img {
  width: 100%;
  height: auto;
  display: block;
}

/* 标题区 */
.ik-discussion-detail-header {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.ik-discussion-detail-title {
  margin: 0;
  font-size: 28px;
  font-weight: 900;
  letter-spacing: 0.8px;
  color: var(--ik-text);
  line-height: 1.3;
}

.ik-discussion-detail-meta {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.ik-discussion-detail-meta__item {
  color: var(--ik-muted);
  font-size: 13px;
}

/* 正文内容 */
.ik-discussion-detail-body {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid #2d2d2d;
}

.ik-discussion-detail-content {
  margin: 0;
  line-height: 1.75;
  white-space: pre-wrap;
  color: #f0f0f0;
  font-size: 15px;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .ik-discussion-main {
    padding: 12px;
    gap: 16px;
  }

  .ik-discussion-detail-title {
    font-size: 22px;
  }

  .ik-discussion-detail-meta {
    gap: 10px;
  }

  .ik-discussion-detail-body {
    padding: 16px;
  }

  .ik-discussion-detail-content {
    font-size: 14px;
  }
}
</style>
