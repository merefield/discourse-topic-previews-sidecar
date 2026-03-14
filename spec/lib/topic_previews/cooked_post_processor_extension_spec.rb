# frozen_string_literal: true

RSpec.describe CookedPostProcessor do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:avatar_upload, :image_upload)
  fab!(:github_avatar_upload, :image_upload)
  fab!(:image_upload, :image_upload)
  fab!(:manual_upload, :image_upload)
  fab!(:url_fallback_upload) do
    Fabricate(:upload, sha1: "a" * 40, url: "/uploads/default/original/3X/b/c/#{"d" * 40}.png")
  end

  before { SiteSetting.topic_list_previews_enabled = true }

  def processor_for(post, html)
    processor = described_class.new(post, disable_dominant_color: true)
    processor.instance_variable_set(:@doc, Loofah.html5_fragment(html))
    processor
  end

  it "ignores inline onebox avatars when selecting the post image" do
    post = Fabricate(:post, user: user, raw: "placeholder")

    processor = processor_for(post, <<~HTML)
          <p><img src="#{avatar_upload.url}" class="onebox-avatar-inline"></p>
          <p><img src="#{image_upload.url}"></p>
        HTML

    processor.update_post_image

    expect(post.reload.image_upload_id).to eq(image_upload.id)
    expect(post.topic.reload.image_upload_id).to eq(image_upload.id)
  end

  it "ignores github folder onebox avatars when selecting the post image" do
    post = Fabricate(:post, user: user, raw: "placeholder")

    processor = processor_for(post, <<~HTML)
          <aside class="onebox githubfolder"><img src="#{github_avatar_upload.url}"></aside>
          <p><img src="#{image_upload.url}"></p>
        HTML

    processor.update_post_image

    expect(post.reload.image_upload_id).to eq(image_upload.id)
    expect(post.topic.reload.image_upload_id).to eq(image_upload.id)
  end

  it "falls back to resolving uploads by URL when the sha1 in the URL does not match" do
    post = Fabricate(:post, user: user, raw: "placeholder")

    processor = processor_for(post, "<p><img src='#{url_fallback_upload.url}'></p>")

    processor.update_post_image

    expect(post.reload.image_upload_id).to eq(url_fallback_upload.id)
    expect(post.topic.reload.image_upload_id).to eq(url_fallback_upload.id)
  end

  it "preserves a manually chosen thumbnail for first posts" do
    post = Fabricate(:post, user: user, raw: "placeholder")
    post.update_column(:image_upload_id, manual_upload.id)
    post.topic.update_column(:image_upload_id, manual_upload.id)
    post.topic.custom_fields["user_chosen_thumbnail_url"] = manual_upload.url
    post.topic.save_custom_fields(true)

    processor = processor_for(post, "<p><img src='#{image_upload.url}'></p>")

    post.topic.expects(:generate_thumbnails!).with(extra_sizes: kind_of(Array))

    processor.update_post_image

    expect(post.reload.image_upload_id).to eq(manual_upload.id)
    expect(post.topic.reload.image_upload_id).to eq(manual_upload.id)
  end

  it "includes enabled theme component thumbnail sizes when generating thumbnails" do
    post = Fabricate(:post, user: user, raw: "placeholder")
    helper = stub(topic_thumbnail_sizes: [[800, 800]])

    Theme.stubs(:enabled_theme_and_component_ids).returns([12, 34])
    ThemeModifierHelper.expects(:new).with(theme_ids: [12, 34]).returns(helper)

    expect(processor_for(post, "<p><img src='#{image_upload.url}'></p>").get_extra_sizes).to eq(
      [[800, 800]],
    )
  end
end
