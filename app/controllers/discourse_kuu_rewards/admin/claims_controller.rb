# frozen_string_literal: true

module DiscourseKuuRewards
  module Admin
    class ClaimsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      before_action :ensure_admin

      def index
        render json: { claims: AdminClaims.as_json }
      end

      def transferred
        Claim::MarkTransferred.call(service_params) do
          on_success { head :no_content }
          on_failed_contract do |contract|
            render(
              json: failed_json.merge(errors: contract.errors.full_messages),
              status: :bad_request,
            )
          end
          on_model_not_found(:claim) { raise Discourse::NotFound }
        end
      end

      def void
        Claim::Void.call(service_params) do
          on_success { head :no_content }
          on_failed_contract do |contract|
            render(
              json: failed_json.merge(errors: contract.errors.full_messages),
              status: :bad_request,
            )
          end
          on_model_not_found(:claim) { raise Discourse::NotFound }
        end
      end

      def clear_payment_info
        Claim::ClearPaymentInfo.call(service_params) { on_success { head :no_content } }
      end
    end
  end
end
