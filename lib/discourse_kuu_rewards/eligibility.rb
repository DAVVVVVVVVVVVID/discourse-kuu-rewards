# frozen_string_literal: true

module DiscourseKuuRewards
  # 哪些帖子参加活动、谁能领奖。都按调用这一刻的状态算：领奖后帖子再被移动、删除、隐藏，
  # 插件不自动处理，由管理员决定要不要作废（2026-10-19 David 定）
  module Eligibility
    def self.participating_posts
      start_at = DiscourseKuuRewards.start_at
      return Post.none if start_at.nil?

      Post
        .joins(:topic)
        .where(post_type: Post.types[:regular], hidden: false, user_deleted: false)
        .where("posts.created_at >= ?", start_at)
        .where("posts.user_id > 0")
        .where.not(user_id: excluded_user_ids)
        .where(
          topics: {
            archetype: Archetype.default,
            visible: true,
            deleted_at: nil,
            category_id: public_category_ids,
          },
        )
    end

    def self.unclaimed_posts_by(user)
      participating_posts.where(user_id: user.id).where.not(id: Claim.select(:post_id))
    end

    def self.claimable_posts_by(user)
      unclaimed_posts_by(user).where(
        "posts.like_count >= ?",
        SiteSetting.kuu_rewards_like_threshold,
      )
    end

    # 匿名用户能看的分类，去掉不参加的（二手市场）
    def self.public_category_ids
      Category
        .where(read_restricted: false)
        .where.not(id: SiteSetting.kuu_rewards_excluded_categories_map)
        .select(:id)
    end

    def self.excluded_user_ids
      usernames = SiteSetting.kuu_rewards_excluded_usernames_map
      User.where(username_lower: usernames.map { User.normalize_username(it) }).select(:id)
    end
  end
end
