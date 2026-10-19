# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::Claim::Create do
  describe described_class::Contract, type: :model do
    subject(:contract) { described_class.new(payment_method: "paypay", agreed: true) }

    it { is_expected.to validate_presence_of(:post_id) }
    it { is_expected.to validate_inclusion_of(:payment_method).in_array(%w[paypay wechat]) }
    it { is_expected.to validate_length_of(:payment_account).is_at_most(100) }
    it { is_expected.to validate_presence_of(:payment_account) }
    it { is_expected.to validate_acceptance_of(:agreed) }

    context "with WeChat" do
      subject(:contract) { described_class.new(payment_method: "wechat", agreed: true) }

      it { is_expected.to validate_presence_of(:qr_code) }
      it { is_expected.not_to validate_presence_of(:payment_account) }

      it "rejects a file that isn't an image" do
        contract.qr_code = Rack::Test::UploadedFile.new(file_from_fixtures("tags.csv", "csv"))

        expect(contract).not_to be_valid
        expect(contract.errors).to include(:qr_code)
      end

      it "rejects an image that is too large" do
        contract.qr_code = Rack::Test::UploadedFile.new(file_from_fixtures("logo.png"))
        contract.qr_code.stubs(:size).returns(DiscourseKuuRewards::QrCodeImage::MAX_BYTES + 1)

        expect(contract).not_to be_valid
      end
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:author) { Fabricate(:user, refresh_auto_groups: true) }
    fab!(:admin) { Fabricate(:admin, username: "reward_admin") }
    fab!(:post) { Fabricate(:post, user: author, like_count: 20) }

    let(:params) do
      { post_id: post.id, payment_method: "paypay", payment_account: " my-paypay ", agreed: true }
    end
    let(:dependencies) { { guardian: author.guardian } }
    let(:claim) { DiscourseKuuRewards::Claim.last }

    before do
      SiteSetting.kuu_rewards_enabled = true
      SiteSetting.kuu_rewards_start_at = 1.day.ago.iso8601
      SiteSetting.kuu_rewards_notify_username = admin.username
    end

    context "when the contract is invalid" do
      let(:params) { { post_id: post.id, payment_method: "paypay", agreed: true } }

      it { is_expected.to fail_a_contract }
    end

    context "when the post doesn't have enough likes" do
      before { post.update!(like_count: 19) }

      it { is_expected.to fail_to_find_a_model(:post) }
    end

    context "when the post belongs to someone else" do
      let(:dependencies) { { guardian: Fabricate(:user).guardian } }

      it { is_expected.to fail_to_find_a_model(:post) }
    end

    context "when the post was already claimed" do
      before { Fabricate(:kuu_reward_claim, user: author, post:) }

      it { is_expected.to fail_to_find_a_model(:post) }
    end

    context "when the post's claim was voided" do
      before { Fabricate(:kuu_reward_claim, user: author, post:, voided_at: Time.zone.now) }

      it { is_expected.to fail_to_find_a_model(:post) }
    end

    context "when all rewards have been claimed" do
      before do
        SiteSetting.kuu_rewards_total = 2
        2.times { Fabricate(:kuu_reward_claim) }
      end

      it { is_expected.to fail_a_policy(:rewards_left) }

      it "frees a reward when a claim is voided" do
        DiscourseKuuRewards::Claim.last.update!(voided_at: Time.zone.now)

        expect(result).to run_successfully
      end
    end

    context "when the user has reached the limit" do
      before do
        SiteSetting.kuu_rewards_per_user_limit = 2
        2.times { Fabricate(:kuu_reward_claim, user: author) }
      end

      it { is_expected.to fail_a_policy(:under_user_limit) }

      it "doesn't count voided claims" do
        DiscourseKuuRewards::Claim.last.update!(voided_at: Time.zone.now)

        expect(result).to run_successfully
      end
    end

    context "when everything is ok" do
      it { is_expected.to run_successfully }

      it "creates the claim right away" do
        expect { result }.to change { DiscourseKuuRewards::Claim.remaining }.by(-1)
        expect(claim).to have_attributes(
          user: author,
          post:,
          like_count: 20,
          payment_method: "paypay",
          payment_account: "my-paypay",
          qr_code: nil,
        )
      end

      it "notifies the admin in the site only" do
        expect { result }.to change { admin.notifications.count }.by(1).and not_change {
                ActionMailer::Base.deliveries.size
              }

        notification = admin.notifications.last
        expect(notification).to have_attributes(
          notification_type: Notification.types[:custom],
          topic_id: post.topic_id,
          post_number: post.post_number,
        )
        expect(notification.data_hash).to include(
          message: "kuu_rewards.notifications.claimed",
          display_username: author.username,
        )
      end

      it "still succeeds when the admin to notify doesn't exist" do
        SiteSetting.stubs(:kuu_rewards_notify_username).returns("nobody")

        expect(result).to run_successfully
      end

      it "allows silenced users" do
        author.update!(silenced_till: 1.day.from_now)

        expect(result).to run_successfully
      end
    end

    context "with WeChat" do
      let(:params) do
        {
          post_id: post.id,
          payment_method: "wechat",
          qr_code: Rack::Test::UploadedFile.new(file_from_fixtures("logo.jpg")),
          agreed: true,
        }
      end

      it "stores the QR code in the claim" do
        expect(result).to run_successfully
        expect(claim.qr_code).to eq(File.binread(file_from_fixtures("logo.jpg").path))
        expect(claim.qr_code_content_type).to eq("image/jpeg")
        expect(claim.payment_account).to be_nil
      end
    end
  end
end
