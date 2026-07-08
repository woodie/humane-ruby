# frozen_string_literal: true

module Humane
  # Formats byte counts the way Finder does: 1000-based math, capitalized unit labels.
  class SizeFormatter
    UNITS = %w[B KB MB GB TB PB EB].freeze

    # Returns from_byte_count as a Finder-style human-readable string.
    def string(from_byte_count:)
      return "#{from_byte_count} B" if from_byte_count < 1000

      exponent = [(Math.log(from_byte_count) / Math.log(1000)).to_i, UNITS.size - 1].min
      rounded = (from_byte_count / (1000.0**exponent) * 10).round / 10.0

      if rounded < 10
        format("%.1f %s", rounded, UNITS[exponent])
      else
        format("%.0f %s", rounded, UNITS[exponent])
      end
    end
  end
end
