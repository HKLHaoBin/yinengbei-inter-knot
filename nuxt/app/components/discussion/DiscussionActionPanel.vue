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

type ActionMode = "default" | "comment";

const mode = ref<ActionMode>("default");
const commentInputRef = ref<HTMLInputElement | null>(null);

const commentInput = computed({
  get: () => props.modelValue,
  set: (value) => emit("update:modelValue", value),
});

const handleCommentClick = () => {
  if (mode.value === "default") {
    mode.value = "comment";
    nextTick(() => {
      commentInputRef.value?.focus();
    });
  } else {
    mode.value = "default";
  }
};

const handleSendComment = async () => {
  await emit("sendComment");
  if (!props.error) {
    mode.value = "default";
  }
};

watch(
  () => props.error,
  (newError) => {
    if (newError && mode.value === "default") {
      mode.value = "comment";
    }
  },
);
</script>

<template>
  <section class="ik-discussion-actions">
    <div v-if="likeError" class="ik-discussion-actions__error">
      <p>{{ likeError }}</p>
    </div>

    <div v-if="mode === 'default'" class="ik-discussion-actions__buttons">
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
      <z-button
        type="default"
        @click="handleCommentClick"
      >
        评论
      </z-button>
    </div>

    <div v-else class="ik-discussion-actions__comment-input">
      <div class="ik-discussion-actions__input-wrapper">
        <z-input
          ref="commentInputRef"
          v-model="commentInput"
          type="textarea"
          placeholder="说点什么..."
          :disabled="sending"
          rows="3"
          class="ik-discussion-actions__input"
        />
        <z-button
          :loading="sending"
          :disabled="!commentInput.trim()"
          size="small"
          type="primary"
          class="ik-discussion-actions__send-btn"
          @click="handleSendComment"
        >
          发送
        </z-button>
      </div>

      <div v-if="error" class="ik-discussion-actions__send-error">
        <p>{{ error }}</p>
        <z-button size="small" type="default" @click="emit('clearSendError')">
          关闭
        </z-button>
      </div>

      <div v-if="!auth.isLogin" class="ik-discussion-actions__login-tip">
        <NuxtLink to="/login" class="ik-meta">
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
  gap: 12px;
  padding: 12px;
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
  flex-wrap: nowrap;
  align-items: center;
}

.ik-discussion-actions__buttons :deep(.z-button) {
  height: 32px;
  padding: 0 16px;
  font-size: 13px;
}

.ik-discussion-actions__comment-input {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.ik-discussion-actions__input-wrapper {
  position: relative;
}

.ik-discussion-actions__input {
  padding-right: 80px;
}

.ik-discussion-actions__send-btn {
  position: absolute;
  bottom: 8px;
  right: 8px;
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

.ik-discussion-actions__login-tip {
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .ik-discussion-actions {
    padding: 12px;
    gap: 12px;
  }

  .ik-discussion-actions__buttons {
    gap: 8px;
  }

  .ik-discussion-actions__send-error {
    flex-direction: column;
    align-items: stretch;
  }

  .ik-discussion-actions__send-error :deep(.z-button) {
    align-self: flex-end;
  }

  .ik-discussion-actions__input {
    padding-right: 70px;
  }

  .ik-discussion-actions__send-btn {
    bottom: 6px;
    right: 6px;
  }
}
</style>
