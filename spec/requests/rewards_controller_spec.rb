# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::RewardsController do
  fab!(:author, :user)
  fab!(:winner, :user)
  fab!(:claim) { Fabricate(:kuu_reward_wechat_claim, user: winner, payment_account: "wxid") }
  fab!(:voided_claim) { Fabricate(:kuu_reward_claim, voided_at: Time.zone.now) }

  before do
    SiteSetting.kuu_rewards_enabled = true
    SiteSetting.kuu_rewards_start_at = 1.day.ago.iso8601
    SiteSetting.kuu_rewards_total = 20
  end

  it "is not found when the plugin is disabled" do
    SiteSetting.kuu_rewards_enabled = false

    get "/rewards.json"

    expect(response.status).to eq(404)
  end

  it "renders the app for HTML requests" do
    get "/rewards"

    expect(response.status).to eq(200)
    expect(response.body).to include("data-discourse-setup")
  end

  context "when anonymous" do
    it "shows the remaining rewards and the winners without payment info" do
      get "/rewards.json"

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body).to include("total" => 20, "remaining" => 19, "amount" => "1000 日元")
      expect(body["winners"].map { it["username"] }).to eq([winner.username])
      expect(body["winners"][0]["post"]["url"]).to eq(claim.post.url)
      expect(body).not_to have_key("me")
      expect(response.body).not_to include("wxid", "paypay-id", "qr")
    end

    it "hides posts the viewer can no longer see" do
      claim.post.trash!

      get "/rewards.json"

      expect(response.parsed_body["winners"][0]["post"]).to be_nil
    end
  end

  context "when signed in" do
    fab!(:claimable_post) { Fabricate(:post, user: author, like_count: 20) }
    fab!(:progress_post) { Fabricate(:post, user: author, like_count: 7) }
    fab!(:old_post) { Fabricate(:post, user: author, like_count: 30, created_at: 2.days.ago) }

    before { sign_in(author) }

    it "lists the user's claimable posts and progress" do
      get "/rewards.json"

      me = response.parsed_body["me"]
      expect(me["claimable_posts"].map { it["id"] }).to eq([claimable_post.id])
      expect(me["progress_posts"].map { it["id"] }).to eq([progress_post.id])
      expect(me["progress_posts"][0]["like_count"]).to eq(7)
      expect(me["blocked_reason"]).to be_nil
      expect(me["claims"]).to eq([])
    end

    it "lists the user's own claims, including voided ones, without payment info" do
      own = Fabricate(:kuu_reward_claim, user: author, payment_account: "secret-id")
      voided =
        Fabricate(:kuu_reward_claim, user: author, voided_at: Time.zone.now, void_reason: "刷赞")

      get "/rewards.json"

      claims = response.parsed_body["me"]["claims"]
      expect(claims.map { it["id"] }).to contain_exactly(own.id, voided.id)
      expect(claims.find { it["id"] == voided.id }["void_reason"]).to eq("刷赞")
      expect(response.body).not_to include("secret-id")
    end

    it "says when the user has reached the limit" do
      SiteSetting.kuu_rewards_per_user_limit = 1
      Fabricate(:kuu_reward_claim, user: author)

      get "/rewards.json"

      expect(response.parsed_body["me"]["blocked_reason"]).to eq("user_limit")
    end

    it "says when all rewards are gone" do
      SiteSetting.kuu_rewards_total = 1

      get "/rewards.json"

      expect(response.parsed_body["remaining"]).to eq(0)
      expect(response.parsed_body["me"]["blocked_reason"]).to eq("sold_out")
    end
  end
end
