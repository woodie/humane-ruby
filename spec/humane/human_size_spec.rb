# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Humane.human_size" do
  subject { Humane.human_size(bytes) }

  context "with 0 bytes" do
    let(:bytes) { 0 }

    it "formats as Zero KB" do
      expect(subject).to eq("Zero KB")
    end
  end

  context "with 1 byte" do
    let(:bytes) { 1 }

    it "spells out the singular unit" do
      expect(subject).to eq("1 byte")
    end
  end

  context "with a small byte count" do
    let(:bytes) { 7 }

    it "spells out bytes" do
      expect(subject).to eq("7 bytes")
    end
  end

  context "with 999 bytes" do
    let(:bytes) { 999 }

    it "stays in bytes" do
      expect(subject).to eq("999 bytes")
    end
  end

  context "with 79992 bytes" do
    let(:bytes) { 79_992 }

    it "formats as 80 KB" do
      expect(subject).to eq("80 KB")
    end
  end

  context "with a real file's byte count" do
    let(:bytes) { 225_935 }

    it "formats as 226 KB" do
      expect(subject).to eq("226 KB")
    end
  end

  context "with 500000 bytes" do
    let(:bytes) { 500_000 }

    it "formats as 500 KB" do
      expect(subject).to eq("500 KB")
    end
  end

  context "with a single-digit megabyte value" do
    let(:bytes) { 1_500_000 }

    it "shows one decimal place, trailing zero trimmed" do
      expect(subject).to eq("1.5 MB")
    end
  end

  context "with a gigabyte-scale value" do
    let(:bytes) { 5_240_000_000 }

    it "shows two decimal places" do
      expect(subject).to eq("5.24 GB")
    end
  end

  context "with a value that lands on an exact unit" do
    let(:bytes) { 2_000_000 }

    it "trims both trailing decimal digits" do
      expect(subject).to eq("2 MB")
    end
  end

  context "with a kilobyte value under 10" do
    let(:bytes) { 1_234 }

    it "rounds to whole kilobytes" do
      expect(subject).to eq("1 KB")
    end
  end

  context "with a kilobyte value that has a fraction" do
    let(:bytes) { 2_579 }

    it "rounds to the nearest kilobyte" do
      expect(subject).to eq("3 KB")
    end
  end

  context "with a megabyte value under 10" do
    let(:bytes) { 4_132_383 }

    it "shows one decimal place, not two" do
      expect(subject).to eq("4.1 MB")
    end
  end

  context "with a megabyte value whose second decimal would round" do
    let(:bytes) { 5_243_887 }

    it "drops the second decimal place" do
      expect(subject).to eq("5.2 MB")
    end
  end

  context "with a megabyte value at 100 or more" do
    let(:bytes) { 123_456_789 }

    it "still shows one decimal place" do
      expect(subject).to eq("123.5 MB")
    end
  end

  context "with a gigabyte value at 10 or more" do
    let(:bytes) { 12_345_678_901 }

    it "still shows two decimal places" do
      expect(subject).to eq("12.35 GB")
    end
  end

  context "with a terabyte value" do
    let(:bytes) { 1_234_567_890_123 }

    it "shows two decimal places" do
      expect(subject).to eq("1.23 TB")
    end
  end

  context "when rounding reaches 1000 of a unit" do
    context "just below the kilobyte limit" do
      let(:bytes) { 999_499 }

      it "stays in KB" do
        expect(subject).to eq("999 KB")
      end
    end

    context "with 999999 bytes" do
      let(:bytes) { 999_999 }

      it "moves up to MB" do
        expect(subject).to eq("1 MB")
      end
    end

    context "just below the megabyte limit" do
      let(:bytes) { 999_949_999 }

      it "stays in MB" do
        expect(subject).to eq("999.9 MB")
      end
    end

    context "with 999960000 bytes" do
      let(:bytes) { 999_960_000 }

      it "moves up to GB" do
        expect(subject).to eq("1 GB")
      end
    end

    context "with 999995000000 bytes" do
      let(:bytes) { 999_995_000_000 }

      it "moves up to TB" do
        expect(subject).to eq("1 TB")
      end
    end
  end
end
