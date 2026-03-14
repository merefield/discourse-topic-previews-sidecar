# frozen_string_literal: true
require_dependency "cooked_post_processor"

module TopicPreviews
  module CookedPostProcessorExtension
    def extract_images_for_post
      # all images with a src attribute
      @doc.css("img[src]") -
        # minus emojis
        @doc.css("img.emoji") -
        # minus images inside quotes
        @doc.css(".quote img") -
        # minus onebox site icons
        @doc.css("img.site-icon") -
        # minus onebox avatars
        @doc.css("img.onebox-avatar") - @doc.css("img.onebox-avatar-inline") -
        # minus github onebox profile images
        @doc.css(".onebox.githubfolder img")
    end

    def update_post_image
      if @post.is_first_post? && @post.topic.custom_fields["user_chosen_thumbnail_url"]
        @post.topic.generate_thumbnails!(extra_sizes: get_extra_sizes)
      else
        upload = nil
        eligible_image_fragments = extract_images_for_post

        # Loop through those fragments until we find one with an upload record
        @post.each_upload_url(fragments: eligible_image_fragments) do |src, path, sha1|
          upload = Upload.fetch_from(sha1:, url: src)
          break if upload
        end

        if upload.present?
          @post.update_column(:image_upload_id, upload.id) # post
          if @post.is_first_post? # topic
            @post.topic.update_column(:image_upload_id, upload.id)
            @post.topic.generate_thumbnails!(extra_sizes: get_extra_sizes)
          end
        else
          @post.update_column(:image_upload_id, nil) if @post.image_upload_id
          if @post.topic.image_upload_id && @post.is_first_post?
            @post.topic.update_column(:image_upload_id, nil)
          end
          nil
        end
      end
    end

    def get_extra_sizes
      ThemeModifierHelper.new(
        theme_ids: Theme.enabled_theme_and_component_ids,
      ).topic_thumbnail_sizes
    end
  end
end
