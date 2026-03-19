import type { CaptchaPayload } from "~/types/captcha";

export function assertCaptchaPayload(payload: unknown): CaptchaPayload {
  if (!payload || typeof payload !== "object") {
    throw new Error("验证码结果无效");
  }
  const typed = payload as Record<string, unknown>;
  const result = {
    lot_number: String(typed.lot_number || ""),
    captcha_output: String(typed.captcha_output || ""),
    pass_token: String(typed.pass_token || ""),
    gen_time: String(typed.gen_time || ""),
  };

  if (
    !result.lot_number ||
    !result.captcha_output ||
    !result.pass_token ||
    !result.gen_time
  ) {
    throw new Error("验证码结果不完整");
  }

  return result;
}
