# frozen_string_literal: true

module DiscourseKuuRewards
  # 领奖：提交收款信息的那一刻就算领奖完成，没有审核。资格在加锁的事务里重新确认，
  # 同一时间只处理一个领奖请求，总份数和每人上限不会因为同时提交而超出
  class Claim::Create
    include Service::Base

    # String#hash 每个进程不一样，各个 worker 要拿到同一把锁
    LOCK_KEY = Zlib.crc32("kuu_reward_claims")

    params do
      attribute :post_id, :integer
      attribute :payment_method, :string
      attribute :payment_account, :string
      attribute :qr_code
      attribute :agreed, :boolean

      validates :post_id, presence: true
      validates :payment_method, inclusion: { in: Claim.payment_methods.keys }
      validates :payment_account, length: { maximum: Claim::PAYMENT_ACCOUNT_MAX_LENGTH }
      validates :payment_account, presence: true, if: -> { payment_method == "paypay" }
      validates :qr_code, presence: true, if: -> { payment_method == "wechat" }
      validates :agreed, acceptance: { accept: true }
      validate :qr_code_is_image, if: -> { qr_code.present? }

      def qr_code_is_image
        errors.add(:qr_code, :invalid) if !QrCodeImage.valid?(qr_code)
      end
    end

    transaction do
      step :lock_claims
      model :post
      policy :rewards_left
      policy :under_user_limit
      model :claim, :build_claim
      step :save_claim
    end

    step :notify_admin

    private

    def lock_claims
      DB.exec("SELECT pg_advisory_xact_lock(?)", LOCK_KEY)
    end

    def fetch_post(guardian:, params:)
      Eligibility.claimable_posts_by(guardian.user).includes(:topic).find_by(id: params.post_id)
    end

    def rewards_left
      Claim.remaining > 0
    end

    def under_user_limit(guardian:)
      Claim.active.where(user_id: guardian.user.id).count < SiteSetting.kuu_rewards_per_user_limit
    end

    def build_claim(guardian:, params:, post:)
      claim =
        Claim.new(
          user: guardian.user,
          post:,
          like_count: post.like_count,
          payment_method: params.payment_method,
          payment_account: params.payment_account.presence&.strip,
        )

      if params.qr_code.present?
        claim.qr_code = File.binread(params.qr_code.path)
        claim.qr_code_content_type = QrCodeImage.content_type(params.qr_code)
      end

      claim
    end

    def save_claim(claim:)
      claim.save!
    end

    def notify_admin(claim:, post:)
      admin = User.find_by_username(SiteSetting.kuu_rewards_notify_username)
      return if admin.nil?

      Notification.create!(
        notification_type: Notification.types[:custom],
        user_id: admin.id,
        topic_id: post.topic_id,
        post_number: post.post_number,
        data: {
          message: "kuu_rewards.notifications.claimed",
          title: "kuu_rewards.notifications.claimed_title",
          display_username: claim.user.username,
          topic_title: post.topic.title,
        }.to_json,
      )
    end
  end
end
