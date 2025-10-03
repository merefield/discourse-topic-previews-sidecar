# frozen_string_literal: true
module TopicPreviews
  module TopicViewSerializerExtension
    extend ActiveSupport::Concern

    included do
      attributes :user_chosen_thumbnail_url,
                 :force_latest_post_nav,
                 :sidecar_installed
    end

    def user_chosen_thumbnail_url
      object.topic.custom_fields["user_chosen_thumbnail_url"]
    end

    def force_latest_post_nav
      object.topic.custom_fields["force_latest_post_nav"]
    end

    def sidecar_installed
      true
    end
  end
end
