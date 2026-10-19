# frozen_string_literal: true

# name: discourse-kuu-rewards
# about: 点赞奖励（临时活动）：单个帖子满 20 赞即可在 /rewards 页面领取奖励，领完即止
# version: 0.0.1
# authors: DAVVVVVVVVVVVID
# url: https://github.com/DAVVVVVVVVVVVID/discourse-kuu-rewards
# required_version: 2026.1.0

enabled_site_setting :kuu_rewards_enabled

register_asset "stylesheets/common/kuu-rewards.scss"

register_svg_icon "gift"
register_svg_icon "ban"

module ::DiscourseKuuRewards
  PLUGIN_NAME = "discourse-kuu-rewards"

  def self.parse_start_at(value)
    # 不带时区的写法会按服务器时区解释，容易差 9 小时，所以不接受
    return if !value.to_s.match?(/\A\s*\d{4}-\d{2}-\d{2}.*(Z|[+-]\d{2}:?\d{2})\s*\z/)

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def self.start_at
    parse_start_at(SiteSetting.kuu_rewards_start_at)
  end
end

require_relative "lib/discourse_kuu_rewards/engine"

add_admin_route "kuu_rewards.admin.title", "discourse-kuu-rewards", use_new_show_route: true
