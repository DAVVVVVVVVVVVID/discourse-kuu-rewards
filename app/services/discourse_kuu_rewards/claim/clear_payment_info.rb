# frozen_string_literal: true

module DiscourseKuuRewards
  # 活动结束、全部转账后：清空所有收款账号和收款码图片，只留领奖记录
  class Claim::ClearPaymentInfo
    include Service::Base

    transaction do
      step :clear
      step :log_action
    end

    private

    def clear
      context[:cleared_count] = Claim.where(
        "payment_account IS NOT NULL OR qr_code IS NOT NULL",
      ).update_all(
        payment_account: nil,
        qr_code: nil,
        qr_code_content_type: nil,
        updated_at: Time.zone.now,
      )
    end

    def log_action(guardian:, cleared_count:)
      StaffActionLogger.new(guardian.user).log_custom(
        "kuu_rewards_clear_payment_info",
        cleared_count:,
      )
    end
  end
end
