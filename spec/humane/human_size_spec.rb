# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Humane.human_size" do
  context "with 0 bytes" do
    it "formats as Zero KB, matching ByteCountFormatter's own wording" do
      expect(Humane.human_size(0)).to eq("Zero KB")
    end
  end

  context "with 1 byte" do
    it "spells out the singular unit" do
      expect(Humane.human_size(1)).to eq("1 byte")
    end
  end

  context "with a small byte count" do
    it "spells out bytes rather than using a B label" do
      expect(Humane.human_size(7)).to eq("7 bytes")
    end
  end

  context "with 999 bytes" do
    it "stays in bytes, just under the 1 KB threshold" do
      expect(Humane.human_size(999)).to eq("999 bytes")
    end
  end

  context "with the shared 79992-byte fixture used by lambada/scandalous" do
    it "formats as 80 KB" do
      expect(Humane.human_size(79_992)).to eq("80 KB")
    end
  end

  context "with a real file's byte count" do
    it "matches Finder's reported size" do
      expect(Humane.human_size(225_935)).to eq("226 KB")
    end
  end

  context "with zouk's ByteCountFormatter(.file) fixture" do
    it "matches its output" do
      expect(Humane.human_size(500_000)).to eq("500 KB")
    end
  end

  context "with a single-digit megabyte value" do
    it "shows one decimal place, trailing zero trimmed" do
      expect(Humane.human_size(1_500_000)).to eq("1.5 MB")
    end
  end

  context "with a gigabyte-scale value" do
    it "keeps 2 decimal places at 3 significant figures (not truncated to 1)" do
      expect(Humane.human_size(5_240_000_000)).to eq("5.24 GB")
    end
  end

  context "with a value that lands on an exact unit" do
    it "trims both trailing decimal digits" do
      expect(Humane.human_size(2_000_000)).to eq("2 MB")
    end
  end
end
