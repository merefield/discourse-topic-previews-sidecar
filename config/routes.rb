# frozen_string_literal: true
Discourse::Application.routes.draw { mount ::TopicPreviews::Engine, at: "/topic-previews" }

TopicPreviews::Engine.routes.draw { get "thumbnail-selection" => "thumbnail_selection#index" }
