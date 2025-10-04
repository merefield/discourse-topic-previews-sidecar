# frozen_string_literal: true
require_dependency "guardian"
require_dependency "guardian/post_guardian"

module TopicPreviews
  module PostGuardianExtension
    # Passing existing loaded topic record avoids an N+1.
    def previewed_post_can_act?(post, topic, action_key, opts = {})
      taken = opts[:taken_actions].try(:keys).to_a
      is_flag = PostActionType.is_flag?(action_key)
      already_taken_this_action =
        taken.any? && taken.include?(PostActionType.types[action_key])
      already_did_flagging =
        taken.any? && (taken & PostActionType.flag_types.values).any?

      result =
        if authenticated? && post && !@user.anonymous?
          if action_key == :notify_moderators &&
               !SiteSetting.enable_private_messages
            return false
          end

          # we allow flagging for trust level 1 and higher
          # always allowed for private messages
          (
            is_flag && not(already_did_flagging) &&
              (@user.has_trust_level?(TrustLevel[1]) || topic.private_message?)
          ) ||
            # not a flagging action, and haven't done it already
            not(is_flag || already_taken_this_action) &&
              # nothing except flagging on archived topics
              not(topic.try(:archived?)) &&
              # nothing except flagging on deleted posts
              not(post.trashed?) &&
              # don't like your own stuff
              not(action_key == :like && is_my_own?(post)) &&
              # new users can't notify_user because they are not allowed to send private messages
              not(action_key == :notify_user &&
                !@user.has_trust_level?(
                  SiteSetting.min_trust_to_send_messages
                )) &&
              # non-staff can't send an official warning
              not(action_key == :notify_user && !is_staff? &&
                opts[:is_warning].present? && opts[:is_warning] == "true") &&
              # can't send private messages if they're disabled globally
              not(action_key == :notify_user &&
                !SiteSetting.enable_private_messages) &&
              # no voting more than once on single vote topics
              not(action_key == :vote && opts[:voted_in_topic] &&
                topic.has_meta_data_boolean?(:single_vote))
        end

      !!result
    end
  end
end
