# frozen_string_literal: true

DiscourseKuuRewards::Engine.routes.draw {}

Discourse::Application.routes.draw { mount ::DiscourseKuuRewards::Engine, at: "kuu-rewards" }
