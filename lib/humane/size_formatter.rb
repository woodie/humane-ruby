# frozen_string_literal: true

module Humane
  # Formats byte counts the way Finder does: 1000-based math, capitalized
  # unit labels, rounded to 2 significant digits. Not the SI-correct
  # lowercase "kB" (that's what number_to_human_size's siblings in other
  # languages get wrong the other way), and not 1024-based math under a
  # "KB" label (that's what Rails' number_to_human_size gets wrong).
  class SizeFormatter
    UNITS = %w[B KB MB GB TB PB EB].freeze

    # string(from_byte_count: 79_992)    == "80 KB"
    # string(from_byte_count: 225_935)   == "226 KB"
    # string(from_byte_count: 1_500_000) == "1.5 MB"
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
