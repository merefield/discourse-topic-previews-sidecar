# frozen_string_literal: true

module TopicPreviews
  module SuggestedTopicSerializerExtension
    extend ActiveSupport::Concern

    include TopicListItemEditsMixin

    included do
      attributes :sidecar_installed,
                 :dominant_colour,
                 :include_dominant_colour?,
                 :topic_post_id,
                 :topic_post_liked,
                 :topic_post_like_count,
                 :topic_post_can_like,
                 :topic_post_can_unlike,
                 :topic_post_bookmarked,
                 :topic_post_is_current_users,
                 :topic_post_number,
                 :topic_post_user
    end
  end
end
