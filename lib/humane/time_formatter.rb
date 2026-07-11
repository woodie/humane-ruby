# frozen_string_literal: true

module Humane
  # Formats one time relative to another the way ActionView's
  # distance_of_time_in_words does for wording, but direction-aware like
  # RelativeDateTimeFormatter -- "X ago"/"in X", chosen automatically rather
  # than requiring the caller to know which applies ahead of time. See
  # docs/COMMENTS.md.
  class TimeFormatter
    class << self
      # Returns at relative to relative_to as a human-readable string. If at
      # is nil, returns when_nil without formatting -- see docs/COMMENTS.md.
      #
      #   Humane::TimeFormatter.time_ago(Time.now - 180, Time.now) #=> "3 minutes ago"
      def time_ago(at, relative_to, approximate: true, include_seconds: false, when_nil: nil)
        return when_nil if at.nil?

        seconds = relative_to - at
        future = seconds.negative?
        seconds = seconds.abs

        if !include_seconds && seconds < 30
          return future ? "in less than a minute" : "less than a minute ago"
        end

        if include_seconds && seconds < 60
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

        text = "about #{text}" if approximate && approximable
        wrap(text, future: future)
      end

      private

      def wrap(text, future:)
        future ? "in #{text}" : "#{text} ago"
      end

      def pluralize(count, unit)
        (count == 1) ? "1 #{unit}" : "#{count} #{unit}s"
      end
    end
  end
end
