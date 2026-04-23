import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

function getAllowedHosts() {
  const rawHosts = process.env.ALLOWED_HOSTS ?? "localhost,myapp.local";

  return [...new Set(
    rawHosts
      .split(",")
      .map((host) => host.trim())
      .filter(Boolean),
  )];
}

export default defineConfig({
  plugins: [vue()],
  server: {
    allowedHosts: getAllowedHosts(),
  },
});
