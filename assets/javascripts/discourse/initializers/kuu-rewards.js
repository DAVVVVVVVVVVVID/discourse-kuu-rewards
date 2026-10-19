import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "discourse-kuu-rewards";

export default {
  name: "kuu-rewards",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.kuu_rewards_enabled) {
      return;
    }

    withPluginApi((api) => {
      // 用 core 的 custom 通知样式，不注册自己的渲染器：二手市场插件已经接管了 custom，再注册会互相覆盖
      api.replaceIcon("notification.kuu_rewards.notifications.claimed", "gift");
      api.replaceIcon("notification.kuu_rewards.notifications.voided", "ban");

      if (api.getCurrentUser()?.admin) {
        api.addAdminPluginConfigurationNav(PLUGIN_ID, [
          {
            label: "kuu_rewards.admin.claims",
            route: "adminPlugins.show.kuu-rewards-claims",
          },
        ]);
      }
    });
  },
};
