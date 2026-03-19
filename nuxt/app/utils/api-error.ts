import type { ApiClientError } from "~/types/api";

export const CAPTCHA_ERROR_CODE_MAP: Record<string, string> = {
  CAPTCHA_REQUIRED: "请先完成验证码验证",
  CAPTCHA_INVALID: "验证码未通过，请重试",
  CAPTCHA_VERIFY_FAILED: "验证码服务异常，请稍后重试",
  CAPTCHA_NOT_CONFIGURED: "验证码服务未配置完成，请稍后再试",
};

export function normalizeApiError(error: unknown): ApiClientError {
  if (error instanceof Error) {
    return error as ApiClientError;
  }
  return new Error("未知请求异常") as ApiClientError;
}

export function resolveErrorMessage(error: unknown, fallback = "请求失败"): string {
  const e = normalizeApiError(error);

  if (e.code) {
    const mapped = CAPTCHA_ERROR_CODE_MAP[e.code];
    if (mapped) return mapped;
  }

  if (e.details && typeof e.details.code === "string") {
    const mapped = CAPTCHA_ERROR_CODE_MAP[e.details.code];
    if (mapped) return mapped;
  }

  return e.message || fallback;
}
