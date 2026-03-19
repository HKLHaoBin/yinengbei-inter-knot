import {
  $fetch,
  type FetchContext,
  type FetchOptions,
  type FetchResponse,
} from "ofetch";
import type { ApiClientError } from "~/types/api";
import { shouldAttachToken } from "~/utils/request-auth";

function toApiError(statusCode: number | undefined, data: unknown): ApiClientError {
  const error = new Error("请求失败") as ApiClientError;
  error.statusCode = statusCode;

  if (data && typeof data === "object") {
    const typed = data as Record<string, unknown>;
    const bodyError = typed.error as Record<string, unknown> | undefined;
    if (bodyError) {
      if (typeof bodyError.message === "string") {
        error.message = bodyError.message;
      }
      if (typeof bodyError.code === "string") {
        error.code = bodyError.code;
      }
      if (bodyError.details && typeof bodyError.details === "object") {
        error.details = bodyError.details as Record<string, unknown>;
      }
    }
  }

  return error;
}

export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig();

  const api = $fetch.create({
    baseURL: config.public.apiBaseUrl,
    headers: {
      "Content-Type": "application/json",
    },
    onRequest(ctx: FetchContext) {
      const options = ctx.options as FetchOptions;
      const request = String(ctx.request);
      if (import.meta.client) {
        const token = localStorage.getItem("access_token") || "";
        const path = request;
        const method = (options.method || "GET").toUpperCase();
        if (shouldAttachToken(path, method, token)) {
          options.headers = {
            ...options.headers,
            Authorization: `Bearer ${token}`,
          };
        }
      }
    },
    onResponseError(ctx: FetchContext & { response?: FetchResponse<unknown> }) {
      throw toApiError(ctx.response?.status, ctx.response?._data);
    },
  });

  return {
    provide: {
      api,
    },
  };
});

declare module "#app" {
  interface NuxtApp {
    $api: typeof $fetch;
  }
}

declare module "vue" {
  interface ComponentCustomProperties {
    $api: typeof $fetch;
  }
}
