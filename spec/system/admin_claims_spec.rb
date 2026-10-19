# frozen_string_literal: true

RSpec.describe "Rewards admin page" do
  fab!(:admin)
  fab!(:claim) { Fabricate(:kuu_reward_wechat_claim, payment_account: "wxid-123") }

  let(:dialog) { PageObjects::Components::Dialog.new }

  before do
    SiteSetting.kuu_rewards_enabled = true
    sign_in(admin)
  end

  def row
    find(".kuu-rewards-admin__row[data-claim-id='#{claim.id}']")
  end

  it "shows the payment details" do
    visit("/admin/plugins/discourse-kuu-rewards/claims")

    expect(row).to have_css(".kuu-rewards-admin__account", text: "wxid-123")
    expect(row).to have_css(".kuu-rewards-admin__qr-code img")
    expect(row.find(".kuu-rewards-admin__qr-code img")["naturalWidth"].to_i).to be > 0
  end

  it "marks a claim as transferred" do
    visit("/admin/plugins/discourse-kuu-rewards/claims")
    row.find(".kuu-rewards-admin__mark-transferred").click

    expect(row).to have_css(".kuu-rewards-admin__undo-transferred")
    expect(claim.reload.transferred_at).to be_present
  end

  it "voids a claim with a reason" do
    visit("/admin/plugins/discourse-kuu-rewards/claims")
    row.find(".kuu-rewards-admin__void").click
    find(".kuu-rewards-void-modal textarea").fill_in(with: "刷赞")
    find(".kuu-rewards-void-modal__submit").click

    expect(row).to have_css(".kuu-rewards-admin__status", text: "刷赞")
    expect(claim.reload.voided_at).to be_present
  end

  it "clears all payment details" do
    visit("/admin/plugins/discourse-kuu-rewards/claims")
    find(".kuu-rewards-admin__clear").click
    dialog.click_danger

    expect(row).to have_no_css(".kuu-rewards-admin__account")
    expect(claim.reload).to have_attributes(payment_account: nil, qr_code: nil)
  end
end
