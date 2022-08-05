# frozen_string_literal: true

module TopicListItemEditsMixin

  def sidecar_installed
    SiteSetting.topic_list_previews_enabled || false
  end

  def excerpt
    if object.previewed_post
      doc = Nokogiri::HTML::fragment(object.previewed_post.cooked)
      doc.search('.//img').remove
      if !SiteSetting.topic_list_excerpt_remove_links
        PrettyText.excerpt(doc.to_html, SiteSetting.topic_list_excerpt_length, keep_emoji_images: true)
      else
        ::TopicPreviews::SerializerLib.remove_links(PrettyText.excerpt(doc.to_html, SiteSetting.topic_list_excerpt_length, keep_emoji_images: true))
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
      @topic_post_user ||= BasicUserSerializer.new(object.previewed_post.user, scope: scope, root: false).as_json
    else
      nil
    end
  end

  def include_topic_post_user?
    @options[:featured_topics] && topic_post_user.present?
  end

  def topic_post_actions
    object.previewed_post_actions || []
  end

  def topic_like_action
    topic_post_actions.select { |a| a.post_action_type_id == PostActionType.types[:like] }
  end

  def topic_post_bookmarked
    object.previewed_post_bookmark || false
  end

  alias :include_topic_post_bookmarked? :include_topic_post_id?

  def topic_post_liked
    topic_like_action.any?
  end
  alias :include_topic_post_liked? :include_topic_post_id?

  def topic_post_like_count
    object.previewed_post&.like_count
  end

  def include_topic_post_like_count?
    object.previewed_post&.id && topic_post_like_count > 0 && SiteSetting.topic_list_previews_enabled
  end

  def topic_post_can_like
    return false if !scope.current_user || topic_post_is_current_users
    scope.previewed_post_can_act?(object.previewed_post, object, PostActionType.types[:like], taken_actions: topic_post_actions)
  end
  alias :include_topic_post_can_like? :include_topic_post_id?

  def topic_post_is_current_users
    return scope.current_user && (object.previewed_post&.user_id == scope.current_user.id)
  end
  alias :include_topic_post_is_current_users? :include_topic_post_id?

  def topic_post_can_unlike
    return false if !scope.current_user
    action = topic_like_action[0]
    !!(action && (action.user_id == scope.current_user.id) && (action.created_at > SiteSetting.post_undo_action_window_mins.minutes.ago))
  end
end
