import { expect, test } from "@playwright/test";

test.describe("auth flow", () => {
  test("login with captcha mock", async ({ page }) => {
    await page.addInitScript(() => {
      (window as any).interKnotVerifyCaptcha = async () => ({
        lot_number: "lot",
        captcha_output: "output",
        pass_token: "token",
        gen_time: "100",
      });
    });

    await page.route("**/api/captcha/config", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: {
            enabled: true,
            captchaId: "mock-id",
            scenes: {
              login: true,
            },
          },
        }),
      });
    });

    await page.route("**/api/auth/local-with-captcha", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          jwt: "token-123",
          user: {
            documentId: "u1",
            name: "测试用户",
          },
        }),
      });
    });

    await page.route("**/api/users/me**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          documentId: "u1",
          name: "测试用户",
        }),
      });
    });

    await page.goto("/login");
    await page.getByPlaceholder("邮箱").fill("demo@example.com");
    await page.getByPlaceholder("密码").fill("123456");
    await page.getByRole("button", { name: "登录" }).click();

    await expect(page).toHaveURL("/");
  });
});
