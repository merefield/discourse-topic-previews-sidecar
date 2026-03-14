# frozen_string_literal: true

RSpec.describe TopicPreviews::ThumbnailSelectionHelper do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:avatar_upload, :image_upload)
  fab!(:github_avatar_upload, :image_upload)
  fab!(:image_upload, :image_upload)
  fab!(:url_fallback_upload) do
    Fabricate(:upload, sha1: "a" * 40, url: "/uploads/default/original/3X/b/c/#{"d" * 40}.png")
  end

  before { SiteSetting.topic_list_previews_enabled = true }

  def update_cooked(post, html)
    post.update_columns(raw: "placeholder", cooked: html)
  end

  it "excludes inline onebox avatars from the thumbnail list" do
    post = Fabricate(:post, user: user)

    update_cooked(post, <<~HTML)
        <p><img src="#{avatar_upload.url}" class="onebox-avatar-inline"></p>
        <p><img src="#{image_upload.url}"></p>
      HTML

    thumbnails = described_class.get_thumbnails_from_topic(post.topic)

    expect(thumbnails.pluck(:upload_id)).to eq([image_upload.id])
  end

  it "excludes github folder onebox avatars from the thumbnail list" do
    post = Fabricate(:post, user: user)

    update_cooked(post, <<~HTML)
        <aside class="onebox githubfolder"><img src="#{github_avatar_upload.url}"></aside>
        <p><img src="#{image_upload.url}"></p>
      HTML

    thumbnails = described_class.get_thumbnails_from_topic(post.topic)

    expect(thumbnails.pluck(:upload_id)).to eq([image_upload.id])
  end

  it "resolves uploads by URL when the sha1 lookup would fail" do
    post = Fabricate(:post, user: user)

    update_cooked(post, "<p><img src='#{url_fallback_upload.url}'></p>")

    thumbnails = described_class.get_thumbnails_from_topic(post.topic)

    expect(thumbnails.pluck(:upload_id)).to eq([url_fallback_upload.id])
  end
end
