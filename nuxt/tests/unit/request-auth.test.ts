import { describe, expect, it } from "vitest";
import { isPublicGetEndpoint, shouldAttachToken } from "~/utils/request-auth";

describe("request auth header policy", () => {
  it("does not attach token for public article list get", () => {
    expect(isPublicGetEndpoint("/api/articles/list", "GET")).toBe(true);
    expect(shouldAttachToken("/api/articles/list", "GET", "token")).toBe(false);
  });

  it("attaches token for private get", () => {
    expect(shouldAttachToken("/api/articles/my/published", "GET", "token")).toBe(true);
  });

  it("attaches token for non-get methods", () => {
    expect(shouldAttachToken("/api/comments", "POST", "token")).toBe(true);
  });
});
