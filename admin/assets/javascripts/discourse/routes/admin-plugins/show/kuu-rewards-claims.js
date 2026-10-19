import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowKuuRewardsClaimsRoute extends DiscourseRoute {
  model() {
    return ajax("/kuu-rewards/admin/claims.json");
  }
}
