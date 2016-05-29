require 'contracts'
require 'ostruct'
require 'date'

module HowBad
  ##
  # Represents a completed analysis of the repository being analyzed.
  class Analysis < OpenStruct
  end

  class Analyzer
    include Contracts::Core

    Contract Fetcher::Results, Class => Analysis
    def call(data, analysis_class: Analysis)
      analysis_class.new(
        total_issues:  data.issues.length,
        total_pulls:   data.pulls.length,

        issues_with_label: num_with_label(issues),
        pulls_with_label: num_with_label(pulls),

        average_issue_age: average_age_for(issues),
        oldest_issue_date: oldest_date_for(issues),

        average_pull_age:  average_age_for(pulls),
        oldest_pull_date:  oldest_date_for(pulls),
      )
    end

    # Given an Array of issues or pulls, return a Hash specifying how many
    # issues or pulls use each label.
    def num_with_label(issues_or_pulls)
      {} # TODO: Implement.
      # Notes:
      # Hash mapping labels to the number of issues with those labels.
      # E.g., given 10 with label "label1" and 5 with label "label2",
      # {
      #   "label1" => 10,
      #   "label2" => 5
      # }
    end

    # Given an Array of issues or pulls, return the average age of them.
    def average_age_for(issues_or_pulls)
      0 # TODO: Implement.
    end

    # Given an Array of issues or pulls, return the creation date of the oldest.
    def oldest_date_for(issues_or_pulls)
      issues_or_pulls.map {|x| DateTime.parse(x['created_at']) }.sort.first
    end
  end
end
