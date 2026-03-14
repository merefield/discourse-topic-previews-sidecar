# frozen_string_literal: true

RSpec.describe Topic do
  fab!(:manual_upload, :image_upload)
  fab!(:other_upload, :image_upload)
  fab!(:topic) { Fabricate(:topic, image_upload: manual_upload) }

  before { SiteSetting.create_thumbnails = true }

  it "deletes only current topic thumbnails when recreation is requested" do
    stale_optimized_image =
      OptimizedImage.create!(
        upload: manual_upload,
        sha1: "1" * 40,
        extension: ".jpeg",
        width: 800,
        height: 450,
        url: "/uploads/default/optimized/stale-manual.jpeg",
        filesize: 123,
        version: 2,
      )
    stale_topic_thumbnail =
      TopicThumbnail.create!(
        upload: manual_upload,
        optimized_image: stale_optimized_image,
        max_width: 800,
        max_height: 800,
      )

    unrelated_optimized_image =
      OptimizedImage.create!(
        upload: other_upload,
        sha1: "2" * 40,
        extension: ".jpeg",
        width: 400,
        height: 225,
        url: "/uploads/default/optimized/unrelated.jpeg",
        filesize: 456,
        version: 2,
      )
    unrelated_topic_thumbnail =
      TopicThumbnail.create!(
        upload: other_upload,
        optimized_image: unrelated_optimized_image,
        max_width: 400,
        max_height: 400,
      )

    TopicThumbnail.expects(:find_or_create_for!).at_least_once

    topic.generate_thumbnails!(extra_sizes: [[800, 800]], recreate_existing: true)

    expect(TopicThumbnail.exists?(stale_topic_thumbnail.id)).to eq(false)
    expect(OptimizedImage.exists?(stale_optimized_image.id)).to eq(false)
    expect(TopicThumbnail.exists?(unrelated_topic_thumbnail.id)).to eq(true)
    expect(OptimizedImage.exists?(unrelated_optimized_image.id)).to eq(true)
  end

  it "does not delete thumbnails when recreation is not requested" do
    stale_optimized_image =
      OptimizedImage.create!(
        upload: manual_upload,
        sha1: "3" * 40,
        extension: ".jpeg",
        width: 800,
        height: 450,
        url: "/uploads/default/optimized/stale-manual-disabled.jpeg",
        filesize: 123,
        version: 2,
      )
    stale_topic_thumbnail =
      TopicThumbnail.create!(
        upload: manual_upload,
        optimized_image: stale_optimized_image,
        max_width: 800,
        max_height: 800,
      )

    TopicThumbnail.expects(:find_or_create_for!).at_least_once

    topic.generate_thumbnails!(extra_sizes: [[800, 800]])

    expect(TopicThumbnail.exists?(stale_topic_thumbnail.id)).to eq(true)
    expect(OptimizedImage.exists?(stale_optimized_image.id)).to eq(true)
  end

  it "does not delete thumbnails when recreation is requested but generation would bail out" do
    SiteSetting.create_thumbnails = false

    stale_optimized_image =
      OptimizedImage.create!(
        upload: manual_upload,
        sha1: "4" * 40,
        extension: ".jpeg",
        width: 800,
        height: 450,
        url: "/uploads/default/optimized/stale-manual-create-thumbnails-off.jpeg",
        filesize: 123,
        version: 2,
      )
    stale_topic_thumbnail =
      TopicThumbnail.create!(
        upload: manual_upload,
        optimized_image: stale_optimized_image,
        max_width: 800,
        max_height: 800,
      )

    TopicThumbnail.expects(:find_or_create_for!).never

    topic.generate_thumbnails!(extra_sizes: [[800, 800]], recreate_existing: true)

    expect(TopicThumbnail.exists?(stale_topic_thumbnail.id)).to eq(true)
    expect(OptimizedImage.exists?(stale_optimized_image.id)).to eq(true)
  end

  it "passes extra sizes through to thumbnail generation" do
    TopicThumbnail.expects(:find_or_create_for!).with(
      manual_upload,
      max_width: 1024,
      max_height: 1024,
    )
    TopicThumbnail.expects(:find_or_create_for!).with(
      manual_upload,
      max_width: 800,
      max_height: 800,
    )

    topic.generate_thumbnails!(extra_sizes: [[800, 800]], recreate_existing: true)
  end
end
