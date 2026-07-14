# frozen_string_literal: true

module Humane
  # Formats one time relative to another the way ActionView's
  # distance_of_time_in_words does for wording, but direction-aware like
  # RelativeDateTimeFormatter -- "X ago"/"in X", chosen automatically rather
  # than requiring the caller to know which applies ahead of time. This is
  # the explicit, fully-tested core -- see .time_ago below for the
  # one-argument convenience. See docs/COMMENTS.md.
  #
  #   Humane.distance_in_time(Time.now - 180, Time.now) #=> "3 minutes ago"
  def self.distance_in_time(at, relative_to, approximate: true, include_seconds: false, when_nil: nil)
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

  # Returns at relative to the current time -- a convenience for the common
  # "drop into a view" case, modeled on ActionView's time_ago_in_words
  # wrapping distance_of_time_in_words with Time.now. Use .distance_in_time
  # directly when the reference time needs to be explicit (tests, a fixed
  # point other than now).
  #
  #   Humane.time_ago(Time.now - 180) #=> "3 minutes ago"
  def self.time_ago(at, **opts)
    distance_in_time(at, Time.now, **opts)
  end

  def self.wrap(text, future:)
    future ? "in #{text}" : "#{text} ago"
  end
  private_class_method :wrap

  def self.pluralize(count, unit)
    (count == 1) ? "1 #{unit}" : "#{count} #{unit}s"
  end
  private_class_method :pluralize
end
