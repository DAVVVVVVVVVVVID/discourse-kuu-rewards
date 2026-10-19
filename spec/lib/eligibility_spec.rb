# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Eligibility do
  fab!(:author, :user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category:) }
  fab!(:post) { Fabricate(:post, topic:, user: author, like_count: 20) }

  before do
    SiteSetting.kuu_rewards_enabled = true
    SiteSetting.kuu_rewards_start_at = 1.day.ago.iso8601
    SiteSetting.kuu_rewards_excluded_usernames = ""
  end

  describe ".claimable_posts_by" do
    subject(:claimable) { described_class.claimable_posts_by(author) }

    it "includes a post with enough likes" do
      expect(claimable).to contain_exactly(post)
    end

    it "includes replies, not only first posts" do
      reply = Fabricate(:post, topic:, user: author, like_count: 25)

      expect(claimable).to contain_exactly(post, reply)
    end

    it "counts only the post's own likes" do
      post.update!(like_count: 19)
      Fabricate(:post, topic:, reply_to_post_number: post.post_number, like_count: 50)

      expect(claimable).to be_empty
    end

    it "uses the like threshold setting" do
      SiteSetting.kuu_rewards_like_threshold = 21

      expect(claimable).to be_empty
    end

    it "excludes posts created before the start time" do
      post.update!(created_at: 2.days.ago)

      expect(claimable).to be_empty
    end

    it "includes nothing when the start time has no time zone" do
      SiteSetting.stubs(:kuu_rewards_start_at).returns("2026-10-20 00:00")

      expect(claimable).to be_empty
    end

    it "excludes posts in excluded categories" do
      SiteSetting.kuu_rewards_excluded_categories = category.id.to_s

      expect(claimable).to be_empty
    end

    it "excludes posts in categories anonymous users can't see" do
      category.set_permissions(staff: :full)
      category.save!

      expect(claimable).to be_empty
    end

    it "excludes private messages" do
      pm = Fabricate(:private_message_post, user: author)
      pm.update!(like_count: 20)

      expect(claimable).not_to include(pm)
    end

    it "excludes deleted posts" do
      post.trash!

      expect(claimable).to be_empty
    end

    it "excludes posts deleted by their author" do
      post.update!(user_deleted: true)

      expect(claimable).to be_empty
    end

    it "excludes hidden posts" do
      post.update!(hidden: true)

      expect(claimable).to be_empty
    end

    it "excludes posts in deleted topics" do
      topic.trash!

      expect(claimable).to be_empty
    end

    it "excludes posts in unlisted topics" do
      topic.update!(visible: false)

      expect(claimable).to be_empty
    end

    it "excludes whispers" do
      post.update!(post_type: Post.types[:whisper])

      expect(claimable).to be_empty
    end

    it "excludes posts by excluded users" do
      SiteSetting.kuu_rewards_excluded_usernames = author.username

      expect(claimable).to be_empty
    end

    it "excludes posts that were already claimed, even when the claim was voided" do
      Fabricate(:kuu_reward_claim, user: author, post:, voided_at: Time.zone.now)

      expect(claimable).to be_empty
    end

    it "excludes other users' posts" do
      expect(described_class.claimable_posts_by(Fabricate(:user))).to be_empty
    end
  end
end
