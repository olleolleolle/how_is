# frozen_string_literal: true

require "cgi"
require "how_is/report/base_report"

class HowIs
  # HTML Report implementation
  class HtmlReport < BaseReport
    def format
      :html
    end

    def title(content)
      @title = content
      @r += "\n<h1>#{content}</h1>\n"
    end

    def header(content)
      @r += "\n<h2>#{content}</h2>\n"
    end

    def link(content, url)
      %[<a href="#{url}">#{content}</a>]
    end

    def text(content)
      @r += "<p>#{content}</p>\n"
    end

    def unordered_list(arr)
      @r += "\n<ul>\n"
      arr.each do |item|
        @r += "  <li>#{item}</li>\n"
      end
      @r += "</ul>\n\n"
    end

    ROW_HTML_GRAPH = <<-EOF
  <tr>
    <td style="width: %{label_width}">%{label_text}</td>
    <td><span class="fill" style="width: %{percentage}%%">%{link_text}</span></td>
  </tr>

    EOF

    def horizontal_bar_graph(data)
      if data.length == 1 && data[0][0] == "(No label)"
        text "There are no open issues to graph."
        return
      end

      biggest = data.map { |x| x[1] }.max
      get_percentage = ->(number_of_issues) { number_of_issues * 100 / biggest }

      longest_label_length = data.map(&:first).map(&:length).max
      label_width = "#{longest_label_length}ch"

      @r += "<table class=\"horizontal-bar-graph\">\n"
      data.each do |row|
        @r += Kernel.format(ROW_HTML_GRAPH, label_width: label_width,
          label_text: label_text_for(row),
          percentage: get_percentage.call(row[1]),
          link_text: row[1])
      end
      @r += "</table>\n"
    end

    def export
      @r = ""
      generate_report_text!
    end

    HTML_DOC_TEMPLATE = <<~EOF
      <!DOCTYPE html>
      <html>
      <head>
        <title>%{title}</title>
        <style>
        body { font: sans-serif; }
        main {
          max-width: 600px;
          max-width: 72ch;
          margin: auto;
        }
         .horizontal-bar-graph {
          position: relative;
          width: 100%;
        }
        .horizontal-bar-graph .fill {
          display: inline-block;
          background: #CCC;
        }
        </style>
      </head>
      <body>
        <main>
        %{report}
        </main>
      </body>
      </html>
    EOF

    def export_file(file)
      content = Kernel.format(HTML_DOC_TEMPLATE, title: @title, report: export)
      File.open(file, "w") do |f|
        f.puts content
      end
    end

    private

    def label_text_for(row)
      if row[2]
        link(row[0], row[2])
      else
        row[0]
      end
    end
  end
end
