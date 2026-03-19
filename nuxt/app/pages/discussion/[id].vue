<script setup lang="ts">
import type { ApiClientError } from "~/types/api";
import type { Comment, Discussion } from "~/types/entities";
import { resolveErrorMessage } from "~/utils/api-error";

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

const newComment = ref("");
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

onMounted(async () => {
  await loadDiscussion();
  await loadComments();
});
</script>

<template>
  <section class="container ik-stack">
    <div v-if="loading" class="ik-empty">正在加载帖子详情...</div>
    <div v-else-if="errorMessage" class="ik-panel" style="border-color: #662e2e; color: #ffb1b1">
      {{ errorMessage }}
    </div>
    <template v-else-if="discussion">
      <z-card class="ik-panel">
        <div class="ik-stack">
          <h1 class="ik-title">{{ discussion.title }}</h1>
          <div class="ik-row">
            <span class="ik-meta">作者：{{ discussion.author.name || "未知作者" }}</span>
            <span class="ik-meta">{{ discussion.views || 0 }} 阅读</span>
            <span class="ik-meta">{{ discussion.commentsCount || 0 }} 评论</span>
          </div>
          <p class="ik-discussion-content">
            {{ discussion.bodyText || discussion.rawBodyText || discussion.body || "暂无正文内容" }}
          </p>
          <div class="ik-row">
            <z-button @click="likeArticle">
              {{ discussion.liked ? "取消点赞" : "点赞" }}
              {{ discussion.likesCount || 0 }}
            </z-button>
          </div>
        </div>
      </z-card>

      <z-card class="ik-panel">
        <div class="ik-stack">
          <h2 style="margin: 0">发表评论</h2>
          <z-input v-model="newComment" type="textarea" placeholder="说点什么..." />
          <div class="ik-row">
            <z-button :loading="sendingComment" @click="sendComment">发送评论</z-button>
            <NuxtLink v-if="!auth.isLogin" to="/login" class="ik-meta">登录后可评论</NuxtLink>
          </div>
        </div>
      </z-card>

      <section class="ik-stack">
        <h2 style="margin: 0">评论区</h2>
        <div v-if="!comments.length" class="ik-empty">暂时还没有评论</div>
        <CommentItem
          v-for="comment in comments"
          :key="comment.id"
          :comment="comment"
          @like-comment="likeComment"
          @like-reply="likeReply"
        />
        <div class="ik-row" style="justify-content: center">
          <z-button v-if="commentsHasNext" :loading="commentsLoading" @click="loadComments">
            加载更多评论
          </z-button>
          <span v-else class="ik-meta">评论已全部加载</span>
        </div>
      </section>
    </template>
  </section>
</template>

<style scoped>
.ik-discussion-content {
  margin: 0;
  line-height: 1.65;
  white-space: pre-wrap;
}
</style>
