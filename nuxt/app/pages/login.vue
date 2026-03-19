<script setup lang="ts">
import { resolveErrorMessage } from "~/utils/api-error";

const api = useApi();
const captcha = useCaptcha();
const auth = useAuthStore();
const router = useRouter();

const form = reactive({
  username: "",
  email: "",
  password: "",
  confirmPassword: "",
});

const isRegister = ref(false);
const isLoading = ref(false);
const isWaitingForActivation = ref(false);
const errorMessage = ref("");
let pollTimer: ReturnType<typeof setInterval> | null = null;

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

const onLoginSuccess = async (token: string, user: Awaited<ReturnType<typeof api.getSelfUser>>) => {
  auth.clearPendingActivation();
  auth.setSession(token, user);
  if (user.documentId || user.authorId) {
    localStorage.setItem("user_id", String(user.documentId || user.authorId));
  }
  await router.push("/");
};

const startActivationPolling = (email: string, password: string) => {
  isWaitingForActivation.value = true;
  auth.setPendingActivation(email, password);
  stopPolling();

  pollTimer = setInterval(async () => {
    try {
      const res = await api.login(email, password, null);
      if (res.token) {
        stopPolling();
        const user = await api.getSelfUser();
        await onLoginSuccess(res.token, user);
      }
    } catch {
      // still waiting for activation
    }
  }, 3000);
};

const submit = async () => {
  errorMessage.value = "";
  isLoading.value = true;

  try {
    if (!form.email.trim() || !form.password.trim()) {
      throw new Error("请输入邮箱和密码");
    }

    if (isRegister.value) {
      if (!form.username.trim()) {
        throw new Error("请输入用户名");
      }
      if (form.password !== form.confirmPassword) {
        throw new Error("两次输入的密码不一致");
      }
    }

    const captchaPayload = await captcha.verify(isRegister.value ? "register" : "login");

    if (isRegister.value) {
      const registerRes = await api.register(
        form.username.trim(),
        form.email.trim(),
        form.password.trim(),
        captchaPayload,
      );

      if (registerRes.token) {
        const user = await api.getSelfUser();
        await onLoginSuccess(registerRes.token, user);
      } else {
        startActivationPolling(form.email.trim(), form.password.trim());
      }
    } else {
      const loginRes = await api.login(form.email.trim(), form.password.trim(), captchaPayload);
      if (!loginRes.token) {
        throw new Error("登录失败：未获取到 Token");
      }
      const user = await api.getSelfUser();
      await onLoginSuccess(loginRes.token, user);
    }
  } catch (err) {
    errorMessage.value = resolveErrorMessage(err, "登录失败");
  } finally {
    isLoading.value = false;
  }
};

const cancelWaiting = () => {
  stopPolling();
  auth.clearPendingActivation();
  isWaitingForActivation.value = false;
};

onMounted(() => {
  const pending = auth.getPendingActivation();
  if (pending) {
    form.email = pending.email;
    form.password = pending.password;
    isRegister.value = true;
    startActivationPolling(pending.email, pending.password);
  }
});

onUnmounted(() => {
  stopPolling();
});
</script>

<template>
  <section class="container">
    <div class="ik-login-card">
      <h1 class="ik-title">{{ isRegister ? "注册账号" : "登录绳网" }}</h1>
      <p class="ik-meta">支持验证码接入和激活轮询流程</p>

      <div v-if="isWaitingForActivation" class="ik-stack">
        <div class="ik-panel">
          <p>注册成功，请前往邮箱完成激活。</p>
          <p class="ik-meta">系统每 3 秒自动检测激活状态。</p>
        </div>
        <z-button @click="cancelWaiting">取消等待</z-button>
      </div>

      <div v-else class="ik-stack">
        <z-input
          v-if="isRegister"
          v-model="form.username"
          placeholder="用户名"
        />
        <z-input v-model="form.email" placeholder="邮箱" />
        <z-input v-model="form.password" type="password" placeholder="密码" />
        <z-input
          v-if="isRegister"
          v-model="form.confirmPassword"
          type="password"
          placeholder="确认密码"
        />

        <div v-if="errorMessage" class="ik-login-error">{{ errorMessage }}</div>

        <z-button :loading="isLoading" @click="submit">
          {{ isRegister ? "注册" : "登录" }}
        </z-button>
        <z-button type="default" @click="isRegister = !isRegister">
          {{ isRegister ? "已有账号，去登录" : "没有账号，去注册" }}
        </z-button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.ik-login-card {
  margin: 24px auto 0;
  max-width: 480px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 18px;
  border: 1px solid #2f2f2f;
  border-radius: 14px;
  background: linear-gradient(180deg, #1b1b1b 0%, #141414 100%);
}

.ik-login-error {
  border: 1px solid #682828;
  border-radius: 8px;
  padding: 10px;
  color: #ffaaaa;
  background: rgba(127, 35, 35, 0.15);
}
</style>
