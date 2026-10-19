import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class KuuRewardsRoute extends DiscourseRoute {
  model() {
    return ajax("/rewards.json");
  }

  titleToken() {
    return i18n("kuu_rewards.page.title");
  }
}
