# frozen_string_literal: true

module DiscourseKuuRewards
  class RewardsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def show
      render json: RewardsPage.new(guardian)
    end
  end
end
