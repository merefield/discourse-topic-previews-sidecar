# frozen_string_literal: true
module TopicPreviews
  module TopicExtension

    attr_accessor :previewed_post
    attr_accessor :previewed_post_actions
    attr_accessor :previewed_post_bookmark

    def dominant_color
      hex = Upload.find_by(id: Topic.find_by(id: self.id)&.image_upload_id)&.dominant_color
      if !hex.blank?
        colour_array = hex.scan(/../).map { |colour| colour.to_i(16) }
        { red: colour_array[0], green: colour_array[1], blue: colour_array[2] }
      else
        {}
      end
    end

    def generate_thumbnails!(extra_sizes: [])
      return nil unless SiteSetting.create_thumbnails
      return nil unless original = image_upload
      return nil if original.filesize >= SiteSetting.max_image_size_kb.kilobytes
      return nil unless original.width && original.height
      extra_sizes = [] unless extra_sizes.kind_of?(Array)

      if SiteSetting.topic_list_enable_thumbnail_recreation_on_post_rebuild
        TopicThumbnail.where(upload_id: original.id).each do |tn|
          optimized_image_id = tn.optimized_image_id
          tn.destroy
          OptimizedImage.find(optimized_image_id).destroy if !optimized_image_id.blank?
        end
      end

      (Topic.thumbnail_sizes + extra_sizes).each do |dim|
        TopicThumbnail.find_or_create_for!(original, max_width: dim[0], max_height: dim[1])
      end
    end
  end
end
