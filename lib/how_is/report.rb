require 'date'
require 'how_is/pulse'

module HowIs
  class UnsupportedExportFormat < StandardError
    def initialize(format)
      super("Unsupported export format: #{format}")
    end
  end

  class Report
    require 'how_is/report/json'
    require 'how_is/report/html'

    # The way this entire class works is there is a REPORT_BLOCK proc which
    # calls various methods to create the report, and REPORT_BLOCK is eventually
    # instance_exec'd by the various *Report (HtmlReport, previously PdfReport)
    # classes, which define the methods required.
    #
    # The *Report class inherit from BaseReport, which implements the common
    # methods for them.

    REPORT_BLOCK = proc do
      title "How is #{analysis.repository}?"

      # DateTime#new_offset(0) sets the timezone to UTC. I think it does this
      # without changing anything besides the timezone, but who knows, 'cause
      # new_offset is entirely undocumented! (Even though it's used in the
      # DateTime documentation!)
      #
      # TODO: Stop pretending everyone who runs how_is is in UTC.
      text "Monthly report, ending on #{DateTime.now.new_offset(0).strftime('%B %e, %Y')}."

      text github_pulse_summary

      header "Pull Requests"
      issue_or_pr_summary "pull", "pull request"

      header "Issues"
      issue_or_pr_summary "issue", "issue"

      header "Issues Per Label"
      issues_per_label = analysis.issues_with_label.to_a.sort_by { |(k, v)| v['total'].to_i }.reverse
      issues_per_label.map! do |label, hash|
        [label, hash['total'], hash['link']]
      end
      issues_per_label << ["(No label)", analysis.issues_with_no_label['total'], nil]
      horizontal_bar_graph issues_per_label
    end

    ##
    # Export a report to a file.
    def self.export_file(analysis, file)
      format = file.split('.').last
      report = get_report_class(format).new(analysis)

      report.export_file(file, &REPORT_BLOCK)
    end

    ##
    # Export a report to a String.
    def self.export(analysis, format = HowIs::DEFAULT_FORMAT)
      report = get_report_class(format).new(analysis)

      report.export(&REPORT_BLOCK)
    end

  private
    # Given a format name (+format+), returns the corresponding <blah>Report
    # class.
    def self.get_report_class(format)
      class_name = "#{format.capitalize}Report"

      raise UnsupportedExportFormat, format unless HowIs.const_defined?(class_name)

      HowIs.const_get(class_name)
    end
  end
end
