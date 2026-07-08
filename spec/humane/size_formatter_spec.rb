# frozen_string_literal: true

require "spec_helper"

RSpec.describe Humane::SizeFormatter do
  subject(:formatter) { described_class.new }

  describe "#string" do
    context "with 0 bytes" do
      let(:byte_count) { 0 }

      it "formats as 0 B" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("0 B")
      end
    end

    context "with a small byte count" do
      let(:byte_count) { 7 }

      it "formats with no rounding" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("7 B")
      end
    end

    context "with 999 bytes" do
      let(:byte_count) { 999 }

      it "stays in bytes, just under the 1 KB threshold" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("999 B")
      end
    end

    context "with the shared 79992-byte fixture used by lambada/scandalous" do
      let(:byte_count) { 79_992 }

      it "formats as 80 KB" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("80 KB")
      end
    end

    context "with a real file's byte count" do
      let(:byte_count) { 225_935 }

      it "matches Finder's reported size" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("226 KB")
      end
    end

    context "with zouk's ByteCountFormatter(.file) fixture" do
      let(:byte_count) { 500_000 }

      it "matches its output" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("500 KB")
      end
    end

    context "with a single-digit megabyte value" do
      let(:byte_count) { 1_500_000 }

      it "shows one decimal place" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("1.5 MB")
      end
    end

    context "with a gigabyte-scale value" do
      let(:byte_count) { 5_240_000_000 }

      it "rounds to 2 significant digits" do
        expect(formatter.string(from_byte_count: byte_count)).to eq("5.2 GB")
      end
    end
  end
end
