<script setup lang="ts">
import type { Comment, CommentReply } from "~/types/entities";

const props = defineProps<{
  comment: Comment;
}>();

const emit = defineEmits<{
  likeComment: [comment: Comment];
  likeReply: [reply: CommentReply];
}>();
</script>

<template>
  <z-card class="ik-comment">
    <div class="ik-stack">
      <div class="ik-row">
        <strong>{{ comment.author?.name || "匿名用户" }}</strong>
        <span class="ik-meta">{{ comment.createdAt || "刚刚" }}</span>
      </div>
      <p class="ik-comment__content">{{ comment.content }}</p>
      <div class="ik-row">
        <z-button @click="emit('likeComment', comment)">
          点赞 {{ comment.likesCount || 0 }}
        </z-button>
      </div>
    </div>

    <div v-if="comment.replies.length" class="ik-replies">
      <div v-for="reply in comment.replies" :key="reply.id" class="ik-reply">
        <div class="ik-row">
          <strong>{{ reply.author?.name || "匿名用户" }}</strong>
          <span class="ik-meta">{{ reply.createdAt || "刚刚" }}</span>
        </div>
        <p class="ik-comment__content">{{ reply.content }}</p>
        <z-button @click="emit('likeReply', reply)">
          点赞 {{ reply.likesCount || 0 }}
        </z-button>
      </div>
    </div>
  </z-card>
</template>

<style scoped>
.ik-comment {
  border-radius: 12px;
}

.ik-comment__content {
  margin: 0;
  line-height: 1.55;
  color: #f0f0f0;
  white-space: pre-wrap;
}

.ik-replies {
  margin-top: 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border-top: 1px dashed #323232;
  padding-top: 12px;
}

.ik-reply {
  border-radius: 10px;
  border: 1px solid #2f2f2f;
  padding: 10px;
}
</style>
