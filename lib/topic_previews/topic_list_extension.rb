# frozen_string_literal: true

module TopicPreviews
  module TopicListExtension
    # attr_accessor :featured_topics
    # include ListHelper

    def load_topics
      @topics = super

      if SiteSetting.topic_list_previews_enabled
        @topics = load_previewed_posts(@topics, @current_user)
      end

      @topics
    end

    def load_previewed_posts(topics, user = nil)
      # TODO: better to keep track of previewed posts' id so they can be loaded at once
      posts_map = {}
      post_actions_map = {}
      accepted_answer_post_ids = []
      qa_topic_ids = []
      normal_topic_ids = []
      previewed_post_ids = []

      topics.each do |topic|
        if post_id = topic.custom_fields["accepted_answer_post_id"]&.to_i
          accepted_answer_post_ids << post_id
        elsif ::Topic.respond_to?(:qa_enabled) && ::Topic.qa_enabled(topic)
          qa_topic_ids << topic.id
        else
          normal_topic_ids << topic.id
        end
      end

      Post
        .where("id IN (?)", accepted_answer_post_ids)
        .each do |post|
          posts_map[post.topic_id] = post
          previewed_post_ids << post.id
        end

      Post
        .where(
          "post_number <> 1 AND sort_order = 1 AND topic_id in (?)",
          qa_topic_ids
        )
        .each do |post|
          posts_map[post.topic_id] = post
          previewed_post_ids << post.id
        end

      Post
        .where("post_number = 1 AND topic_id IN (?)", normal_topic_ids)
        .each do |post|
          posts_map[post.topic_id] = post
          previewed_post_ids << post.id
        end

      if user
        PostAction
          .where("post_id IN (?) AND user_id = ?", previewed_post_ids, user.id)
          .each do |post_action|
            (post_actions_map[post_action.post_id] ||= []) << post_action
          end
      end

      topics.each do |topic|
        topic.previewed_post = posts_map[topic.id]
        topic.previewed_post_actions =
          post_actions_map[topic.previewed_post.id] if topic.previewed_post
        topic.previewed_post_bookmark =
          Bookmark.find_by(bookmarkable_id: topic.first_post.id)
      end

      topics
    end
  end
end
