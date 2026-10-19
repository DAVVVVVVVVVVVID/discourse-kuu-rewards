# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::ClaimsController do
  fab!(:author) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:admin)
  fab!(:claimable_post) { Fabricate(:post, user: author, like_count: 20) }

  before do
    SiteSetting.kuu_rewards_enabled = true
    SiteSetting.kuu_rewards_start_at = 1.day.ago.iso8601
  end

  describe "#create" do
    let(:params) do
      {
        post_id: claimable_post.id,
        payment_method: "paypay",
        payment_account: "my-paypay",
        agreed: true,
      }
    end

    it "requires login" do
      post "/kuu-rewards/claims.json", params: params

      expect(response.status).to eq(403)
    end

    context "when signed in" do
      before { sign_in(author) }

      it "creates the claim" do
        expect { post "/kuu-rewards/claims.json", params: }.to change {
          DiscourseKuuRewards::Claim.count
        }.by(1)

        expect(response.status).to eq(201)
        expect(response.parsed_body["id"]).to eq(DiscourseKuuRewards::Claim.last.id)
      end

      it "accepts a QR code image upload" do
        post "/kuu-rewards/claims.json",
             params: {
               post_id: claimable_post.id,
               payment_method: "wechat",
               qr_code: Rack::Test::UploadedFile.new(file_from_fixtures("logo.png"), "image/png"),
               agreed: true,
             }

        expect(response.status).to eq(201)
        expect(DiscourseKuuRewards::Claim.last.qr_code_content_type).to eq("image/png")
      end

      it "requires the agreement" do
        post "/kuu-rewards/claims.json", params: params.merge(agreed: false)

        expect(response.status).to eq(400)
      end

      it "explains when the post can't be claimed" do
        claimable_post.update!(like_count: 3)

        post "/kuu-rewards/claims.json", params: params

        expect(response.status).to eq(422)
        expect(response.parsed_body["errors"]).to eq([I18n.t("kuu_rewards.errors.not_eligible")])
      end

      it "explains when all rewards are gone" do
        SiteSetting.kuu_rewards_total = 1
        Fabricate(:kuu_reward_claim)

        post "/kuu-rewards/claims.json", params: params

        expect(response.status).to eq(422)
        expect(response.parsed_body["errors"]).to eq([I18n.t("kuu_rewards.errors.sold_out")])
      end

      it "explains when the user has reached the limit" do
        SiteSetting.kuu_rewards_per_user_limit = 1
        Fabricate(:kuu_reward_claim, user: author)

        post "/kuu-rewards/claims.json", params: params

        expect(response.status).to eq(422)
        expect(response.parsed_body["errors"]).to eq([I18n.t("kuu_rewards.errors.user_limit")])
      end
    end
  end

  describe "#qr_code" do
    fab!(:claim) { Fabricate(:kuu_reward_wechat_claim, user: author) }

    let(:path) { "/kuu-rewards/claims/#{claim.id}/qr-code" }

    it "serves the image to admins" do
      sign_in(admin)

      get path

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("image/png")
      expect(response.body.b).to eq(claim.qr_code.b)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "serves the image to the claimant" do
      sign_in(author)

      get path

      expect(response.status).to eq(200)
    end

    it "hides the image from other users" do
      sign_in(Fabricate(:user))

      get path

      expect(response.status).to eq(404)
    end

    it "hides the image from moderators" do
      sign_in(Fabricate(:moderator))

      get path

      expect(response.status).to eq(404)
    end

    it "hides the image from anonymous users" do
      get path

      expect(response.status).to eq(404)
    end

    it "is gone after the payment info is cleared" do
      sign_in(admin)
      DiscourseKuuRewards::Claim::ClearPaymentInfo.call(guardian: admin.guardian)

      get path

      expect(response.status).to eq(404)
    end
  end
end
