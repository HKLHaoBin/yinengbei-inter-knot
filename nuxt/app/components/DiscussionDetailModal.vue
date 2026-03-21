<script setup lang="ts">
import type { ApiClientError } from "~/types/api";
import type { Comment, Discussion } from "~/types/entities";
import { resolveErrorMessage } from "~/utils/api-error";
import { useAuthStore } from "~/stores/auth";

const props = defineProps<{
  discussionId: string;
  widthPercent?: number;
  heightPercent?: number;
}>();

const emit = defineEmits<{
  close: [];
}>();

const api = useApi();
const captcha = useCaptcha();
const auth = useAuthStore();

const discussion = ref<Discussion | null>(null);
const loading = ref(true);
const loadError = ref("");

const comments = ref<Comment[]>([]);
const commentsCursor = ref("");
const commentsHasNext = ref(true);
const commentsLoading = ref(false);
const commentsError = ref("");

const sendingComment = ref(false);
const sendCommentError = ref("");

const likeArticleError = ref("");

const newComment = ref("");

const loadDiscussion = async () => {
  loading.value = true;
  loadError.value = "";
  try {
    discussion.value = await api.getDiscussion(props.discussionId);
  } catch (err) {
    loadError.value = resolveErrorMessage(err, "获取帖子详情失败");
  } finally {
    loading.value = false;
  }
};

const loadComments = async () => {
  if (commentsLoading.value || !commentsHasNext.value) return;
  commentsLoading.value = true;
  commentsError.value = "";
  try {
    const page = await api.getComments(props.discussionId, commentsCursor.value);
    comments.value.push(...page.nodes);
    commentsCursor.value = page.endCursor;
    commentsHasNext.value = page.hasNextPage;
  } catch (err) {
    commentsError.value = resolveErrorMessage(err, "获取评论失败");
  } finally {
    commentsLoading.value = false;
  }
};

const retryLoadComments = async () => {
  commentsError.value = "";
  commentsLoading.value = true;
  try {
    const page = await api.getComments(props.discussionId, commentsCursor.value);
    
    if (!commentsCursor.value) {
      comments.value = page.nodes;
    } else {
      const existingIds = new Set(comments.value.map(c => c.id));
      const newNodes = page.nodes.filter(node => !existingIds.has(node.id));
      comments.value.push(...newNodes);
    }
    
    commentsCursor.value = page.endCursor;
    commentsHasNext.value = page.hasNextPage;
  } catch (err) {
    commentsError.value = resolveErrorMessage(err, "获取评论失败");
  } finally {
    commentsLoading.value = false;
  }
};

const sendComment = async () => {
  if (!auth.isLogin) {
    await navigateTo("/login");
    return;
  }
  if (!newComment.value.trim()) {
    return;
  }

  sendingComment.value = true;
  sendCommentError.value = "";
  try {
    let captchaPayload = await captcha.verify("commentCreate");
    await api.addDiscussionComment({
      discussionId: props.discussionId,
      content: newComment.value.trim(),
      captcha: captchaPayload,
    });
    if (discussion.value) {
      discussion.value.commentsCount = (discussion.value.commentsCount || 0) + 1;
    }
    newComment.value = "";
    comments.value = [];
    commentsCursor.value = "";
    commentsHasNext.value = true;
    await loadComments();
  } catch (err) {
    const apiErr = err as ApiClientError;
    if (apiErr.code === "CAPTCHA_REQUIRED") {
      try {
        const verified = await captcha.verifyForRequiredResponse(
          "commentCreate",
          apiErr.details,
        );
        await api.addDiscussionComment({
          discussionId: props.discussionId,
          content: newComment.value.trim(),
          captcha: verified,
        });
        if (discussion.value) {
          discussion.value.commentsCount = (discussion.value.commentsCount || 0) + 1;
        }
        newComment.value = "";
        comments.value = [];
        commentsCursor.value = "";
        commentsHasNext.value = true;
        await loadComments();
        return;
      } catch (retryErr) {
        sendCommentError.value = resolveErrorMessage(retryErr, "评论发送失败");
      }
    } else {
      sendCommentError.value = resolveErrorMessage(err, "评论发送失败");
    }
  } finally {
    sendingComment.value = false;
  }
};

const likeArticle = async () => {
  if (!discussion.value) return;
  if (!auth.isLogin) {
    await navigateTo("/login");
    return;
  }
  likeArticleError.value = "";
  try {
    const result = await api.toggleLike("article", discussion.value.id);
    discussion.value.liked = result.liked;
    discussion.value.likesCount = result.likesCount;
  } catch (err) {
    likeArticleError.value = resolveErrorMessage(err, "点赞失败");
  }
};

const likeComment = async (comment: Comment) => {
  if (!auth.isLogin) {
    await navigateTo("/login");
    return;
  }
  try {
    const result = await api.toggleLike("comment", comment.id);
    comment.liked = result.liked;
    comment.likesCount = result.likesCount;
  } catch (err) {
    console.error("评论点赞失败:", err);
  }
};

const likeReply = async (reply: Comment["replies"][number]) => {
  if (!auth.isLogin) {
    await navigateTo("/login");
    return;
  }
  try {
    const result = await api.toggleLike("comment", reply.id);
    reply.liked = result.liked;
    reply.likesCount = result.likesCount;
  } catch (err) {
    console.error("回复点赞失败:", err);
  }
};

const clearSendError = () => {
  sendCommentError.value = "";
};

const clearCommentsError = () => {
  commentsError.value = "";
};

const handleMaskClick = (e: MouseEvent) => {
  if (e.target === e.currentTarget) {
    emit("close");
  }
};

const handleEscKey = (e: KeyboardEvent) => {
  if (e.key === "Escape") {
    emit("close");
  }
};

onMounted(async () => {
  document.addEventListener("keydown", handleEscKey);
  await loadDiscussion();
  await loadComments();
});

onBeforeUnmount(() => {
  document.removeEventListener("keydown", handleEscKey);
});

watch(
  () => props.discussionId,
  async () => {
    discussion.value = null;
    comments.value = [];
    commentsCursor.value = "";
    commentsHasNext.value = true;
    commentsError.value = "";
    loadError.value = "";
    newComment.value = "";
    await loadDiscussion();
    await loadComments();
  },
);
</script>

<template>
  <Teleport to="body">
    <div class="ik-modal-mask" @click="handleMaskClick">
      <div
        class="ik-modal-container"
        :style="{
          width: `${widthPercent || 82}%`,
          height: `${heightPercent || 88}%`,
        }"
      >
        <div v-if="loading" class="ik-modal-loading">
          正在加载帖子详情...
        </div>

        <div v-else-if="loadError" class="ik-modal-error">
          {{ loadError }}
        </div>

        <template v-else-if="discussion">
          <div class="ik-modal-content">
            <DiscussionHeaderBar
              :discussion="discussion"
              @close="emit('close')"
            />

            <div class="ik-modal-body">
              <DiscussionDetailPanel
                class="ik-modal-main"
                :discussion="discussion"
              />

              <aside class="ik-modal-side">
                <DiscussionCommentPanel
                  class="ik-modal-comments"
                  :comments="comments"
                  :loading="commentsLoading"
                  :has-next="commentsHasNext"
                  :error="commentsError"
                  @load-more="loadComments"
                  @retry="retryLoadComments"
                  @clear-error="clearCommentsError"
                  @like-comment="likeComment"
                  @like-reply="likeReply"
                />

                <DiscussionActionPanel
                  class="ik-modal-actions"
                  :discussion="discussion"
                  :sending="sendingComment"
                  :auth="auth"
                  :model-value="newComment"
                  :error="sendCommentError"
                  :like-error="likeArticleError"
                  @update:model-value="newComment = $event"
                  @like="likeArticle"
                  @send-comment="sendComment"
                  @clear-send-error="clearSendError"
                />
              </aside>
            </div>
          </div>
        </template>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.ik-modal-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(4px);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.ik-modal-container {
  max-width: 1600px;
  min-width: 600px;
  max-height: 100vh;
  min-height: 400px;
  border-radius: 16px;
  background: linear-gradient(180deg, #212121 0%, #181818 100%);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
}

.ik-modal-loading,
.ik-modal-error {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  font-size: 16px;
  color: var(--ik-muted);
}

.ik-modal-error {
  color: #ffb1b1;
}

.ik-modal-content {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
}

.ik-modal-body {
  display: grid;
  grid-template-columns: 1fr 420px;
  gap: 0;
  flex: 1;
  overflow: hidden;
}

.ik-modal-main {
  border-right: 1px solid #2d2d2d;
  overflow-y: auto;
}

.ik-modal-side {
  display: flex;
  flex-direction: column;
  border-left: 1px solid #2d2d2d;
  overflow: hidden;
}

.ik-modal-comments {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  border-bottom: 1px solid #2d2d2d;
}

.ik-modal-main::-webkit-scrollbar,
.ik-modal-comments::-webkit-scrollbar {
  width: 6px;
}

.ik-modal-main::-webkit-scrollbar-track,
.ik-modal-comments::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 3px;
}

.ik-modal-main::-webkit-scrollbar-thumb,
.ik-modal-comments::-webkit-scrollbar-thumb {
  background: #3d3d3d;
  border-radius: 3px;
}

.ik-modal-main::-webkit-scrollbar-thumb:hover,
.ik-modal-comments::-webkit-scrollbar-thumb:hover {
  background: #4d4d4d;
}

@media (max-width: 959px) {
  .ik-modal-body {
    grid-template-columns: 1fr 350px;
  }
}

@media (max-width: 767px) {
  .ik-modal-mask {
    padding: 0;
  }

  .ik-modal-container {
    width: 100vw !important;
    height: 100dvh !important;
    max-width: none;
    min-width: none;
    max-height: none;
    min-height: none;
    border-radius: 0;
  }

  .ik-modal-body {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .ik-modal-main {
    border-right: none;
    border-bottom: 1px solid #2d2d2d;
    border-radius: 12px;
    background: linear-gradient(180deg, #212121 0%, #181818 100%);
    margin: 12px;
  }

  .ik-modal-side {
    border-left: none;
    gap: 16px;
    padding: 0 12px 12px;
  }

  .ik-modal-comments {
    border-bottom: none;
    border-radius: 12px;
    background: linear-gradient(180deg, #212121 0%, #181818 100%);
  }

  .ik-modal-actions {
    border-radius: 12px;
    background: linear-gradient(180deg, #212121 0%, #181818 100%);
  }
}
</style>
