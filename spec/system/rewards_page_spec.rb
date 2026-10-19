# frozen_string_literal: true

RSpec.describe "Rewards page" do
  fab!(:author) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:winner, :user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category:, title: "My reward winning topic") }
  fab!(:post) { Fabricate(:post, topic:, user: author, like_count: 20) }

  let(:form) { PageObjects::Components::FormKit.new(".kuu-rewards-claim-form") }
  let(:toasts) { PageObjects::Components::Toasts.new }

  before do
    SiteSetting.kuu_rewards_enabled = true
    SiteSetting.kuu_rewards_start_at = 1.day.ago.iso8601
    SiteSetting.kuu_rewards_total = 20
  end

  it "shows anonymous users the remaining rewards and the winners" do
    Fabricate(:kuu_reward_claim, user: winner)

    visit("/rewards")

    expect(page).to have_css(".kuu-rewards__remaining-count strong", text: "19")
    expect(page).to have_css(".kuu-rewards__winner", text: winner.username)
    expect(page).to have_css(".kuu-rewards__me .btn-primary", text: I18n.t("js.log_in"))
    expect(page).to have_no_css(".kuu-rewards__claim")
  end

  it "says when all rewards are gone" do
    SiteSetting.kuu_rewards_total = 1
    Fabricate(:kuu_reward_claim, user: winner)

    visit("/rewards")

    expect(page).to have_css(".kuu-rewards__sold-out")
  end

  context "when signed in" do
    before { sign_in(author) }

    it "shows progress when no post qualifies yet" do
      post.update!(like_count: 7)

      visit("/rewards")

      expect(page).to have_no_css(".kuu-rewards__claim")
      expect(page).to have_css(".kuu-rewards__progress-item", text: "My reward winning topic")
      expect(page).to have_css(".kuu-rewards__progress-bar[value='7'][max='20']")
    end

    it "claims a reward with PayPay" do
      visit("/rewards")
      expect(page).to have_css(".kuu-rewards__eligible-message")
      find(".kuu-rewards__claim").click

      form.field("payment_account").fill_in("my-paypay-id")
      form.field("agreed").toggle
      find(".kuu-rewards-claim-modal__submit").click

      expect(toasts).to have_success(I18n.t("js.kuu_rewards.claim.success"))
      expect(page).to have_css(".kuu-rewards__remaining-count strong", text: "19")
      expect(page).to have_css(".kuu-rewards__winner", text: author.username)
      expect(page).to have_css(
        ".kuu-rewards__my-claim",
        text: I18n.t("js.kuu_rewards.me.status.pending"),
      )
      expect(DiscourseKuuRewards::Claim.last).to have_attributes(
        post:,
        payment_method: "paypay",
        payment_account: "my-paypay-id",
      )
    end

    it "claims a reward with a WeChat QR code" do
      visit("/rewards")
      find(".kuu-rewards__claim").click

      form.field("payment_method").select("wechat")
      attach_file(file_from_fixtures("logo.png").path)
      expect(page).to have_css(".kuu-rewards-qr-input__preview")
      form.field("agreed").toggle
      find(".kuu-rewards-claim-modal__submit").click

      expect(toasts).to have_success(I18n.t("js.kuu_rewards.claim.success"))
      expect(DiscourseKuuRewards::Claim.last).to have_attributes(
        payment_method: "wechat",
        qr_code_content_type: "image/png",
      )
    end

    it "requires the PayPay ID, the WeChat QR code and the agreement" do
      visit("/rewards")
      find(".kuu-rewards__claim").click

      find(".kuu-rewards-claim-modal__submit").click
      expect(form.field("payment_account")).to have_errors
      expect(form.field("agreed")).to have_errors

      form.field("payment_method").select("wechat")
      find(".kuu-rewards-claim-modal__submit").click
      expect(form.field("qr_code")).to have_errors
      expect(DiscourseKuuRewards::Claim.count).to eq(0)
    end

    it "explains when the user has reached the limit" do
      SiteSetting.kuu_rewards_per_user_limit = 1
      Fabricate(:kuu_reward_claim, user: author)

      visit("/rewards")

      expect(page).to have_css(".kuu-rewards__blocked")
      expect(page).to have_no_css(".kuu-rewards__claim")
    end

    it "shows voided claims with the reason" do
      Fabricate(:kuu_reward_claim, user: author, voided_at: Time.zone.now, void_reason: "刷赞")

      visit("/rewards")

      expect(page).to have_css(".kuu-rewards__my-claim", text: "刷赞")
    end
  end
end
