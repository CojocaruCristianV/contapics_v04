import { createApp } from "vue";
import App from "./App.vue";
import axios from "axios";

// Wait for config.js to load
const initApp = () => {
  // Set up Axios interceptor globally
  axios.interceptors.request.use(
    (config) => {
      const token = localStorage.getItem("authToken");
      if (token) {
        config.headers = config.headers || {};
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  createApp(App).mount("#app");
};

// Check if config is loaded, if not wait for it
if (window._env_) {
  initApp();
} else {
  window.addEventListener('load', initApp);
}