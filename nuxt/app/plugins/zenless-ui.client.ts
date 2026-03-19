import ZenlessUI from "zenless-ui";
import "zenless-ui/dist/index.css";

export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.vueApp.use(ZenlessUI);
});
