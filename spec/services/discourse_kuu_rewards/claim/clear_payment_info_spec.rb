# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Claim::ClearPaymentInfo do
  describe ".call" do
    subject(:result) { described_class.call(**dependencies) }

    fab!(:admin)
    fab!(:paypay_claim, :kuu_reward_claim)
    fab!(:wechat_claim) { Fabricate(:kuu_reward_wechat_claim, payment_account: "wxid") }

    let(:dependencies) { { guardian: admin.guardian } }

    it "clears payment accounts and QR codes but keeps the claims" do
      expect(result).to run_successfully

      expect(DiscourseKuuRewards::Claim.count).to eq(2)
      [paypay_claim, wechat_claim].each do |claim|
        expect(claim.reload).to have_attributes(
          payment_account: nil,
          qr_code: nil,
          qr_code_content_type: nil,
        )
      end
      expect(wechat_claim.payment_method).to eq("wechat")
    end

    it "logs a staff action" do
      expect { result }.to change {
        UserHistory.where(custom_type: "kuu_rewards_clear_payment_info").count
      }.by(1)
    end
  end
end
