# frozen_string_literal: true

module DiscourseKuuRewards
  # 管理员标记「已转账」，点错了可以取消
  class Claim::MarkTransferred
    include Service::Base

    params do
      attribute :claim_id, :integer
      attribute :transferred, :boolean

      validates :claim_id, presence: true
      validates :transferred, inclusion: { in: [true, false] }
    end

    model :claim
    step :mark

    private

    def fetch_claim(params:)
      Claim.without_qr_code.active.find_by(id: params.claim_id)
    end

    def mark(claim:, params:)
      claim.update!(transferred_at: params.transferred ? Time.zone.now : nil)
    end
  end
end
