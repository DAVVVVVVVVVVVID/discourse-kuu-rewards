# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Admin::ClaimsController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:claim) { Fabricate(:kuu_reward_wechat_claim, payment_account: "wxid") }

  before { SiteSetting.kuu_rewards_enabled = true }

  describe "#index" do
    it "shows the payment info to admins" do
      sign_in(admin)

      get "/kuu-rewards/admin/claims.json"

      expect(response.status).to eq(200)
      row = response.parsed_body["claims"][0]
      expect(row).to include(
        "id" => claim.id,
        "payment_method" => "wechat",
        "payment_account" => "wxid",
        "qr_code_url" => "/kuu-rewards/claims/#{claim.id}/qr-code",
      )
      expect(row["user"]["username"]).to eq(claim.user.username)
    end

    it "is not available to moderators" do
      sign_in(moderator)

      get "/kuu-rewards/admin/claims.json"

      expect(response.status).to eq(404)
    end

    it "is not available to regular users" do
      sign_in(claim.user)

      get "/kuu-rewards/admin/claims.json"

      expect(response.status).to eq(404)
    end
  end

  describe "#transferred" do
    it "marks the claim as transferred" do
      sign_in(admin)

      put "/kuu-rewards/admin/claims/#{claim.id}/transferred.json", params: { transferred: true }

      expect(response.status).to eq(204)
      expect(claim.reload.transferred_at).to be_present
    end
  end

  describe "#void" do
    it "voids the claim" do
      sign_in(admin)

      put "/kuu-rewards/admin/claims/#{claim.id}/void.json", params: { reason: "刷赞" }

      expect(response.status).to eq(204)
      expect(claim.reload.voided_at).to be_present
    end

    it "requires a reason" do
      sign_in(admin)

      put "/kuu-rewards/admin/claims/#{claim.id}/void.json"

      expect(response.status).to eq(400)
    end
  end

  describe "#clear_payment_info" do
    it "clears all payment info" do
      sign_in(admin)

      delete "/kuu-rewards/admin/payment-info.json"

      expect(response.status).to eq(204)
      expect(claim.reload.payment_account).to be_nil
    end

    it "is not available to moderators" do
      sign_in(moderator)

      delete "/kuu-rewards/admin/payment-info.json"

      expect(response.status).to eq(404)
      expect(claim.reload.payment_account).to eq("wxid")
    end
  end
end
