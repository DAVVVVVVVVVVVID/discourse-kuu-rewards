# frozen_string_literal: true

module DiscourseKuuRewards
  # 后台的领奖记录，含收款信息，只给管理员
  module AdminClaims
    def self.as_json
      Claim
        .without_qr_code
        .includes(:user, :voided_by, post: :topic)
        .order(created_at: :desc)
        .map do |claim|
          post = claim.post
          {
            id: claim.id,
            user: {
              id: claim.user_id,
              username: claim.user&.username,
              avatar_template: claim.user&.avatar_template,
            },
            post:
              post &&
                {
                  id: post.id,
                  url: post.url,
                  topic_title: post.topic&.title,
                  post_number: post.post_number,
                  like_count: post.like_count,
                  deleted: post.deleted_at.present? || post.user_deleted,
                  hidden: post.hidden,
                },
            like_count: claim.like_count,
            claimed_at: claim.created_at,
            payment_method: claim.payment_method,
            payment_account: claim.payment_account,
            qr_code_url:
              ("#{Discourse.base_path}/kuu-rewards/claims/#{claim.id}/qr-code" if claim.qr_code?),
            transferred_at: claim.transferred_at,
            voided_at: claim.voided_at,
            voided_by: claim.voided_by&.username,
            void_reason: claim.void_reason,
          }
        end
    end
  end
end
