# frozen_string_literal: true

RSpec.describe TopicPreviews::ThumbnailSelectionController do
  fab!(:owner) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_user, :user)
  fab!(:staff, :admin)
  fab!(:avatar_upload, :image_upload)
  fab!(:github_avatar_upload, :image_upload)
  fab!(:image_upload, :image_upload)
  fab!(:post) { Fabricate(:post, user: owner) }

  before do
    SiteSetting.topic_list_previews_enabled = true
    post.update_columns(raw: "placeholder", cooked: <<~HTML)
        <p><img src="#{avatar_upload.url}" class="onebox-avatar-inline"></p>
        <aside class="onebox githubfolder"><img src="#{github_avatar_upload.url}"></aside>
        <p><img src="#{image_upload.url}"></p>
      HTML
  end

  it "requires a logged in user" do
    get "/topic-previews/thumbnail-selection.json", params: { topic: post.topic_id }

    expect(response.status).to eq(403)
  end

  it "returns filtered thumbnails for the topic owner" do
    sign_in(owner)

    get "/topic-previews/thumbnail-selection.json", params: { topic: post.topic_id }

    expect(response.status).to eq(200)
    expect(response.parsed_body["thumbnailselection"]).to eq(
      [{ "image_url" => image_upload.url, "post_id" => post.id, "upload_id" => image_upload.id }],
    )
  end

  it "returns thumbnails for staff" do
    sign_in(staff)

    get "/topic-previews/thumbnail-selection.json", params: { topic: post.topic_id }

    expect(response.status).to eq(200)
    expect(response.parsed_body["thumbnailselection"].pluck("upload_id")).to eq([image_upload.id])
  end

  it "returns an empty list for other users" do
    sign_in(other_user)

    get "/topic-previews/thumbnail-selection.json", params: { topic: post.topic_id }

    expect(response.status).to eq(200)
    expect(response.parsed_body["thumbnailselection"]).to eq([])
  end
end
