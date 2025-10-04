# frozen_string_literal: true

module TopicPreviews
  module ListHelperExtension
    class << self
      def load_previewed_posts(topics, user = nil)
        return topics if topics.blank?

        posts_map = {}
        post_actions_map = {}
        bookmarked_post_ids = Set.new
        accepted_ids = []
        qa_topic_ids = []
        normal_topic_ids = []

        # partition topics by preview rule
        topics.each do |topic|
          if (pid = topic.custom_fields["accepted_answer_post_id"]).present?
            accepted_ids << pid.to_i
          elsif ::Topic.respond_to?(:qa_enabled) && ::Topic.qa_enabled(topic)
            qa_topic_ids << topic.id
          else
            normal_topic_ids << topic.id
          end
        end

        # 1) accepted answers — exact IDs
        if accepted_ids.any?
          Post
            .where(id: accepted_ids)
            .includes(:user)
            .find_each { |post| posts_map[post.topic_id] = post }
        end

        # 2) QA “preview” posts — first non-OP with sort_order=1 (and not post 1)
        if qa_topic_ids.any?
          Post
            .where(topic_id: qa_topic_ids)
            .where.not(post_number: 1)
            .where(sort_order: 1)
            .includes(:user)
            .find_each { |post| posts_map[post.topic_id] = post }
        end

        # 3) Normal topics — first post
        if normal_topic_ids.any?
          Post
            .where(topic_id: normal_topic_ids, post_number: 1)
            .includes(:user)
            .find_each { |post| posts_map[post.topic_id] = post }
        end

        previewed_post_ids = posts_map.values.map!(&:id)

        # Batch post actions for the current user (only what we need)
        if user && previewed_post_ids.any?
          PostAction
            .where(post_id: previewed_post_ids, user_id: user.id)
            .select(:id, :post_id, :user_id, :post_action_type_id, :created_at)
            .find_each { |pa| (post_actions_map[pa.post_id] ||= []) << pa }

          # Batch bookmarks for the previewed posts (not first_post)
          Bookmark
            .where(
              user_id: user.id,
              bookmarkable_type: "Post",
              bookmarkable_id: previewed_post_ids
            )
            .pluck(:bookmarkable_id)
            .each { |pid| bookmarked_post_ids << pid }
        end

        # assign sidecar fields (all in-memory)
        topics.each do |topic|
          pv = posts_map[topic.id]
          topic.previewed_post = pv
          topic.previewed_post_actions = pv ? post_actions_map[pv.id] : nil
          topic.previewed_post_bookmark =
            pv ? bookmarked_post_ids.include?(pv.id) : false
        end

        topics
      end
    end
  end
end
