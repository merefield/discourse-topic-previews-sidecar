# frozen_string_literal: true

module ::TopicPreviews
  class Engine < ::Rails::Engine
    self.called_from = File.expand_path("../..", __dir__)

    engine_name PLUGIN_NAME
    isolate_namespace TopicPreviews
    config.autoload_paths << File.join(config.root, "lib")
  end
end
