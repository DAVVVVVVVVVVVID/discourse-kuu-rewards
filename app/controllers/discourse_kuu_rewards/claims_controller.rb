# frozen_string_literal: true

module DiscourseKuuRewards
  class ClaimsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    # 收款码用 <img> 直接打开，不是 XHR
    skip_before_action :check_xhr, only: :qr_code

    def create
      Claim::Create.call(service_params) do
        on_success { head :created }
        on_failed_contract do |contract|
          render(
            json: failed_json.merge(errors: contract.errors.full_messages),
            status: :bad_request,
          )
        end
        on_model_not_found(:post) { render_error("not_eligible") }
        on_failed_policy(:rewards_left) { render_error("sold_out") }
        on_failed_policy(:under_user_limit) { render_error("user_limit") }
        on_model_errors(:claim) do |claim|
          render(
            json: failed_json.merge(errors: claim.errors.full_messages),
            status: :unprocessable_content,
          )
        end
      end
    end

    # 只有管理员和领奖人本人能看
    def qr_code
      claim = Claim.find_by(id: params[:id])
      raise Discourse::NotFound if claim.nil? || !claim.qr_code?
      raise Discourse::NotFound if !current_user.admin? && claim.user_id != current_user.id

      response.headers["Cache-Control"] = "private, no-store"
      send_data claim.qr_code, type: claim.qr_code_content_type, disposition: "inline"
    end

    private

    def render_error(key)
      render(
        json: failed_json.merge(errors: [I18n.t("kuu_rewards.errors.#{key}")]),
        status: :unprocessable_content,
      )
    end
  end
end
