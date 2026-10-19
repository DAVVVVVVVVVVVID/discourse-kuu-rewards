# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Claim::Void do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:claim_id) }
    it { is_expected.to validate_presence_of(:reason) }
    it { is_expected.to validate_length_of(:reason).is_at_most(500) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:admin)
    fab!(:claim, :kuu_reward_claim)

    let(:params) { { claim_id: claim.id, reason: " 刷赞 " } }
    let(:dependencies) { { guardian: admin.guardian } }

    context "when the claim is not found" do
      let(:params) { { claim_id: 0, reason: "刷赞" } }

      it { is_expected.to fail_to_find_a_model(:claim) }
    end

    context "when the claim was already voided" do
      before { claim.update!(voided_at: Time.zone.now) }

      it { is_expected.to fail_to_find_a_model(:claim) }
    end

    context "when everything is ok" do
      it { is_expected.to run_successfully }

      it "voids the claim and frees the reward" do
        expect { result }.to change { DiscourseKuuRewards::Claim.remaining }.by(1)
        expect(claim.reload).to have_attributes(voided_by: admin, void_reason: "刷赞")
        expect(claim.voided_at).to be_present
      end

      it "notifies the claimant in the site" do
        expect { result }.to change { claim.user.notifications.count }.by(1)

        notification = claim.user.notifications.last
        expect(notification).to have_attributes(
          notification_type: Notification.types[:custom],
          topic_id: claim.post.topic_id,
        )
        expect(notification.data_hash[:message]).to eq("kuu_rewards.notifications.voided")
      end

      it "logs a staff action" do
        expect { result }.to change {
          UserHistory.where(custom_type: "kuu_rewards_void_claim").count
        }.by(1)
      end

      it "still works when the post was deleted" do
        claim.post.trash!

        expect(result).to run_successfully
      end
    end
  end
end
