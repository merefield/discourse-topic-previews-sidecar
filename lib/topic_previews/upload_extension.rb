# frozen_string_literal: true
module TopicPreviews
  module UploadExtension
    DOMINANT_COLOR_COMMAND_TIMEOUT_SECONDS = 5

    def calculate_dominant_color!(local_path = nil)
      color = nil

      color = "" if !FileHelper.is_supported_image?("image.#{extension}") ||
        extension == "svg"

      if color.nil?
        local_path ||=
          if local?
            Discourse.store.path_for(self)
          else
            Discourse.store.download_safe(self)&.path
          end

        if local_path.nil?
          # Download failed. Could be too large to download, or file could be missing in s3
          color = ""
        end

        color ||=
          begin
            data =
              Discourse::Utils.execute_command(
                "nice",
                "-n",
                "10",
                "convert",
                local_path,
                "-depth",
                "8",
                "-colors",
                SiteSetting.topic_list_dominant_color_quantisation.to_s,
                "-define",
                "histogram:unique-colors=true",
                "-format",
                "%c",
                "histogram:info:",
                timeout: DOMINANT_COLOR_COMMAND_TIMEOUT_SECONDS
              )

            # Output format:
            # 1: (110.873,116.226,93.8821) #6F745E srgb(43.4798%,45.5789%,36.8165%)

            color = data[/#([0-9A-F]{6})/, 1]

            if color.nil?
              raise "Calculated dominant color but unable to parse output:\n#{data}"
            end

            color
          rescue Discourse::Utils::CommandError => e
            # Timeout or unable to parse image
            # This can happen due to bad user input - ignore and save
            # an empty string to prevent re-evaluation
            ""
          end
      end

      if persisted?
        self.update_column(:dominant_color, color)
      else
        self.dominant_color = color
      end
    end
  end
end
