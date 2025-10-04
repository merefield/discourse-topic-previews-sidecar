# frozen_string_literal: true
require_dependency "optimized_image"

module TopicPreviews
  module OptimizedImageExtension
    def optimize(operation, from, to, dimensions, opts = {})
      method_name = "#{operation}_instructions"

      pp "###########################  ###########################"
      pp method_name
      pp "###########################  ###########################"
      instructions =
        self.public_send(method_name.to_sym, from, to, dimensions, opts)
      pp "###########################  ###########################"
      pp instructions
      pp "###########################  ###########################"
      pp from
      pp "###########################  ###########################"
      pp to
      pp "###########################  ###########################"
      pp dimensions
      pp "###########################  ###########################"
      pp opts
      pp "###########################  ###########################"
      convert_with(instructions, to, opts)
    end

    def border_elimination_instructions
      %W[-gravity center -crop 100%x75% +repage]
    end

    def resize_instructions(from, to, dimensions, opts = {})
      dimensions = dimensions.split("x", 2)[0] if crop_for_youtube?(opts)

      ensure_safe_paths!(from, to)

      # note FROM my not be named correctly
      from = prepend_decoder!(from, to, opts)
      to = prepend_decoder!(to, to, opts)

      instructions = ["convert", "#{from}[0]"]

      instructions << "-colors" << opts[:colors].to_s if opts[:colors]

      instructions << "-quality" << opts[:quality].to_s if opts[:quality]

      # NOTE: ORDER is important!
      instructions.concat(%W[-auto-orient -gravity center])

      if crop_for_youtube?(opts)
        instructions.concat(
          %W[-#{thumbnail_or_resize} #{dimensions.split("x", 2)[0]}^]
        )
      else
        instructions.concat(
          %W[
            -background
            transparent
            -#{thumbnail_or_resize}
            #{dimensions}^
            -extent
            #{dimensions}
          ]
        )
      end

      if crop_for_youtube?(opts)
        instructions.concat(border_elimination_instructions)
      end

      instructions.concat(
        %W[
          -interpolate
          catrom
          -unsharp
          2x0.5+0.7+0
          -interlace
          none
          -profile
          #{File.join(Rails.root, "vendor", "data", "RT_sRGB.icm")}
        ]
      )

      instructions.concat(%W[#{to}])
    end

    def self.crop_instructions(from, to, dimensions, opts = {})
      dimensions = dimensions.split("x", 2)[0] if crop_for_youtube?(opts)

      ensure_safe_paths!(from, to)

      from = prepend_decoder!(from, to, opts)
      to = prepend_decoder!(to, to, opts)

      instructions = ["convert", "#{from}[0]"]

      if crop_for_youtube?(opts)
        instructions.concat(border_elimination_instructions)
      end

      instructions.concat(
        %W[
          -auto-orient
          -gravity
          north
          -background
          transparent
          -#{thumbnail_or_resize}
          #{dimensions}^
          -crop
          #{dimensions}+0+0
          -unsharp
          2x0.5+0.7+0
          -interlace
          none
          -profile
          #{File.join(Rails.root, "vendor", "data", "RT_sRGB.icm")}
        ]
      )

      instructions << "-quality" << opts[:quality].to_s if opts[:quality]

      instructions << to
    end

    def self.downsize_instructions(from, to, dimensions, opts = {})
      ensure_safe_paths!(from, to)

      from = prepend_decoder!(from, to, opts)
      to = prepend_decoder!(to, to, opts)

      instructions = ["convert", "#{from}[0]"]

      instructions.concat(%W[-auto-orient -gravity center])

      unless crop_for_youtube?(opts)
        instructions.concat(%W[-background transparent])
      end

      instructions.concat(
        %W[
          -interlace
          none
          -resize
          #{dimensions}
          -profile
          #{File.join(Rails.root, "vendor", "data", "RT_sRGB.icm")}
        ]
      )

      if SiteSetting.topic_list_enable_thumbnail_black_border_elimination &&
           is_youtube_four_by_three
        instructions.concat(border_elimination_instructions)
      end

      instructions.concat(%W[#{to}])
    end

    def crop_for_youtube?(opts)
      is_youtube_four_by_three = false
      if opts[:upload_id]
        is_youtube_four_by_three =
          Upload.find(opts[:upload_id]).original_filename == "hqdefault.jpg"
      end
      SiteSetting.topic_list_enable_thumbnail_black_border_elimination &&
        is_youtube_four_by_three
    end
  end
end
