# frozen_string_literal: true

module DiscourseKuuRewards
  # 开始时间要带时区，例如「2026-10-20 00:00 +09:00」，免得按服务器时区解释
  class StartAtValidator
    def initialize(opts = {})
      @opts = opts
    end

    def valid_value?(value)
      DiscourseKuuRewards.parse_start_at(value).present?
    end

    def error_message
      I18n.t("kuu_rewards.errors.invalid_start_at")
    end
  end
end
