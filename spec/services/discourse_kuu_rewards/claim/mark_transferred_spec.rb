# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Claim::MarkTransferred do
  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:admin)
    fab!(:claim, :kuu_reward_claim)

    let(:params) { { claim_id: claim.id, transferred: true } }
    let(:dependencies) { { guardian: admin.guardian } }

    context "when the contract is invalid" do
      let(:params) { { claim_id: claim.id } }

      it { is_expected.to fail_a_contract }
    end

    context "when the claim was voided" do
      before { claim.update!(voided_at: Time.zone.now) }

      it { is_expected.to fail_to_find_a_model(:claim) }
    end

    it "records the transfer time" do
      freeze_time

      expect(result).to run_successfully
      expect(claim.reload.transferred_at).to eq_time(Time.zone.now)
    end

    context "when undoing" do
      let(:params) { { claim_id: claim.id, transferred: false } }

      before { claim.update!(transferred_at: Time.zone.now) }

      it "clears the transfer time" do
        expect(result).to run_successfully
        expect(claim.reload.transferred_at).to be_nil
      end
    end
  end
end
