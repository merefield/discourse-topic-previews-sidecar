# frozen_string_literal: true

module TopicPreviews
  module TopicListItemEditsMixin
    def sidecar_installed
      SiteSetting.topic_list_previews_enabled || false
    end

    def excerpt
      if object.previewed_post
        doc = Nokogiri::HTML5.fragment(object.previewed_post.cooked)
        doc.search(".//img").remove
        if !SiteSetting.topic_list_excerpt_remove_links
          PrettyText.excerpt(
            doc.to_html,
            SiteSetting.topic_list_excerpt_length,
            keep_emoji_images: true
          )
        else
          ::TopicPreviews::TopicListSerializerLib.remove_links(
            PrettyText.excerpt(
              doc.to_html,
              SiteSetting.topic_list_excerpt_length,
              keep_emoji_images: true
            )
          )
        end
      else
        object.excerpt
      end
    end

    def include_topic_post_id?
      object.previewed_post.present? && SiteSetting.topic_list_previews_enabled
    end

    def topic_post_id
      object.previewed_post&.id
    end

    def topic_post_number
      object.previewed_post&.post_number
    end

    def topic_post_user
      if object.previewed_post
        @topic_post_user ||=
          BasicUserSerializer.new(
            object.previewed_post.user,
            scope: scope,
            root: false
          ).as_json
      else
        nil
      end
    end

    def include_topic_post_user?
      topic_post_user.present?
    end

    def topic_post_actions
      object.previewed_post_actions || []
    end

    def topic_like_action
      topic_post_actions.select do |a|
        a.post_action_type_id == PostActionType.types[:like]
      end
    end

    def topic_post_bookmarked
      object.previewed_post_bookmark.present? # || false
    end

    alias include_topic_post_bookmarked? include_topic_post_id?

    def topic_post_liked
      topic_like_action.any?
    end
    alias include_topic_post_liked? include_topic_post_id?

    def topic_post_like_count
      object.previewed_post&.like_count
    end

    def include_topic_post_like_count?
      object.previewed_post&.id && topic_post_like_count > 0 &&
        SiteSetting.topic_list_previews_enabled
    end

    def topic_post_can_like
      return false if !scope.current_user || topic_post_is_current_users
      scope.previewed_post_can_act?(
        object.previewed_post,
        object,
        PostActionType.types[:like],
        taken_actions: topic_post_actions
      )
    end
    alias include_topic_post_can_like? include_topic_post_id?

    def topic_post_is_current_users
      scope.current_user &&
        (object.previewed_post&.user_id == scope.current_user.id)
    end
    alias include_topic_post_is_current_users? include_topic_post_id?

    def topic_post_can_unlike
      return false if !scope.current_user
      action = topic_like_action[0]
      !!(
        action && (action.user_id == scope.current_user.id) &&
          (
            action.created_at >
              SiteSetting.post_undo_action_window_mins.minutes.ago
          )
      )
    end

    def include_dominant_colour?
      SiteSetting.topic_list_enable_thumbnail_colour_determination
    end

    def dominant_colour
      object.dominant_color || object.custom_fields["dominant_colour"]
    end

    def force_latest_post_nav
      object.custom_fields["force_latest_post_nav"] || false
    end

    def show_latest_post_excerpt
      object.custom_fields["show_latest_post_excerpt"] || false
    end

    def last_post_excerpt
      cache_key = "tlp_tl_last_post_excerpt_#{object.id}"
      Discourse
        .cache
        .fetch(cache_key, expires_in: 10.minutes) do
          post =
            Post.find_by(
              topic_id: object.id,
              post_number: object.highest_post_number
            ).cooked
          doc = Nokogiri::HTML.fragment(post)
          doc.search(".//img").remove
          node = doc.at("a")
          node.replace(node.text) if !node.nil?
          PrettyText.excerpt(
            doc.to_html,
            SiteSetting.topic_list_excerpt_length,
            keep_emoji_images: true
          )
        end
    end

    def last_post_id
      Post.find_by(
        topic_id: object.id,
        post_number: object.highest_post_number
      ).id
    end
  end
end
