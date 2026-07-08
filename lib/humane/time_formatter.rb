# frozen_string_literal: true

module Humane
  # Formats one time relative to another the way Finder-adjacent tools do:
  # symmetric "X ago" / "X from now" phrasing, no "about" prefix on the hour
  # bucket -- a deliberate departure from RelativeDateTimeFormatter's actual
  # asymmetric output ("X ago" / "in X"), not an attempt to reproduce it
  # verbatim.
  class TimeFormatter
    # collapse_minute renders any duration under 60 seconds as "less than a
    # minute ago"/"less than a minute from now" instead of counting seconds.
    # Defaults to true -- Rails' distance_of_time_in_words, Go's
    # justincampbell/timeago, and zouk's own RelativeDateTimeFormatter
    # wrapper all do this in practice; Swift's formatter has no such bucket
    # natively, so there's no "pure" behavior being overridden here.
    def initialize(collapse_minute: true)
      @collapse_minute = collapse_minute
    end

    # Swift's localizedString(for:relativeTo:) uses "for:" as its first
    # argument label; Ruby's "for" is a reserved word, and while
    # `def string(for:, ...)` parses, reading the bound value back out
    # inside the method needs `binding.local_variable_get(:for)` since a
    # bare `for` triggers the keyword parser -- not worth it for a label
    # match. "at:" reads just as naturally: "the string for the time AT
    # this moment, RELATIVE TO that one".
    #
    # string(at: t, relative_to: t)                        == "less than a minute ago"
    # string(at: t - 180, relative_to: t)                  == "3 minutes ago"
    # string(at: t + 180, relative_to: t)                  == "3 minutes from now"
    # string(at: t - 15 * 3600, relative_to: t)             == "15 hours ago"
    # string(at: t - 30 * 3600, relative_to: t)             == "1 day ago"
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
