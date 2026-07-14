# frozen_string_literal: true

module Humane
  UNITS = %w[KB MB GB TB PB EB].freeze

  # Returns byte_count as a Finder-style human-readable string.
  #
  #   Humane.human_size(225_935) #=> "226 KB"
  def self.human_size(byte_count)
    return "Zero KB" if byte_count.zero?
    return (byte_count == 1) ? "1 byte" : "#{byte_count} bytes" if byte_count < 1000

    exponent = [(Math.log(byte_count) / Math.log(1000)).to_i, UNITS.size].min
    value = byte_count / (1000.0**exponent)

    "#{format_significant(value, 3)} #{UNITS[exponent - 1]}"
  end

  # Rounds value to sig_figs significant figures and trims trailing
  # fractional zeros (and the decimal point itself, if nothing remains
  # after it) -- see docs/COMMENTS.md.
  def self.format_significant(value, sig_figs)
    magnitude = Math.log10(value).floor + 1
    decimals = [sig_figs - magnitude, 0].max

    formatted = format("%.#{decimals}f", value)
    formatted.include?(".") ? formatted.sub(/0+\z/, "").sub(/\.\z/, "") : formatted
  end
  private_class_method :format_significant
end
