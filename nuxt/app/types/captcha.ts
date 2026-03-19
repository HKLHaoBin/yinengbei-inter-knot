export type CaptchaScene =
  | "articleCreate"
  | "articlePublish"
  | "commentCreate"
  | "checkIn"
  | "login"
  | "register";

export interface CaptchaPayload {
  lot_number: string;
  captcha_output: string;
  pass_token: string;
  gen_time: string;
}

export interface CaptchaConfig {
  enabled: boolean;
  captchaId: string;
  scenes: Record<string, boolean | { enabled?: boolean }>;
  sceneModes?: Record<string, string>;
  passTtlSeconds?: Record<string, number>;
}
