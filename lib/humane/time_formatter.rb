# frozen_string_literal: true

module Humane
  # Formats one time relative to another the way Finder-adjacent tools do, symmetric "X ago"/"X from now".
  class TimeFormatter
    # collapse_minute buckets anything under a minute as "less than a minute ago/from now". Defaults to true.
    def initialize(collapse_minute: true)
      @collapse_minute = collapse_minute
    end

    # Returns the time at `at` relative to `relative_to` as a human-readable string.
    def string(at:, relative_to:)
      seconds = relative_to - at
      future = seconds.negative?
      seconds = seconds.abs

      if @collapse_minute && seconds < 60
        return future ? "less than a minute from now" : "less than a minute ago"
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

      future ? "#{text} from now" : "#{text} ago"
    end

    private

    def pluralize(count, unit)
      count == 1 ? "1 #{unit}" : "#{count} #{unit}s"
    end
  end
end
