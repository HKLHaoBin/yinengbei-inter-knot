<script setup lang="ts">
import type { Comment, Discussion, Profile } from "~/types/entities";
import { resolveErrorMessage } from "~/utils/api-error";

const route = useRoute();
const api = useApi();

const profile = ref<Profile | null>(null);
const errorMessage = ref("");
const loading = ref(false);

const tab = ref<"articles" | "comments">("articles");

const articles = ref<Discussion[]>([]);
const articleCursor = ref("");
const articleHasNext = ref(true);
const articleLoading = ref(false);

const comments = ref<Comment[]>([]);
const commentCursor = ref("");
const commentHasNext = ref(true);
const commentLoading = ref(false);

const profileId = computed(() => String(route.params.id || ""));

const loadProfile = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    profile.value = await api.getProfile(profileId.value);
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "获取用户信息失败");
  } finally {
    loading.value = false;
  }
};

const loadProfileArticles = async () => {
  if (articleLoading.value || !articleHasNext.value) return;
  articleLoading.value = true;
  try {
    const page = await api.getProfileArticles(profileId.value, articleCursor.value);
    articles.value.push(...page.nodes);
    articleCursor.value = page.endCursor;
    articleHasNext.value = page.hasNextPage;
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "获取用户帖子失败");
  } finally {
    articleLoading.value = false;
  }
};

const loadProfileComments = async () => {
  if (commentLoading.value || !commentHasNext.value) return;
  commentLoading.value = true;
  try {
    const page = await api.getProfileComments(profileId.value, commentCursor.value);
    comments.value.push(...page.nodes);
    commentCursor.value = page.endCursor;
    commentHasNext.value = page.hasNextPage;
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "获取用户评论失败");
  } finally {
    commentLoading.value = false;
  }
};

watch(
  () => tab.value,
  async (next) => {
    if (next === "articles" && !articles.value.length) {
      await loadProfileArticles();
    }
    if (next === "comments" && !comments.value.length) {
      await loadProfileComments();
    }
  },
);

onMounted(async () => {
  await loadProfile();
  await loadProfileArticles();
});
</script>

<template>
  <section class="container ik-stack">
    <div v-if="loading" class="ik-empty">正在加载个人资料...</div>
    <template v-else-if="profile">
      <z-card class="ik-panel">
        <div class="ik-row" style="align-items: flex-start">
          <div class="ik-avatar">{{ (profile.name || profile.login || "U")[0] }}</div>
          <div class="ik-stack" style="gap: 4px">
            <h1 class="ik-title" style="margin: 0">{{ profile.name || profile.login || "匿名用户" }}</h1>
            <span class="ik-meta">等级 {{ profile.level || 1 }} · 经验 {{ profile.exp || 0 }}</span>
            <p class="ik-meta">{{ profile.bio || "这个人很神秘，什么都没有留下。" }}</p>
          </div>
        </div>
      </z-card>

      <ClientOnly>
        <z-tabs v-model="tab">
          <z-tab-panel name="articles" label="帖子">
            <div class="ik-stack">
              <div v-if="!articles.length" class="ik-empty">暂无帖子</div>
              <DiscussionCard v-for="item in articles" :key="item.id" :discussion="item" />
              <div class="ik-row" style="justify-content: center">
                <z-button v-if="articleHasNext" :loading="articleLoading" @click="loadProfileArticles">
                  加载更多帖子
                </z-button>
                <span v-else class="ik-meta">帖子已全部加载</span>
              </div>
            </div>
          </z-tab-panel>
          <z-tab-panel name="comments" label="评论">
            <div class="ik-stack">
              <div v-if="!comments.length" class="ik-empty">暂无评论</div>
              <CommentItem
                v-for="item in comments"
                :key="item.id"
                :comment="item"
                @like-comment="() => undefined"
                @like-reply="() => undefined"
              />
              <div class="ik-row" style="justify-content: center">
                <z-button v-if="commentHasNext" :loading="commentLoading" @click="loadProfileComments">
                  加载更多评论
                </z-button>
                <span v-else class="ik-meta">评论已全部加载</span>
              </div>
            </div>
          </z-tab-panel>
        </z-tabs>
      </ClientOnly>
    </template>

    <div v-if="errorMessage" class="ik-panel" style="border-color: #662e2e; color: #ffb1b1">
      {{ errorMessage }}
    </div>
  </section>
</template>

<style scoped>
.ik-avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  border: 1px solid #3c3c3c;
  background: #171717;
  display: grid;
  place-items: center;
  color: var(--ik-primary);
  font-size: 24px;
  font-weight: 900;
}
</style>
