# frozen_string_literal: true

RSpec.describe TopicPreviews::PostGuardianExtension do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_user, :user)
  fab!(:post) { Fabricate(:post, user: other_user) }

  describe "#previewed_post_can_act?" do
    it "treats taken_actions arrays as post action type ids" do
      taken_actions = [
        PostAction.new(user: user, post: post, post_action_type_id: PostActionType.types[:like]),
      ]

      expect(
        Guardian.new(user).previewed_post_can_act?(post, post.topic, :like, taken_actions:),
      ).to eq(false)
    end

    it "continues to accept hash-based taken_actions" do
      taken_actions = { PostActionType.types[:like] => [post.post_number] }

      expect(
        Guardian.new(user).previewed_post_can_act?(post, post.topic, :like, taken_actions:),
      ).to eq(false)
    end
  end
end
