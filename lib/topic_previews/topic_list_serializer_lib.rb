# frozen_string_literal: true
require "nokogiri"

module TopicPreviews
  module TopicListSerializerLib
    def self.remove_links(excerpt)
      doc = Nokogiri.HTML excerpt
      node = doc.at("a")
      node.replace(node.text) if node
      if SiteSetting.topic_list_keep_link_text_content
        doc.to_str.strip
      else
        doc.to_str.gsub(/#{URI.regexp}/, "").gsub(/\s+/, " ").strip
      end
    end
  end
end
