# frozen_string_literal: true

module TopicPreviews
  module TopicGenerateThumbnailsExtension
    def generate_thumbnails!(extra_sizes: [], recreate_existing: false)
      clear_existing_topic_thumbnails if recreate_existing && can_generate_thumbnails?
      super(extra_sizes: extra_sizes)
    end

    private

    def clear_existing_topic_thumbnails
      TopicThumbnail
        .where(upload_id: image_upload.id)
        .find_each do |topic_thumbnail|
          optimized_image_id = topic_thumbnail.optimized_image_id
          topic_thumbnail.destroy
          OptimizedImage.find_by(id: optimized_image_id)&.destroy if optimized_image_id.present?
        end
    end

    def can_generate_thumbnails?
      return false if !SiteSetting.create_thumbnails

      original = image_upload
      return false if original.blank?
      if original.filesize && original.filesize >= SiteSetting.max_image_size_kb.kilobytes
        return false
      end
      return false if !original.width || !original.height

      true
    end
  end
end
