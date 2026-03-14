# frozen_string_literal: true

RSpec.describe TopicPreviews::TopicListExtension do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_user, :user)
  fab!(:accepted_answer_topic, :topic)
  fab!(:first_post) { Fabricate(:post, topic: accepted_answer_topic) }
  fab!(:accepted_answer) do
    Fabricate(:post, topic: accepted_answer_topic, post_number: 2, user: other_user)
  end

  before do
    accepted_answer_topic.custom_fields["accepted_answer_post_id"] = accepted_answer.id
    accepted_answer_topic.save_custom_fields(true)
  end

  let(:topic_list_extension_host) { Object.new.extend(described_class) }

  describe "#load_previewed_posts" do
    it "loads bookmarked state for the previewed post, not the first post" do
      Bookmark.create!(user: user, bookmarkable: accepted_answer)

      topics = topic_list_extension_host.load_previewed_posts([accepted_answer_topic], user)

      expect(topics.first.previewed_post).to eq(accepted_answer)
      expect(topics.first.previewed_post_bookmark&.bookmarkable_id).to eq(accepted_answer.id)
    end

    it "does not load another user's bookmark for the previewed post" do
      Bookmark.create!(user: other_user, bookmarkable: accepted_answer)

      topics = topic_list_extension_host.load_previewed_posts([accepted_answer_topic], user)

      expect(topics.first.previewed_post).to eq(accepted_answer)
      expect(topics.first.previewed_post_bookmark).to eq(nil)
    end
  end
end
