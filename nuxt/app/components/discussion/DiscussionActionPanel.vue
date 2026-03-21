<script setup lang="ts">
import type { Discussion } from "~/types/entities";
import { useAuthStore } from "~/stores/auth";

const props = defineProps<{
  discussion: Discussion;
  sending: boolean;
  auth: ReturnType<typeof useAuthStore>;
  modelValue: string;
}>();

const emit = defineEmits<{
  like: [];
  sendComment: [];
  "update:modelValue": [value: string];
}>();

const commentInput = computed({
  get: () => props.modelValue,
  set: (value) => emit("update:modelValue", value),
});
</script>

<template>
  <section class="ik-discussion-actions">
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
