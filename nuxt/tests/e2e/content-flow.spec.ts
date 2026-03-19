import { expect, test } from "@playwright/test";

test.describe("content flow", () => {
  test("search -> detail -> comment -> like", async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem("access_token", "token-123");
      (window as any).interKnotVerifyCaptcha = async () => ({
        lot_number: "lot",
        captcha_output: "output",
        pass_token: "token",
        gen_time: "100",
      });
    });

    await page.route("**/api/articles/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              documentId: "d1",
              title: "帖子一",
              bodyText: "摘要一",
              views: 10,
              author: { name: "作者甲" },
            },
          ],
        }),
      });
    });

    await page.route("**/api/articles/search**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              documentId: "d1",
              title: "帖子一",
              bodyText: "摘要一",
              views: 10,
              author: { name: "作者甲" },
            },
          ],
        }),
      });
    });

    await page.route("**/api/articles/detail/d1", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: {
            documentId: "d1",
            title: "帖子一",
            bodyText: "正文内容",
            likesCount: 1,
            commentsCount: 1,
            author: { name: "作者甲" },
          },
        }),
      });
    });

    await page.route("**/api/comments/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              documentId: "c1",
              content: "评论一",
              likesCount: 1,
              author: { name: "评论用户" },
              replies: [],
            },
          ],
        }),
      });
    });

    await page.route("**/api/comments", async (route) => {
      if (route.request().method() === "POST") {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify({ data: { ok: true } }),
        });
        return;
      }
      await route.continue();
    });

    await page.route("**/api/likes/toggle", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          liked: true,
          likesCount: 2,
        }),
      });
    });

    await page.route("**/api/article-reads/batch", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [{ isRead: true }],
        }),
      });
    });

    await page.goto("/");
    await expect(page.getByText("帖子一")).toBeVisible();
    await page.getByText("帖子一").first().click();
    await expect(page).toHaveURL("/discussion/d1");
    await page.getByPlaceholder("说点什么...").fill("新评论");
    await page.getByRole("button", { name: "发送评论" }).click();
    await page.getByRole("button", { name: /点赞/ }).first().click();
  });
});
