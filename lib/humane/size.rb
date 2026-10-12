# frozen_string_literal: true

module Humane
  UNITS = %w[KB MB GB TB PB EB].freeze
  DECIMAL_PLACES = [0, 1, 2, 2, 2, 2].freeze

  # Returns byte_count as a Finder-style human-readable string.
  #
  #   Humane.human_size(225_935) #=> "226 KB"
  def self.human_size(byte_count)
    return "Zero KB" if byte_count.zero?
    return (byte_count == 1) ? "1 byte" : "#{byte_count} bytes" if byte_count < 1000

    exponent = [(Math.log(byte_count) / Math.log(1000)).to_i, UNITS.size].min
    value = round_for_unit(byte_count, exponent)
    if value >= 1000 && exponent < UNITS.size
      exponent += 1
      value = round_for_unit(byte_count, exponent)
    end

    "#{trim_zeros(value, DECIMAL_PLACES[exponent - 1])} #{UNITS[exponent - 1]}"
  end

  def self.round_for_unit(byte_count, exponent)
    scale = 10**DECIMAL_PLACES[exponent - 1]
    (byte_count / (1000.0**exponent) * scale).round / scale.to_f
  end
  private_class_method :round_for_unit

  def self.trim_zeros(value, decimals)
    formatted = format("%.#{decimals}f", value)
    formatted.include?(".") ? formatted.sub(/0+\z/, "").sub(/\.\z/, "") : formatted
  end
  private_class_method :trim_zeros
end
