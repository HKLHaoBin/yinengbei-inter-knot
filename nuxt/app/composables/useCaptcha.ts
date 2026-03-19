import type { CaptchaConfig, CaptchaPayload, CaptchaScene } from "~/types/captcha";
import { assertCaptchaPayload } from "~/utils/captcha";

declare global {
  interface Window {
    interKnotVerifyCaptcha?: (captchaId: string) => Promise<unknown>;
  }
}

function isSceneEnabled(config: CaptchaConfig, scene: CaptchaScene): boolean {
  if (!config.enabled || !config.captchaId) {
    return false;
  }
  const sceneConfig = config.scenes?.[scene];
  if (typeof sceneConfig === "boolean") return sceneConfig;
  if (typeof sceneConfig === "object" && sceneConfig) {
    return sceneConfig.enabled !== false;
  }
  return false;
}

export function useCaptcha() {
  const { $api } = useNuxtApp();
  const captchaConfig = useState<CaptchaConfig | null>("captcha-config", () => null);

  const loadConfig = async () => {
    const response = await $api("/api/captcha/config");
    if (response && typeof response === "object" && "data" in (response as Record<string, unknown>)) {
      captchaConfig.value = (response as { data: CaptchaConfig }).data;
    } else {
      captchaConfig.value = response as CaptchaConfig;
    }
    return captchaConfig.value;
  };

  const ensureConfig = async () => {
    return captchaConfig.value || (await loadConfig());
  };

  const verify = async (scene: CaptchaScene): Promise<CaptchaPayload | null> => {
    const config = await ensureConfig();
    if (!isSceneEnabled(config, scene)) {
      return null;
    }
    if (typeof window === "undefined" || typeof window.interKnotVerifyCaptcha !== "function") {
      throw new Error("验证码能力未就绪");
    }
    const payload = await window.interKnotVerifyCaptcha(config.captchaId);
    return assertCaptchaPayload(payload);
  };

  const verifyForRequiredResponse = async (
    fallbackScene: CaptchaScene,
    errorDetails?: Record<string, unknown>,
  ) => {
    const scene = (errorDetails?.scene as CaptchaScene | undefined) || fallbackScene;
    return await verify(scene);
  };

  return {
    captchaConfig,
    loadConfig,
    ensureConfig,
    verify,
    verifyForRequiredResponse,
  };
}
