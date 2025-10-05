# frozen_string_literal: true

module TopicPreviews
  module TopicExtension
    extend ActiveSupport::Concern

    included do
      has_one :last_post, -> { order(post_number: :desc) }, class_name: "Post"
      has_one :first_post,
              -> { where(deleted_at: nil, post_number: 1) },
              class_name: "Post"
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

    def excerpt_for(post)
      return nil unless post
      build_cached_excerpt("tlp:post", post) # same helper you wrote for first/last
    end

    def last_post_excerpt_emoji
      return excerpt if highest_post_number <= 1
      lp = last_post
      return nil unless lp
      build_cached_excerpt("tlp:last", lp)
    end

    def first_post_excerpt_emoji
      fp = first_post
      return nil unless fp
      build_cached_excerpt("tlp:first", fp)
    end

    private

    def build_cached_excerpt(prefix, post)
      key = [
        prefix,
        post.id,
        "v#{post.version}",
        "len#{SiteSetting.topic_list_excerpt_length}",
        ("nolinks" if SiteSetting.topic_list_excerpt_remove_links)
      ].compact.join(":")

      Discourse
        .cache
        .fetch(key, expires_in: 1.day) do
          frag = Nokogiri::HTML5.fragment(post.cooked)

          # --- Remove all non-emoji images ---
          frag.css("img:not(.emoji)").remove

          # --- Build the excerpt, still HTML ---
          html_excerpt =
            PrettyText.excerpt(
              frag.to_html,
              SiteSetting.topic_list_excerpt_length,
              keep_emoji_images: true
            )

          if SiteSetting.topic_list_excerpt_remove_links
            doc = Nokogiri::HTML5.fragment(html_excerpt)

            # unwrap <a> tags (preserve inner HTML, remove the tag itself)
            doc
              .css("a")
              .each do |a|
                a.replace(a.children) # keep link text / emojis
              end

            # Defensive: remove empty <a> remnants or attributes if any
            doc.css("a").remove

            html_excerpt = doc.to_html
          end

          html_excerpt
        end
    end
  end
end
