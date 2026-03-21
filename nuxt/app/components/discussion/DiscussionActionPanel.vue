<script setup lang="ts">
import type { Discussion } from "~/types/entities";
import { useAuthStore } from "~/stores/auth";

const props = defineProps<{
  discussion: Discussion;
  sending: boolean;
  auth: ReturnType<typeof useAuthStore>;
  modelValue: string;
  error: string;
  likeError: string;
}>();

const emit = defineEmits<{
  like: [];
  sendComment: [];
  clearSendError: [];
  "update:modelValue": [value: string];
}>();

const commentInput = computed({
  get: () => props.modelValue,
  set: (value) => emit("update:modelValue", value),
});
</script>

<template>
  <section class="ik-discussion-actions">
    <!-- 点赞失败提示 -->
    <div v-if="likeError" class="ik-discussion-actions__error">
      <p>{{ likeError }}</p>
    </div>

    <!-- 操作按钮组 -->
    <div class="ik-discussion-actions__buttons">
      <z-button
        :type="discussion.liked ? 'primary' : 'default'"
        @click="emit('like')"
      >
        {{ discussion.liked ? "已点赞" : "点赞" }}
      </z-button>
      <z-button disabled title="功能开发中">
        收藏
      </z-button>
      <z-button disabled title="功能开发中">
        分享
      </z-button>
    </div>

    <!-- 评论输入区 -->
    <div class="ik-discussion-actions__comment-input">
      <h3 class="ik-discussion-actions__title">
        发表评论
      </h3>
      <z-input
        v-model="commentInput"
        type="textarea"
        placeholder="说点什么..."
        :disabled="sending"
        rows="3"
      />

      <!-- 发送失败提示 -->
      <div v-if="error" class="ik-discussion-actions__send-error">
        <p>{{ error }}</p>
        <button class="ik-discussion-actions__clear-error" @click="emit('clearSendError')">
          关闭
        </button>
      </div>

      <div class="ik-row">
        <z-button :loading="sending" @click="emit('sendComment')">
          发送评论
        </z-button>
        <NuxtLink v-if="!auth.isLogin" to="/login" class="ik-meta">
          登录后可评论
        </NuxtLink>
      </div>
    </div>
  </section>
</template>

<style scoped>
.ik-discussion-actions {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 16px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
  border: 1px solid #2d2d2d;
  flex-shrink: 0;
}

.ik-discussion-actions__error {
  padding: 8px 12px;
  background: rgba(102, 46, 46, 0.15);
  border: 1px solid #662e2e;
  border-radius: 6px;
  color: #ffb1b1;
  font-size: 13px;
}

.ik-discussion-actions__error p {
  margin: 0;
}

.ik-discussion-actions__buttons {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.ik-discussion-actions__comment-input {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.ik-discussion-actions__title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--ik-muted);
}

.ik-discussion-actions__send-error {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 12px;
  background: rgba(102, 46, 46, 0.15);
  border: 1px solid #662e2e;
  border-radius: 6px;
  color: #ffb1b1;
  font-size: 13px;
}

.ik-discussion-actions__send-error p {
  margin: 0;
  flex: 1;
}

.ik-discussion-actions__clear-error {
  background: transparent;
  border: none;
  color: var(--ik-muted);
  cursor: pointer;
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 4px;
  transition: all 0.2s;
}

.ik-discussion-actions__clear-error:hover {
  background: rgba(255, 255, 255, 0.1);
  color: var(--ik-text);
}

.ik-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

@media (max-width: 768px) {
  .ik-discussion-actions {
    padding: 12px;
    gap: 12px;
  }

  .ik-discussion-actions__buttons {
    gap: 8px;
  }
}
</style>
