# frozen_string_literal: true

module DiscourseKuuRewards
  # 管理员作废一份：名额退回，从公开名单去掉，站内通知领奖人。这个帖子不能再领
  class Claim::Void
    include Service::Base

    params do
      attribute :claim_id, :integer
      attribute :reason, :string

      validates :claim_id, presence: true
      validates :reason, presence: true, length: { maximum: Claim::VOID_REASON_MAX_LENGTH }
    end

    model :claim

    transaction do
      step :void
      step :log_action
    end

    step :notify_claimant

    private

    def fetch_claim(params:)
      Claim.without_qr_code.active.includes(:user, post: :topic).find_by(id: params.claim_id)
    end

    def void(claim:, guardian:, params:)
      claim.update!(
        voided_at: Time.zone.now,
        voided_by_id: guardian.user.id,
        void_reason: params.reason.strip,
      )
    end

    def log_action(claim:, guardian:)
      StaffActionLogger.new(guardian.user).log_custom(
        "kuu_rewards_void_claim",
        claim_id: claim.id,
        post_id: claim.post_id,
        target_user_id: claim.user_id,
        reason: claim.void_reason,
      )
    end

    def notify_claimant(claim:)
      post = claim.post
      Notification.create!(
        notification_type: Notification.types[:custom],
        user_id: claim.user_id,
        topic_id: post&.topic_id,
        post_number: post&.post_number,
        data: {
          message: "kuu_rewards.notifications.voided",
          title: "kuu_rewards.notifications.voided_title",
          display_username:
            I18n.with_locale(claim.user.effective_locale) do
              I18n.t("kuu_rewards.notifications.voided_label")
            end,
          topic_title: post&.topic&.title,
        }.to_json,
      )
    end
  end
end
