# frozen_string_literal: true
module TopicPreviews
  module TopicExtension
    extend ActiveSupport::Concern

    included do
      has_one :last_post, -> { order(post_number: :desc) }, class_name: "Post"
    end

    attr_accessor :previewed_post
    attr_accessor :previewed_post_actions
    attr_accessor :previewed_post_bookmark

    def dominant_color
      hex = image_upload&.dominant_color
      return {} if hex.blank?

      r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
      { red: r, green: g, blue: b }
    end

    def generate_thumbnails!(extra_sizes: [])
      return nil unless SiteSetting.create_thumbnails
      original = image_upload
      return nil unless original
      if original.filesize &&
           original.filesize >= SiteSetting.max_image_size_kb.kilobytes
        return nil
      end
      return nil unless original.width && original.height
      extra_sizes = [] unless extra_sizes.is_a?(Array)

      if SiteSetting.topic_list_enable_thumbnail_recreation_on_post_rebuild
        TopicThumbnail
          .where(upload_id: original.id)
          .find_each do |tn|
            optimized_image_id = tn.optimized_image_id
            tn.destroy
            if optimized_image_id.present?
              OptimizedImage.find_by(id: optimized_image_id)&.destroy
            end
          end
      end

      (Topic.thumbnail_sizes + extra_sizes).each do |(w, h)|
        TopicThumbnail.find_or_create_for!(
          original,
          max_width: w,
          max_height: h
        )
      end
      nil
    end

    def last_post_excerpt
      return excerpt if highest_post_number <= 1
      last_post&.excerpt
    end
  end
end
