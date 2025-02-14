# frozen_string_literal: true

module ::TopicPreviews
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace TopicPreviews
    config.autoload_paths << File.join(config.root, "lib")
  end
end
