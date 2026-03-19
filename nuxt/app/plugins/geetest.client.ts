declare global {
  interface Window {
    initGeetest4?: (options: Record<string, unknown>, cb: (instance: GeetestInstance) => void) => void;
    interKnotVerifyCaptcha?: (captchaId: string) => Promise<unknown>;
  }
}

interface GeetestInstance {
  onSuccess(cb: () => void): void;
  onError(cb: (error: { msg?: string }) => void): void;
  onClose(cb: () => void): void;
  onReady(cb: () => void): void;
  showCaptcha(): void;
  getValidate(): unknown;
  destroy(): void;
}

let scriptPromise: Promise<void> | null = null;

function ensureCaptchaScriptLoaded(): Promise<void> {
  if (typeof window === "undefined") {
    return Promise.reject(new Error("captcha only works on client"));
  }
  if (typeof window.initGeetest4 === "function") {
    return Promise.resolve();
  }
  if (scriptPromise) {
    return scriptPromise;
  }

  scriptPromise = new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "https://static.geetest.com/v4/gt4.js";
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("验证码脚本加载失败"));
    document.head.appendChild(script);
  });

  return scriptPromise;
}

export default defineNuxtPlugin(() => {
  if (typeof window === "undefined") {
    return;
  }

  window.interKnotVerifyCaptcha = async (captchaId: string) => {
    await ensureCaptchaScriptLoaded();

    return await new Promise((resolve, reject) => {
      if (typeof window.initGeetest4 !== "function") {
        reject(new Error("验证码脚本未加载完成"));
        return;
      }

      let settled = false;

      window.initGeetest4(
        {
          captchaId,
          product: "bind",
          language: "zho",
        },
        (captchaObj) => {
          const cleanup = () => {
            try {
              captchaObj.destroy();
            } catch {
              // ignore destroy errors
            }
          };

          captchaObj.onSuccess(() => {
            if (settled) return;
            settled = true;
            const result = captchaObj.getValidate();
            cleanup();
            if (result) {
              resolve(result);
              return;
            }
            reject(new Error("验证码结果无效"));
          });

          captchaObj.onError((error) => {
            if (settled) return;
            settled = true;
            cleanup();
            reject(new Error(error?.msg || "验证码校验失败"));
          });

          captchaObj.onClose(() => {
            if (settled) return;
            settled = true;
            cleanup();
            reject(new Error("CAPTCHA_CANCELLED"));
          });

          captchaObj.onReady(() => {
            try {
              captchaObj.showCaptcha();
            } catch (error) {
              if (settled) return;
              settled = true;
              cleanup();
              reject(error instanceof Error ? error : new Error("验证码拉起失败"));
            }
          });
        },
      );
    });
  };
});
