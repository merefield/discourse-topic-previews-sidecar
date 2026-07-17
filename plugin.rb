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
  require_relative "app/services/problem_check/topic_list_previews_sidecar_unsupported"

  register_problem_check ProblemCheck::TopicListPreviewsSidecarUnsupported

  reloadable_patch do
    Upload.prepend(TopicPreviews::UploadExtension)
    Topic.prepend(TopicPreviews::TopicExtension)
    TopicViewSerializer.include(TopicPreviews::TopicViewSerializerExtension)
    ListHelper.prepend(TopicPreviews::ListHelperExtension)
    TopicList.prepend(TopicPreviews::TopicListExtension)
    TopicListItemSerializer.include(TopicPreviews::TopicListItemSerializerExtension)
    OptimizedImage.singleton_class.prepend(TopicPreviews::OptimizedImageExtension)
    CookedPostProcessor.prepend(TopicPreviews::CookedPostProcessorExtension)
    PostGuardian.prepend(TopicPreviews::PostGuardianExtension)
    SuggestedTopicSerializer.include(TopicPreviews::SuggestedTopicSerializerExtension)
    if SiteSetting.topic_list_search_previews_enabled
      SearchTopicListItemSerializer.prepend(TopicPreviews::SearchTopicListItemSerializerExtension)
    end
  end

  User.register_custom_field_type('tlp_user_prefs_prefer_low_res_thumbnails', :boolean)
  Topic.register_custom_field_type('user_chosen_thumbnail_url', :string)
  Topic.register_custom_field_type('dominant_colour', :json)
  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails
  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "dominant_colour" if TopicList.respond_to? :preloaded_custom_fields
  TopicView.preloaded_custom_fields << "accepted_answer_post_id" if TopicView.respond_to? :preloaded_custom_fields
  TopicView.preloaded_custom_fields << "dominant_colour" if TopicView.respond_to? :preloaded_custom_fields
  Topic.preloaded_custom_fields << "accepted_answer_post_id" if Topic.respond_to? :preloaded_custom_fields
  Topic.preloaded_custom_fields << "dominant_colour" if Topic.respond_to? :preloaded_custom_fields
  # DiscourseEvent.on(:accepted_solution) do |post|
  #   if post.image_url && SiteSetting.topic_list_previews_enabled
  #     ListHelper.create_topic_thumbnails(post, post.image_url)[:id]
  #   end
  # end

  TopicList.preloaded_custom_fields << "user_chosen_thumbnail_url" if TopicList.respond_to? :preloaded_custom_fields
  PostRevisor.track_topic_field("user_chosen_thumbnail_url".to_sym) do |tc, tf|
    tc.record_change("user_chosen_thumbnail_url", tc.topic.custom_fields["user_thumbnail_choice"], tf)
    tc.topic.custom_fields["user_chosen_thumbnail_url"] = tf
  end
  PostRevisor.track_topic_field("image_upload_id".to_sym) do |tc, tf|
    tc.record_change("image_upload_id", tc.topic.image_upload_id, tf)
    tc.topic.image_upload_id = tf
  end

  DiscourseEvent.trigger(:topic_previews_ready)
end
