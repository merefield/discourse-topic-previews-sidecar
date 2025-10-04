# frozen_string_literal: true
module TopicPreviews
  module TopicListItemSerializerExtension
    extend ActiveSupport::Concern

    include TopicListItemEditsMixin

    included do
      attributes :sidecar_installed,
                 :dominant_colour,
                 :dominant_color,
                 :include_dominant_colour?,
                 :force_latest_post_nav,
                 :show_latest_post_excerpt,
                 :last_post_excerpt,
                 :last_post_id,
                 :topic_post_id,
                 :topic_post_liked,
                 :topic_post_like_count,
                 :topic_post_can_like,
                 :topic_post_can_unlike,
                 :topic_post_bookmarked,
                 :topic_post_is_current_users,
                 :topic_post_number,
                 :topic_post_user

      alias include_topic_post_can_unlike? include_topic_post_id?
    end
  end
end
