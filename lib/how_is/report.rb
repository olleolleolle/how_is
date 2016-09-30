module HowIs
  class UnsupportedExportFormat < StandardError
    def initialize(format)
      super("Unsupported export format: #{format}")
    end
  end

  ##
  # Represents a completed report.
  class BaseReport < Struct.new(:analysis)
    def format
      raise NotImplementedError
    end

    def github_pulse_summary
      @pulse ||= HowIs::Pulse.new(analysis.repository)
      @pulse.send("#{format}_summary")
    end

    def to_h
      analysis.to_h
    end
    alias :to_hash :to_h

    def to_json
      to_h.to_json
    end

    private
    def issue_or_pr_summary(type, type_label)
      oldest_date_format = "%b %e, %Y"
      a = analysis

      number_of_type = a.send("number_of_#{type}s")

      type_link = a.send("#{type}s_url")
      oldest = a.send("oldest_#{type}")

      "There are #{link("#{number_of_type} #{type_label}s open", type_link)}. " +
      "The average #{type_label} age is #{a.send("average_#{type}_age")}, and the " +
      "#{link("oldest", oldest['html_url'])} was opened on #{oldest['date'].strftime(oldest_date_format)}."
    end
  end

  class Report
    require 'how_is/report/json'
    require 'how_is/report/html'

    REPORT_BLOCK = proc do
      title "How is #{analysis.repository}?"

      text github_pulse_summary

      header "Pull Requests"
      text issue_or_pr_summary "pull", "pull request"

      header "Issues"
      text issue_or_pr_summary "issue", "issue"

      header "Issues Per Label"
      issues_per_label = analysis.issues_with_label.to_a.sort_by { |(k, v)| v['total'].to_i }.reverse
      issues_per_label.map! do |label, hash|
        [label, hash['total'], hash['link']]
      end
      issues_per_label << ["(No label)", analysis.issues_with_no_label['total'], nil]
      horizontal_bar_graph issues_per_label
    end

    def self.export!(analysis, file)
      format = file.split('.').last
      report = get_report_class(format).new(analysis)

      report.export!(file, &REPORT_BLOCK)
    end

    def self.export(analysis, format = HowIs::DEFAULT_FORMAT)
      report = get_report_class(format).new(analysis)

      report.export(&REPORT_BLOCK)
    end

  private
    def self.get_report_class(format)
      class_name = "#{format.capitalize}Report"

      raise UnsupportedExportFormat, format unless HowIs.const_defined?(class_name)

      HowIs.const_get(class_name)
    end
  end
end
