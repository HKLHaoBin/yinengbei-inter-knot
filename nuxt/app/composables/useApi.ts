import type { ApiClientError, Pagination } from "~/types/api";
import type {
  Author,
  Comment,
  Discussion,
  LikeToggleResult,
  Profile,
} from "~/types/entities";
import type { CaptchaPayload } from "~/types/captcha";
import {
  buildPagination,
  DEFAULT_PAGE_SIZE,
  parseStart,
} from "~/utils/pagination";

interface AuthResult {
  token: string | null;
  user: Author;
}

interface DiscussionCommentPayload {
  discussionId: string;
  content: string;
  parentId?: string;
  captcha?: CaptchaPayload | null;
}

interface MediaMeta {
  url: string;
  width?: number;
  height?: number;
}

function normalizeMediaUrl(input: unknown, apiBaseUrl: string): string {
  if (typeof input !== "string" || !input.trim()) {
    return "";
  }
  const url = input.trim();
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  if (url.startsWith("/")) {
    return `${apiBaseUrl}${url}`;
  }
  return `${apiBaseUrl}/${url}`;
}

function parsePositiveNumber(input: unknown): number | undefined {
  if (typeof input === "number" && Number.isFinite(input) && input > 0) {
    return input;
  }
  if (typeof input === "string") {
    const parsed = Number(input);
    if (Number.isFinite(parsed) && parsed > 0) {
      return parsed;
    }
  }
  return undefined;
}

function extractMediaMeta(raw: unknown, apiBaseUrl: string): MediaMeta | null {
  if (typeof raw === "string") {
    const url = normalizeMediaUrl(raw, apiBaseUrl);
    return url ? { url } : null;
  }

  if (Array.isArray(raw)) {
    for (const item of raw) {
      const media = extractMediaMeta(item, apiBaseUrl);
      if (media) return media;
    }
    return null;
  }

  if (raw && typeof raw === "object") {
    const record = raw as Record<string, unknown>;

    const directUrl = normalizeMediaUrl(record.url, apiBaseUrl);
    if (directUrl) {
      return {
        url: directUrl,
        width: parsePositiveNumber(record.width),
        height: parsePositiveNumber(record.height),
      };
    }

    const attributes = record.attributes;
    if (attributes && typeof attributes === "object") {
      const attrs = attributes as Record<string, unknown>;
      const attrUrl = normalizeMediaUrl(attrs.url, apiBaseUrl);
      if (attrUrl) {
        return {
          url: attrUrl,
          width: parsePositiveNumber(attrs.width),
          height: parsePositiveNumber(attrs.height),
        };
      }
    }

    if (record.data) {
      return extractMediaMeta(record.data, apiBaseUrl);
    }
  }

  return null;
}

function unwrapData<T>(payload: unknown): T {
  if (payload && typeof payload === "object" && "data" in (payload as Record<string, unknown>)) {
    return (payload as { data: T }).data;
  }
  return payload as T;
}

function toAuthor(raw: unknown, apiBaseUrl: string): Author {
  const data = (raw || {}) as Record<string, unknown>;
  const avatar = extractMediaMeta(data.avatar, apiBaseUrl)?.url || "";

  return {
    id: data.id as string | number | undefined,
    documentId: (data.documentId as string | undefined) || (data.id as string | undefined),
    authorId: (data.authorId as string | undefined) || (data.documentId as string | undefined),
    username: data.username as string | undefined,
    login: data.login as string | undefined,
    name:
      (data.name as string | undefined) ||
      (data.username as string | undefined) ||
      (data.login as string | undefined) ||
      "Unknown",
    email: data.email as string | undefined,
    avatar,
    exp: (data.exp as number | undefined) || 0,
    level: (data.level as number | undefined) || 1,
  };
}

function toDiscussion(raw: unknown, apiBaseUrl: string): Discussion {
  const data = (raw || {}) as Record<string, unknown>;
  const cover =
    extractMediaMeta(data.cover, apiBaseUrl) ||
    extractMediaMeta(data.coverImages, apiBaseUrl) ||
    extractMediaMeta(data.covers, apiBaseUrl);

  return {
    id: String(data.documentId || data.id || ""),
    title: String(data.title || "无标题"),
    body: (data.body as string | undefined) || "",
    bodyText: (data.bodyText as string | undefined) || "",
    rawBodyText: (data.rawBodyText as string | undefined) || "",
    cover: cover?.url || "",
    coverWidth: cover?.width,
    coverHeight: cover?.height,
    views: Number(data.views || 0),
    likesCount: Number(data.likesCount || 0),
    commentsCount: Number(data.commentsCount || 0),
    isPinned: data.isPinned === true,
    isRead: data.isRead === true,
    liked: data.liked === true,
    createdAt: data.createdAt as string | undefined,
    updatedAt: data.updatedAt as string | undefined,
    author: toAuthor(data.author, apiBaseUrl),
  };
}

function toComment(raw: unknown, apiBaseUrl: string): Comment {
  const data = (raw || {}) as Record<string, unknown>;
  const repliesRaw = Array.isArray(data.replies) ? data.replies : [];
  return {
    id: String(data.documentId || data.id || ""),
    content: String(data.content || ""),
    liked: data.liked === true,
    likesCount: Number(data.likesCount || 0),
    createdAt: data.createdAt as string | undefined,
    author: toAuthor(data.author, apiBaseUrl),
    replies: repliesRaw.map((item) => {
      const reply = item as Record<string, unknown>;
      return {
        id: String(reply.documentId || reply.id || ""),
        content: String(reply.content || ""),
        liked: reply.liked === true,
        likesCount: Number(reply.likesCount || 0),
        createdAt: reply.createdAt as string | undefined,
        author: toAuthor(reply.author, apiBaseUrl),
      };
    }),
  };
}

export function useApi() {
  const { $api } = useNuxtApp();
  const config = useRuntimeConfig();
  const apiBaseUrl = String(config.public.apiBaseUrl || "").replace(/\/+$/, "");

  const login = async (
    email: string,
    password: string,
    captcha?: CaptchaPayload | null,
  ): Promise<AuthResult> => {
    const endpoint = captcha ? "/api/auth/local-with-captcha" : "/api/auth/local";
    const payload = captcha
      ? { identifier: email, password, captcha }
      : { identifier: email, password };
    const response = await $api(endpoint, { method: "POST", body: payload });
    const data = response as Record<string, unknown>;
    return {
      token: (data.jwt as string | undefined) || null,
      user: toAuthor(data.user, apiBaseUrl),
    };
  };

  const register = async (
    username: string,
    email: string,
    password: string,
    captcha?: CaptchaPayload | null,
  ): Promise<AuthResult> => {
    const endpoint = captcha
      ? "/api/auth/register-with-captcha"
      : "/api/auth/local/register";
    const payload = captcha
      ? { username, email, password, captcha }
      : { username, email, password };
    const response = await $api(endpoint, { method: "POST", body: payload });
    const data = response as Record<string, unknown>;
    return {
      token: (data.jwt as string | undefined) || null,
      user: toAuthor(data.user, apiBaseUrl),
    };
  };

  const getSelfUser = async (): Promise<Author> => {
    const response = await $api("/api/users/me", {
      query: {
        "populate[avatar][fields][0]": "url",
      },
    });
    return toAuthor(response, apiBaseUrl);
  };

  const searchArticles = async (
    query: string,
    endCur = "",
  ): Promise<Pagination<Discussion>> => {
    const start = parseStart(endCur);
    const endpoint = query ? "/api/articles/search" : "/api/articles/list";
    const response = await $api(endpoint, {
      query: {
        ...(query ? { q: query } : {}),
        start: String(start),
        limit: String(DEFAULT_PAGE_SIZE),
      },
    });
    const data = unwrapData<unknown[]>(response) || [];
    return buildPagination(data.map((item) => toDiscussion(item, apiBaseUrl)), start);
  };

  const getDiscussion = async (id: string): Promise<Discussion> => {
    const response = await $api(`/api/articles/detail/${id}`);
    const discussion = toDiscussion(unwrapData(response), apiBaseUrl);

    if (import.meta.client) {
      const userId = localStorage.getItem("user_id");
      if (userId) {
        try {
          const readStatus = await $api("/api/article-reads/batch", {
            method: "POST",
            body: {
              articleDocumentIds: [id],
            },
          });
          const list = unwrapData<Array<{ isRead?: boolean }>>(readStatus);
          if (Array.isArray(list) && list[0]?.isRead === true) {
            discussion.isRead = true;
          }
        } catch {
          // ignore read status failures
        }
      }
    }

    return discussion;
  };

  const getComments = async (
    discussionId: string,
    endCur = "",
  ): Promise<Pagination<Comment>> => {
    const start = parseStart(endCur);
    const response = await $api("/api/comments/list", {
      query: {
        article: discussionId,
        start: String(start),
        limit: String(DEFAULT_PAGE_SIZE),
        ts: String(Date.now()),
      },
    });
    const data = unwrapData<unknown[]>(response) || [];
    return buildPagination(data.map((item) => toComment(item, apiBaseUrl)), start);
  };

  const addDiscussionComment = async ({
    discussionId,
    content,
    parentId,
    captcha,
  }: DiscussionCommentPayload) => {
    return await $api("/api/comments", {
      method: "POST",
      body: {
        data: {
          article: discussionId,
          content,
          ...(parentId ? { parent: parentId } : {}),
        },
        ...(captcha ? { captcha } : {}),
      },
    });
  };

  const toggleLike = async (
    targetType: "article" | "comment",
    targetId: string,
  ): Promise<LikeToggleResult> => {
    const response = await $api("/api/likes/toggle", {
      method: "POST",
      body: {
        targetType,
        targetId,
      },
    });
    const data = response as Record<string, unknown>;
    return {
      liked: data.liked === true,
      likesCount: Number(data.likesCount || 0),
    };
  };

  const batchCheckLikes = async (
    targetType: "article" | "comment",
    targetIds: string[],
  ): Promise<Record<string, boolean>> => {
    if (!targetIds.length) return {};
    const response = await $api("/api/likes/check", {
      query: {
        targetType,
        targetIds: targetIds.join(","),
      },
    });
    return (unwrapData(response) as Record<string, boolean>) || {};
  };

  const markAsReadBatch = async (articleDocumentIds: string[]) => {
    if (!articleDocumentIds.length) return;
    await $api("/api/article-reads/batch", {
      method: "POST",
      body: { articleDocumentIds },
    });
  };

  const getProfile = async (documentId: string): Promise<Profile> => {
    const response = await $api(`/api/profiles/${documentId}`);
    const data = unwrapData<Record<string, unknown>>(response);
    return {
      documentId: String(data.documentId || documentId),
      login: data.login as string | undefined,
      name: data.name as string | undefined,
      bio: data.bio as string | undefined,
      avatar: data.avatar as string | undefined,
      level: Number(data.level || 1),
      exp: Number(data.exp || 0),
    };
  };

  const getProfileArticles = async (
    documentId: string,
    endCur = "",
  ): Promise<Pagination<Discussion>> => {
    const start = parseStart(endCur);
    const response = await $api(`/api/profiles/${documentId}/articles`, {
      query: {
        start: String(start),
        limit: String(DEFAULT_PAGE_SIZE),
      },
    });
    const data = unwrapData<unknown[]>(response) || [];
    return buildPagination(data.map((item) => toDiscussion(item, apiBaseUrl)), start);
  };

  const getProfileComments = async (
    documentId: string,
    endCur = "",
  ): Promise<Pagination<Comment>> => {
    const start = parseStart(endCur);
    const response = await $api(`/api/profiles/${documentId}/comments`, {
      query: {
        start: String(start),
        limit: String(DEFAULT_PAGE_SIZE),
      },
    });
    const data = unwrapData<unknown[]>(response) || [];
    return buildPagination(data.map((item) => toComment(item, apiBaseUrl)), start);
  };

  return {
    login,
    register,
    getSelfUser,
    searchArticles,
    getDiscussion,
    getComments,
    addDiscussionComment,
    toggleLike,
    batchCheckLikes,
    markAsReadBatch,
    getProfile,
    getProfileArticles,
    getProfileComments,
  };
}

export function isApiClientError(err: unknown): err is ApiClientError {
  return !!err && typeof err === "object" && "message" in (err as object);
}
