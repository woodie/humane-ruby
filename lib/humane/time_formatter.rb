# frozen_string_literal: true

module Humane
  # Formats one time relative to another the way Finder-adjacent tools do.
  class TimeFormatter
    # include_seconds shows exact seconds under a minute instead of collapsing to "less than a minute ago/in less than a minute". Defaults to false, matching ActionView's include_seconds.
    # approximate prefixes "about"/"in about" on buckets of an hour or more, matching ActionView's distance_of_time_in_words past that same boundary. Defaults to false.
    def initialize(include_seconds: false, approximate: false)
      @include_seconds = include_seconds
      @approximate = approximate
    end

    # Returns the time at `at` relative to `relative_to` as a human-readable string.
    def string(at:, relative_to:)
      seconds = relative_to - at
      future = seconds.negative?
      seconds = seconds.abs

      if !@include_seconds && seconds < 60
        return future ? "in less than a minute" : "less than a minute ago"
      end

      text =
        if seconds < 60
          pluralize(seconds.to_i, "second")
        elsif seconds < 3600
          pluralize((seconds / 60.0).round, "minute")
        elsif seconds < 86_400
          pluralize((seconds / 3600.0).round, "hour")
        else
          pluralize((seconds / 86_400.0).round, "day")
        end

      text = "about #{text}" if @approximate && seconds >= 3600

      future ? "in #{text}" : "#{text} ago"
    end

    private

    def pluralize(count, unit)
      count == 1 ? "1 #{unit}" : "#{count} #{unit}s"
    end
  end
end
