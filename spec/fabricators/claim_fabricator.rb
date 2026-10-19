# frozen_string_literal: true

Fabricator(:kuu_reward_claim, class_name: "DiscourseKuuRewards::Claim") do
  user
  post { |attrs| Fabricate(:post, user: attrs[:user], like_count: 20) }
  like_count 20
  payment_method "paypay"
  payment_account "paypay-id"
end

Fabricator(:kuu_reward_wechat_claim, from: :kuu_reward_claim) do
  payment_method "wechat"
  payment_account nil
  qr_code { File.binread(file_from_fixtures("logo.png").path) }
  qr_code_content_type "image/png"
end
