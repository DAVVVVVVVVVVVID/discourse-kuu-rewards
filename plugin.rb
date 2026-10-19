# frozen_string_literal: true

# name: discourse-kuu-rewards
# about: 点赞奖励（临时活动）：单个帖子满 20 赞即可在 /rewards 页面领取奖励，领完即止
# version: 0.0.1
# authors: DAVVVVVVVVVVVID
# url: https://github.com/DAVVVVVVVVVVVID/discourse-kuu-rewards
# required_version: 2026.1.0

enabled_site_setting :kuu_rewards_enabled

module ::DiscourseKuuRewards
  PLUGIN_NAME = "discourse-kuu-rewards"
end

require_relative "lib/discourse_kuu_rewards/engine"

after_initialize {}
