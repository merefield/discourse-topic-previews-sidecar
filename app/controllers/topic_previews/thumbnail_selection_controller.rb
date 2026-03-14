# frozen_string_literal: true
module ::TopicPreviews
  class ThumbnailSelectionController < ::ApplicationController
    requires_plugin "discourse-topic-previews-sidecar"

    def index
      params.require(:topic)

      raise Discourse::InvalidAccess.new unless current_user

      topic_id = params[:topic].to_i
      topic = Topic.find(topic_id)
      user_id = topic.user_id

      thumbnails = []

      if current_user.id == user_id || current_user.staff?
        thumbnails = TopicPreviews::ThumbnailSelectionHelper.get_thumbnails_from_topic(topic)
      end

      respond_to { |format| format.json { render json: { thumbnailselection: thumbnails } } }
    end
  end
end
