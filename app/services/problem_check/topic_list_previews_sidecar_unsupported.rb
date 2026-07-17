# frozen_string_literal: true

class ProblemCheck::TopicListPreviewsSidecarUnsupported < ProblemCheck
  self.priority = "high"

  def call
    problem
  end
end
