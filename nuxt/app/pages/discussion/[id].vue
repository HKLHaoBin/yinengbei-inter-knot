<script setup lang="ts">
import type { ApiClientError } from "~/types/api";
import type { Comment, Discussion } from "~/types/entities";
import { resolveErrorMessage } from "~/utils/api-error";
import { useAuthStore } from "~/stores/auth";

const route = useRoute();
const api = useApi();
const captcha = useCaptcha();
const auth = useAuthStore();

const discussion = ref<Discussion | null>(null);
const loading = ref(true);
const errorMessage = ref("");

const comments = ref<Comment[]>([]);
const commentsCursor = ref("");
const commentsHasNext = ref(true);
const commentsLoading = ref(false);

const sendingComment = ref(false);

const discussionId = computed(() => String(route.params.id || ""));

const loadDiscussion = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    discussion.value = await api.getDiscussion(discussionId.value);
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "获取帖子详情失败");
  } finally {
    loading.value = false;
  }
};

const loadComments = async () => {
  if (commentsLoading.value || !commentsHasNext.value) return;
  commentsLoading.value = true;
  try {
    const page = await api.getComments(discussionId.value, commentsCursor.value);
    comments.value.push(...page.nodes);
    commentsCursor.value = page.endCursor;
    commentsHasNext.value = page.hasNextPage;
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "获取评论失败");
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
  errorMessage.value = "";
  try {
    let captchaPayload = await captcha.verify("commentCreate");
    await api.addDiscussionComment({
      discussionId: discussionId.value,
      content: newComment.value.trim(),
      captcha: captchaPayload,
    });
    // 更新评论计数
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
          discussionId: discussionId.value,
          content: newComment.value.trim(),
          captcha: verified,
        });
        // 更新评论计数
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
        errorMessage.value = resolveErrorMessage(retryErr, "评论发送失败");
      }
    } else {
      errorMessage.value = resolveErrorMessage(err, "评论发送失败");
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
  try {
    const result = await api.toggleLike("article", discussion.value.id);
    discussion.value.liked = result.liked;
    discussion.value.likesCount = result.likesCount;
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "点赞失败");
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
    errorMessage.value = resolveErrorMessage(err, "评论点赞失败");
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
    errorMessage.value = resolveErrorMessage(err, "回复点赞失败");
  }
};

const goBack = () => {
  navigateTo("/");
};

// 评论输入框
const newComment = ref("");

onMounted(async () => {
  await loadDiscussion();
  await loadComments();
});
</script>

<template>
  <section class="ik-discussion-detail container">
    <div v-if="loading" class="ik-empty">正在加载帖子详情...</div>
    <div v-else-if="errorMessage" class="ik-panel" style="border-color: #662e2e; color: #ffb1b1">
      {{ errorMessage }}
    </div>
    <template v-else-if="discussion">
      <div class="ik-discussion-stage">
        <!-- 顶部作者信息条 -->
        <DiscussionHeaderBar
          :discussion="discussion"
          @close="goBack"
        />

        <!-- 主体内容区 -->
        <div class="ik-discussion-stage__body">
          <!-- 左侧详情面板 -->
          <DiscussionDetailPanel
            class="ik-discussion-stage__main"
            :discussion="discussion"
          />

          <!-- 右侧边栏 -->
          <aside class="ik-discussion-stage__side">
            <!-- 评论面板 -->
            <DiscussionCommentPanel
              class="ik-discussion-stage__comments"
              :comments="comments"
              :loading="commentsLoading"
              :has-next="commentsHasNext"
              @load-more="loadComments"
              @like-comment="likeComment"
              @like-reply="likeReply"
            />

            <!-- 操作面板 -->
            <DiscussionActionPanel
              class="ik-discussion-stage__actions"
              :discussion="discussion"
              :sending="sendingComment"
              :auth="auth"
              :model-value="newComment"
              @update:model-value="newComment = $event"
              @like="likeArticle"
              @send-comment="sendComment"
            />
          </aside>
        </div>
      </div>
    </template>
  </section>
</template>

<style scoped>
/* 页面容器 */
.ik-discussion-detail {
  padding: 20px 0;
}

/* 主舞台容器 */
.ik-discussion-stage {
  border-radius: 16px;
  border: 1px solid #2d2d2d;
  background: linear-gradient(180deg, #212121 0%, #181818 100%);
  overflow: hidden;
}

/* 主体布局 */
.ik-discussion-stage__body {
  display: grid;
  grid-template-columns: 1fr 420px;
  gap: 0;
}

.ik-discussion-stage__main {
  border-right: 1px solid #2d2d2d;
}

.ik-discussion-stage__side {
  display: flex;
  flex-direction: column;
  border-left: 1px solid #2d2d2d;
}

.ik-discussion-stage__comments {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  border-bottom: 1px solid #2d2d2d;
}

/* 响应式布局 - 平板 */
@media (max-width: 959px) {
  .ik-discussion-stage__body {
    grid-template-columns: 1fr 350px;
  }
}

/* 响应式布局 - 移动端 */
@media (max-width: 767px) {
  .ik-discussion-stage {
    border-radius: 0;
    border: none;
    background: transparent;
  }

  .ik-discussion-stage__body {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .ik-discussion-stage__main {
    border-right: none;
    border-bottom: 1px solid #2d2d2d;
    border-radius: 12px;
    background: linear-gradient(180deg, #212121 0%, #181818 100%);
  }

  .ik-discussion-stage__side {
    border-left: none;
    gap: 16px;
  }

  .ik-discussion-stage__comments {
    border-bottom: none;
    border-radius: 12px;
    background: linear-gradient(180deg, #212121 0%, #181818 100%);
  }

  .ik-discussion-stage__actions {
    border-radius: 12px;
    background: linear-gradient(180deg, #212121 0%, #181818 100%);
  }
}
</style>
