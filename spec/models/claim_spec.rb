# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Claim do
  it "requires a PayPay ID for PayPay" do
    claim = Fabricate.build(:kuu_reward_claim, payment_account: nil)

    expect(claim).not_to be_valid
    expect(claim.errors).to include(:payment_account)
  end

  it "requires a QR code for WeChat" do
    claim = Fabricate.build(:kuu_reward_wechat_claim, qr_code: nil)

    expect(claim).not_to be_valid
    expect(claim.errors).to include(:qr_code)
  end

  describe ".remaining" do
    before { SiteSetting.kuu_rewards_total = 3 }

    it "doesn't count voided claims" do
      Fabricate(:kuu_reward_claim)
      Fabricate(:kuu_reward_claim, voided_at: Time.zone.now)

      expect(described_class.remaining).to eq(2)
    end

    it "never goes below zero" do
      SiteSetting.kuu_rewards_total = 1
      2.times { Fabricate(:kuu_reward_claim) }

      expect(described_class.remaining).to eq(0)
    end
  end
end
