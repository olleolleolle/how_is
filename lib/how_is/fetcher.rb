# frozen_string_literal: true

require "contracts"
require "github_api"
require "how_is/pulse"

C ||= Contracts

class HowIs
  ##
  # Fetches data from GitHub.
  class Fetcher
    include Contracts::Core

    # TODO: Fix this bullshit.
    # :nodoc:
    def self.default_github_instance
      Github.new(auto_pagination: true) do |config|
        config.basic_auth = ENV["HOWIS_BASIC_AUTH"] if ENV["HOWIS_BASIC_AUTH"]
      end
    end

    ##
    # Standardized representation for fetcher results.
    #
    # Implemented as a class instead of passing around a Hash so that it can
    # be more easily referenced by Contracts.
    Results = Struct.new(:repository, :issues, :pulls, :pulse) do
      include Contracts::Core

      Contract String, C::ArrayOf[Hash], C::ArrayOf[Hash], String => nil
      def initialize(repository, issues, pulls, pulse)
        super(repository, issues, pulls, pulse)
      end

      # Struct defines #to_h, but not #to_hash, so we alias them.
      alias_method :to_hash, :to_h
    end

    ##
    # Fetches repository information from GitHub and returns a Results object.
    Contract String,
      C::Or[C::RespondTo[:issues, :pulls], nil],
      C::Or[C::RespondTo[:html_summary], nil] => Results
    def call(repository,
             github = nil,
             pulse = nil)
      github ||= self.class.default_github_instance
      pulse ||= HowIs::Pulse.new(repository)
      user, repo = repository.split("/", 2)

      unless user && repo
        raise HowIs::CLI::OptionsError, "To generate a report from GitHub, " \
          "provide the repository " \
          "username/project. Quitting!"
      end

      issues  = github.issues.list user: user, repo: repo
      pulls   = github.pulls.list  user: user, repo: repo

      summary = pulse.html_summary

      Results.new(
        repository,
        obj_to_array_of_hashes(issues),
        obj_to_array_of_hashes(pulls),
        summary
      )
    end

    private

    def obj_to_array_of_hashes(object)
      object.to_a.map(&:to_h)
    end
  end
end
