# frozen_string_literal: true

DiscourseKuuRewards::Engine.routes.draw do
  post "/claims" => "claims#create"
  get "/claims/:id/qr-code" => "claims#qr_code"

  scope "/admin", constraints: AdminConstraint.new do
    get "/claims" => "admin/claims#index"
    put "/claims/:claim_id/transferred" => "admin/claims#transferred"
    put "/claims/:claim_id/void" => "admin/claims#void"
    delete "/payment-info" => "admin/claims#clear_payment_info"
  end
end

Discourse::Application.routes.draw do
  mount ::DiscourseKuuRewards::Engine, at: "kuu-rewards"
  get "/rewards" => "discourse_kuu_rewards/rewards#show"
  get "/admin/plugins/discourse-kuu-rewards/claims" => "admin/plugins#index",
      :constraints => AdminConstraint.new
end
