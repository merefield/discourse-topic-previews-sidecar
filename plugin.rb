# frozen_string_literal: true
# name: discourse-topic-previews-sidecar
# about: Sidecar Plugin to support Topic List Preview Theme Component
# version: 6.0.1
# authors: Robert Barrow, Angus McLeod
# url: https://github.com/paviliondev/discourse-topic-previews

enabled_site_setting :topic_list_previews_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "tlp_user_prefs_prefer_low_res_thumbnails"

module ::TopicPreviews
  PLUGIN_NAME = "topic-previews".freeze
end

require_relative "lib/topic_previews/engine"

after_initialize do
  reloadable_patch do
    Upload.prepend(TopicPreviews::UploadExtension)
    Topic.prepend(TopicPreviews::TopicExtension)
    TopicViewSerializer.include(TopicPreviews::TopicViewSerializerExtension)
    ListHelper.prepend(TopicPreviews::ListHelperExtension)
    TopicList.prepend(TopicPreviews::TopicListExtension)
    TopicListItemSerializer.include(
      TopicPreviews::TopicListItemSerializerExtension
    )
    OptimizedImage.singleton_class.prepend(
      TopicPreviews::OptimizedImageExtension
    )
    CookedPostProcessor.prepend(TopicPreviews::CookedPostProcessorExtension)
    PostGuardian.prepend(TopicPreviews::PostGuardianExtension)
    SuggestedTopicSerializer.include(
      TopicPreviews::SuggestedTopicSerializerExtension
    )
    if SiteSetting.topic_list_search_previews_enabled
      SearchTopicListItemSerializer.prepend(
        TopicPreviews::SearchTopicListItemSerializerExtension
      )
    end
  end

  User.register_custom_field_type(
    "tlp_user_prefs_prefer_low_res_thumbnails",
    :boolean
  )
  Topic.register_custom_field_type("user_chosen_thumbnail_url", :string)
  Topic.register_custom_field_type("dominant_colour", :json)
  Topic.register_custom_field_type("force_latest_post_nav", :boolean)
  Topic.register_custom_field_type("show_latest_post_excerpt", :boolean)
  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails
  if TopicList.respond_to? :preloaded_custom_fields
    TopicList.preloaded_custom_fields << "accepted_answer_post_id"
  end
  if TopicList.respond_to? :preloaded_custom_fields
    TopicList.preloaded_custom_fields << "dominant_colour"
  end
  if TopicList.respond_to? :preloaded_custom_fields
    TopicList.preloaded_custom_fields << "force_latest_post_nav"
  end
  if TopicList.respond_to? :preloaded_custom_fields
    TopicList.preloaded_custom_fields << "show_latest_post_excerpt"
  end
  if TopicView.respond_to? :preloaded_custom_fields
    TopicView.preloaded_custom_fields << "accepted_answer_post_id"
  end
  if TopicView.respond_to? :preloaded_custom_fields
    TopicView.preloaded_custom_fields << "dominant_colour"
  end
  if Topic.respond_to? :preloaded_custom_fields
    Topic.preloaded_custom_fields << "accepted_answer_post_id"
  end
  if Topic.respond_to? :preloaded_custom_fields
    Topic.preloaded_custom_fields << "dominant_colour"
  end
  # DiscourseEvent.on(:accepted_solution) do |post|
  #   if post.image_url && SiteSetting.topic_list_previews_enabled
  #     ListHelper.create_topic_thumbnails(post, post.image_url)[:id]
  #   end
  # end

  if TopicList.respond_to? :preloaded_custom_fields
    TopicList.preloaded_custom_fields << "user_chosen_thumbnail_url"
  end
  PostRevisor.track_topic_field("user_chosen_thumbnail_url".to_sym) do |tc, tf|
    tc.record_change(
      "user_chosen_thumbnail_url",
      tc.topic.custom_fields["user_thumbnail_choice"],
      tf
    )
    tc.topic.custom_fields["user_chosen_thumbnail_url"] = tf
  end
  PostRevisor.track_topic_field("image_upload_id".to_sym) do |tc, tf|
    tc.record_change("image_upload_id", tc.topic.image_upload_id, tf)
    tc.topic.image_upload_id = tf
  end
  PostRevisor.track_topic_field("force_latest_post_nav".to_sym) do |tc, tf|
    tc.record_change(
      "force_latest_post_nav",
      tc.topic.custom_fields["force_latest_post_nav"],
      tf
    )
    tc.topic.custom_fields["force_latest_post_nav"] = tf
  end
  PostRevisor.track_topic_field("show_latest_post_excerpt".to_sym) do |tc, tf|
    tc.record_change(
      "show_latest_post_excerpt",
      tc.topic.custom_fields["show_latest_post_excerpt"],
      tf
    )
    tc.topic.custom_fields["show_latest_post_excerpt"] = tf
  end

  DiscourseEvent.trigger(:topic_previews_ready)
end
