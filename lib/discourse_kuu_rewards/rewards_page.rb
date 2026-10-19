# frozen_string_literal: true

module DiscourseKuuRewards
  # /rewards 页面的数据。公开部分和「我的」部分都不含收款信息
  class RewardsPage
    PROGRESS_POSTS_LIMIT = 10

    def initialize(guardian)
      @guardian = guardian
    end

    def as_json(*)
      data = {
        total: SiteSetting.kuu_rewards_total,
        remaining:,
        amount: SiteSetting.kuu_rewards_amount,
        like_threshold: SiteSetting.kuu_rewards_like_threshold,
        per_user_limit: SiteSetting.kuu_rewards_per_user_limit,
        start_at: DiscourseKuuRewards.start_at,
        winners:,
      }
      data[:me] = me if @guardian.user
      data
    end

    private

    def remaining
      @remaining ||= Claim.remaining
    end

    def winners
      Claim
        .without_qr_code
        .active
        .includes(:user, post: :topic)
        .order(created_at: :desc)
        .map do |claim|
          {
            id: claim.id,
            username: claim.user.username,
            avatar_template: claim.user.avatar_template,
            claimed_at: claim.created_at,
            post: post_json(claim.post),
          }
        end
    end

    def me
      user = @guardian.user
      claims =
        Claim
          .without_qr_code
          .where(user_id: user.id)
          .includes(post: :topic)
          .order(created_at: :desc)
      blocked_reason =
        if remaining == 0
          "sold_out"
        elsif claims.count { !it.voided? } >= SiteSetting.kuu_rewards_per_user_limit
          "user_limit"
        end

      {
        claimable_posts:
          Eligibility
            .claimable_posts_by(user)
            .includes(:topic)
            .order(created_at: :desc)
            .map { post_json(it) },
        progress_posts:
          Eligibility
            .unclaimed_posts_by(user)
            .where("posts.like_count < ?", SiteSetting.kuu_rewards_like_threshold)
            .includes(:topic)
            .order(like_count: :desc, created_at: :desc)
            .limit(PROGRESS_POSTS_LIMIT)
            .map { post_json(it) },
        blocked_reason:,
        claims:
          claims.map do |claim|
            {
              id: claim.id,
              claimed_at: claim.created_at,
              payment_method: claim.payment_method,
              transferred_at: claim.transferred_at,
              voided_at: claim.voided_at,
              void_reason: claim.void_reason,
              post: post_json(claim.post),
            }
          end,
      }
    end

    # 帖子后来被删、被移到私密分类时，看不到的人只看到「帖子已不可见」
    def post_json(post)
      return if post.nil? || post.topic.nil? || !@guardian.can_see_post?(post)

      {
        id: post.id,
        url: post.url,
        topic_title: post.topic.title,
        post_number: post.post_number,
        like_count: post.like_count,
        created_at: post.created_at,
      }
    end
  end
end
