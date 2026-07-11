# frozen_string_literal: true

module Humane
  # Formats byte counts the way Finder does: 1000-based math, capitalized
  # unit labels, rounded to 3 significant figures. See docs/COMMENTS.md.
  class SizeFormatter
    UNITS = %w[KB MB GB TB PB EB].freeze

    class << self
      # Returns byte_count as a Finder-style human-readable string.
      #
      #   Humane::SizeFormatter.human_size(225_935) #=> "226 KB"
      def human_size(byte_count)
        return "Zero KB" if byte_count.zero?
        return (byte_count == 1) ? "1 byte" : "#{byte_count} bytes" if byte_count < 1000

        exponent = [(Math.log(byte_count) / Math.log(1000)).to_i, UNITS.size].min
        value = byte_count / (1000.0**exponent)

        "#{format_significant(value, 3)} #{UNITS[exponent - 1]}"
      end

      private

      # Rounds value to sig_figs significant figures and trims trailing
      # fractional zeros (and the decimal point itself, if nothing remains
      # after it) -- see docs/COMMENTS.md.
      def format_significant(value, sig_figs)
        magnitude = Math.log10(value).floor + 1
        decimals = [sig_figs - magnitude, 0].max

        formatted = format("%.#{decimals}f", value)
        formatted.include?(".") ? formatted.sub(/0+\z/, "").sub(/\.\z/, "") : formatted
      end
    end
  end
end
