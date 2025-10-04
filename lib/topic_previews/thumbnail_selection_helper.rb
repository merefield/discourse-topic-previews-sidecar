# frozen_string_literal: true
module ::TopicPreviews::ThumbnailSelectionHelper
  def self.extract_images_for_post(doc)
    # all images with a src attribute
    doc.css("img[src]") -
      # minus emojis
      doc.css("img.emoji") -
      # minus images inside quotes
      doc.css(".quote img") -
      # minus onebox site icons
      doc.css("img.site-icon") -
      # minus onebox avatars
      doc.css("img.onebox-avatar") #-
    # minus small onebox images (large images are .aspect-image-full-size)
    # @doc.css(".onebox .aspect-image img")
  end

  def self.get_thumbnails_from_topic(topic)
    thumbnails = []

    posts = topic.posts

    posts.map do |post|
      post_id = post.id.to_i

      @post = Post.find(post_id)

      doc = Nokogiri::HTML5.fragment(@post.cooked)

      eligible_image_fragments = extract_images_for_post(doc)

      @post.each_upload_url(
        fragments: eligible_image_fragments
      ) do |src, path, sha1|
        upload = Upload.find_by(sha1: sha1)
        if upload
          thumbnails << {
            image_url: upload.url,
            post_id: post_id,
            upload_id: upload.id
          }
        end
      end
    end
    thumbnails
  end
end
