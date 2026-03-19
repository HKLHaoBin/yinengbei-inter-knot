import { expect, test } from "@playwright/test";

test.describe("profile flow", () => {
  test("loads profile, articles and comments", async ({ page }) => {
    await page.route("**/api/profiles/u1", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: {
            documentId: "u1",
            name: "测试用户",
            bio: "你好",
            level: 2,
            exp: 20,
          },
        }),
      });
    });

    await page.route("**/api/profiles/u1/articles**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              documentId: "d1",
              title: "用户帖子",
              bodyText: "帖子摘要",
              author: { name: "测试用户" },
            },
          ],
        }),
      });
    });

    await page.route("**/api/profiles/u1/comments**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              documentId: "c1",
              content: "用户评论",
              author: { name: "测试用户" },
              replies: [],
            },
          ],
        }),
      });
    });

    await page.goto("/profile/u1");
    await expect(page.getByRole("heading", { name: "测试用户" })).toBeVisible();
    await expect(page.getByText("用户帖子")).toBeVisible();
  });
});
