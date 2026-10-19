# frozen_string_literal: true

module DiscourseKuuRewards
  # 一份奖励：提交收款信息的那一刻就算领奖完成。作废的记录不删，同一个帖子不能再领
  class Claim < ActiveRecord::Base
    self.table_name = "kuu_reward_claims"

    PAYMENT_ACCOUNT_MAX_LENGTH = 100
    VOID_REASON_MAX_LENGTH = 500

    enum :payment_method, { paypay: "paypay", wechat: "wechat" }, validate: true

    belongs_to :user
    belongs_to :post, -> { with_deleted }
    belongs_to :voided_by, class_name: "User", optional: true

    # 收款码图片可能有几 MB，列表里不要把它读出来
    scope :without_qr_code, -> { select(column_names - ["qr_code"]) }
    scope :active, -> { where(voided_at: nil) }

    validates :like_count, presence: true
    validates :payment_account, length: { maximum: PAYMENT_ACCOUNT_MAX_LENGTH }
    validates :void_reason, length: { maximum: VOID_REASON_MAX_LENGTH }
    validate :payment_details_present, on: :create

    def self.remaining
      [SiteSetting.kuu_rewards_total - active.count, 0].max
    end

    def voided?
      voided_at.present?
    end

    def transferred?
      transferred_at.present?
    end

    def qr_code?
      qr_code_content_type.present?
    end

    private

    def payment_details_present
      errors.add(:payment_account, :blank) if paypay? && payment_account.blank?
      errors.add(:qr_code, :blank) if wechat? && qr_code.blank?
    end
  end
end

# == Schema Information
#
# Table name: kuu_reward_claims
#
#  id                   :bigint           not null, primary key
#  like_count           :integer          not null
#  payment_account      :string
#  payment_method       :string           not null
#  qr_code              :binary
#  qr_code_content_type :string
#  transferred_at       :datetime
#  void_reason          :text
#  voided_at            :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  post_id              :integer          not null
#  user_id              :integer          not null
#  voided_by_id         :integer
#
# Indexes
#
#  index_kuu_reward_claims_on_post_id  (post_id) UNIQUE
#  index_kuu_reward_claims_on_user_id  (user_id)
#
