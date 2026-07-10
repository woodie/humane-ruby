# frozen_string_literal: true

module Humane
  # Formats one time relative to another the way Finder-adjacent tools do.
  class TimeFormatter
    # include_seconds shows exact seconds under a minute instead of collapsing to "less than a minute ago/in less than a minute". Defaults to false, matching ActionView's include_seconds.
    # approximate prefixes "about"/"in about" on the hour-scale buckets (1 hour, and 2..24 hours), matching ActionView's distance_of_time_in_words wording for those buckets. Defaults to false. See docs/COMMENTS.md and humane-ruby issue #1 for the full bucket table this ports.
    def initialize(include_seconds: false, approximate: false)
      @include_seconds = include_seconds
      @approximate = approximate
    end

    # Returns the time at `at` relative to `relative_to` as a human-readable string.
    def string(at:, relative_to:)
      seconds = relative_to - at
      future = seconds.negative?
      seconds = seconds.abs

      if !@include_seconds && seconds < 30
        return future ? "in less than a minute" : "less than a minute ago"
      end

      if @include_seconds && seconds < 60
        return wrap(pluralize(seconds.to_i, "second"), future: future)
      end

      # Buckets come from distance_in_minutes, not raw seconds re-divided per unit -- see docs/COMMENTS.md.
      distance_in_minutes = (seconds / 60.0).round

      text, approximable =
        case distance_in_minutes
        when 1 then ["1 minute", false]
        when 2..44 then [pluralize(distance_in_minutes, "minute"), false]
        when 45..89 then ["1 hour", true]
        when 90..1439 then [pluralize((distance_in_minutes / 60.0).round, "hour"), true]
        when 1440..2519 then ["1 day", false]
        else [pluralize((distance_in_minutes / 1440.0).round, "day"), false]
        end

      text = "about #{text}" if @approximate && approximable
      wrap(text, future: future)
    end

    private

    def wrap(text, future:)
      future ? "in #{text}" : "#{text} ago"
    end

    def pluralize(count, unit)
      count == 1 ? "1 #{unit}" : "#{count} #{unit}s"
    end
  end
end
