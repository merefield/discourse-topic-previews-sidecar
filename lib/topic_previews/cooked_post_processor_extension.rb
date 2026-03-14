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
        regenerate_topic_thumbnails!
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
            regenerate_topic_thumbnails!
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

    def regenerate_topic_thumbnails!
      clear_existing_topic_thumbnails_if_needed
      @post.topic.generate_thumbnails!(extra_sizes: get_extra_sizes)
    end

    def clear_existing_topic_thumbnails_if_needed
      return false if !@post.is_first_post?
      return false if !SiteSetting.topic_list_enable_thumbnail_recreation_on_post_rebuild
      return false if @post.topic.image_upload_id.blank?

      TopicThumbnail
        .where(upload_id: @post.topic.image_upload_id)
        .find_each do |topic_thumbnail|
          optimized_image_id = topic_thumbnail.optimized_image_id
          topic_thumbnail.destroy
          OptimizedImage.find_by(id: optimized_image_id)&.destroy if optimized_image_id.present?
        end

      true
    end

    def get_extra_sizes
      ThemeModifierHelper.new(
        theme_ids: Theme.enabled_theme_and_component_ids,
      ).topic_thumbnail_sizes
    end
  end
end
