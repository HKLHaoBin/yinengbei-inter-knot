import { describe, expect, it } from "vitest";
import { resolveErrorMessage } from "~/utils/api-error";
import type { ApiClientError } from "~/types/api";

describe("api error resolver", () => {
  it("maps captcha error code to chinese message", () => {
    const err = new Error("x") as ApiClientError;
    err.code = "CAPTCHA_REQUIRED";
    expect(resolveErrorMessage(err)).toBe("请先完成验证码验证");
  });

  it("falls back to error message when no known code", () => {
    const err = new Error("邮箱或密码错误");
    expect(resolveErrorMessage(err)).toBe("邮箱或密码错误");
  });
});
