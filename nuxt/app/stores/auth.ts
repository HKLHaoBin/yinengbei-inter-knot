import { defineStore } from "pinia";
import type { Author } from "~/types/entities";

const TOKEN_KEY = "access_token";
const PENDING_EMAIL_KEY = "pending_activation_email";
const PENDING_PASSWORD_KEY = "pending_activation_password";

export const useAuthStore = defineStore("auth", {
  state: () => ({
    token: "" as string,
    user: null as Author | null,
  }),
  getters: {
    isLogin: (state) => !!state.token,
  },
  actions: {
    hydrateFromStorage() {
      if (!import.meta.client) return;
      this.token = localStorage.getItem(TOKEN_KEY) || "";
    },
    setSession(token: string, user: Author) {
      this.token = token;
      this.user = user;
      if (import.meta.client) {
        localStorage.setItem(TOKEN_KEY, token);
      }
    },
    clearSession() {
      this.token = "";
      this.user = null;
      if (import.meta.client) {
        localStorage.removeItem(TOKEN_KEY);
      }
    },
    setPendingActivation(email: string, password: string) {
      if (!import.meta.client) return;
      localStorage.setItem(PENDING_EMAIL_KEY, email);
      localStorage.setItem(PENDING_PASSWORD_KEY, password);
    },
    clearPendingActivation() {
      if (!import.meta.client) return;
      localStorage.removeItem(PENDING_EMAIL_KEY);
      localStorage.removeItem(PENDING_PASSWORD_KEY);
    },
    getPendingActivation() {
      if (!import.meta.client) return null;
      const email = localStorage.getItem(PENDING_EMAIL_KEY);
      const password = localStorage.getItem(PENDING_PASSWORD_KEY);
      if (!email || !password) return null;
      return { email, password };
    },
  },
});
