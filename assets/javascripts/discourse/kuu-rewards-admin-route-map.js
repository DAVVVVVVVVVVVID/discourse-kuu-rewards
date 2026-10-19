export default {
  resource: "admin.adminPlugins.show",

  map() {
    this.route("kuu-rewards-claims", { path: "claims" });
  },
};
