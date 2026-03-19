import { describe, expect, it } from "vitest";
import { assertCaptchaPayload } from "~/utils/captcha";

describe("captcha payload parser", () => {
  it("parses valid payload", () => {
    const payload = assertCaptchaPayload({
      lot_number: "lot",
      captcha_output: "output",
      pass_token: "token",
      gen_time: "123",
    });
    expect(payload.captcha_output).toBe("output");
  });

  it("throws when payload is incomplete", () => {
    expect(() =>
      assertCaptchaPayload({
        lot_number: "lot",
      }),
    ).toThrow("验证码结果不完整");
  });
});
